extends Node

signal setting_changed(setting: String)

const AdventureCatalog = preload("res://scripts/adventure/adventure_catalog.gd")
const SAVE_PATH := "user://math_cat_profile.json"
const GRADE_BUCKET_COUNT := 13
const PRACTICE_MIN_LIVES := 1
const PRACTICE_MAX_LIVES := 9

const CAT_COLORS := {
    "Orange": Color("ffffff"),
    "Red": Color("ff7a7a"),
    "Green": Color("8de58d"),
    "Yellow": Color("ffe67a"),
    "Blue": Color("7ab8ff"),
    "Purple": Color("c99aff"),
    "Pink": Color("ff9ecb"),
    "White": Color("ffffff"),
    "Brown": Color("b7835f"),
    "Black": Color("555563"),
}

var data: Dictionary = {}
var storage_path := SAVE_PATH
var last_save_error := ""

func _ready() -> void:
    data = _load_data()
    apply_audio_settings()

func master_volume() -> int:
    return int(data.settings.master_volume)

func music_volume() -> int:
    return int(data.settings.music_volume)

func sfx_volume() -> int:
    return int(data.settings.sfx_volume)

func controller_navigation_mode() -> bool:
    return data.settings.controller_input_style == "navigation"

func cat_color_name() -> String:
    return str(data.settings.cat_color)

func cat_modulate() -> Color:
    return CAT_COLORS.get(cat_color_name(), Color.WHITE)

func animated_background_enabled() -> bool:
    return bool(data.settings.animated_background)

func practice_lives() -> int:
    return int(data.settings.practice_lives)

func set_practice_lives(value: int) -> void:
    data.settings.practice_lives = clampi(value, PRACTICE_MIN_LIVES, PRACTICE_MAX_LIVES)
    save()

func set_volume(setting: String, value: int) -> void:
    data.settings[setting] = clampi(value, 0, 10)
    apply_audio_settings()
    if setting == "music_volume":
        AudioManager.set_music_volume(music_volume())
    elif setting == "sfx_volume":
        AudioManager.set_sfx_volume(sfx_volume())
    save()
    setting_changed.emit(setting)

func set_controller_input_style(style: String) -> void:
    data.settings.controller_input_style = "navigation" if style == "navigation" else "direct"
    save()
    setting_changed.emit("controller_input_style")

func set_cat_color(color_name: String) -> void:
    if CAT_COLORS.has(color_name):
        data.settings.cat_color = color_name
        save()
        setting_changed.emit("cat_color")

func set_animated_background(enabled: bool) -> void:
    data.settings.animated_background = enabled
    save()
    setting_changed.emit("animated_background")

func apply_audio_settings() -> void:
    _set_bus_volume("Master", master_volume())

func record_session(score: int, max_grade: int, correct_answers: int, best_streak: int, elapsed_seconds: float, correct_by_grade: Dictionary, is_practice: bool, reason: String) -> void:
    data.lifetime.time_played_seconds = int(data.lifetime.time_played_seconds) + roundi(elapsed_seconds)
    for grade in correct_by_grade:
        var bucket := clampi(int(grade), 1, GRADE_BUCKET_COUNT)
        data.lifetime.correct_by_grade[bucket - 1] = int(data.lifetime.correct_by_grade[bucket - 1]) + int(correct_by_grade[grade])

    if is_practice:
        save()
        return

    data.records.highest_score = max(int(data.records.highest_score), score)
    data.records.highest_grade = max(int(data.records.highest_grade), max_grade)
    data.records.most_correct_in_run = max(int(data.records.most_correct_in_run), correct_answers)
    data.records.best_correct_streak = max(int(data.records.best_correct_streak), best_streak)
    data.lifetime.games_played = int(data.lifetime.games_played) + 1
    if reason == GameManager.VICTORY_REASON:
        data.lifetime.victories = int(data.lifetime.victories) + 1
    save()

func reset_statistics() -> void:
    data.records = _default_data().records
    data.lifetime = _default_data().lifetime
    save()

func statistics() -> Dictionary:
    return data.duplicate(true)

func save() -> bool:
    last_save_error = ""
    var temporary := storage_path + ".tmp"
    var backup := storage_path + ".bak"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        last_save_error = "Unable to write profile. Check available storage and permissions."
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    var write_error := file.get_error()
    file.close()
    if write_error != OK:
        last_save_error = "Unable to finish writing profile."
        return false
    if FileAccess.file_exists(storage_path):
        if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
            last_save_error = "Unable to replace profile backup."
            return false
        if DirAccess.rename_absolute(storage_path, backup) != OK:
            last_save_error = "Unable to back up profile."
            return false
    if DirAccess.rename_absolute(temporary, storage_path) != OK:
        if FileAccess.file_exists(backup):
            DirAccess.rename_absolute(backup, storage_path)
        last_save_error = "Unable to replace profile."
        return false
    return true

func adventure_progress(campaign: String) -> Dictionary:
    return data.adventure.get(campaign, AdventureCatalog.default_progress()).duplicate(true)

func adventure_level_unlocked(campaign: String, number: int) -> bool:
    return AdventureCatalog.CAMPAIGNS.has(campaign) and number >= 1 and number <= int(adventure_progress(campaign).highest_unlocked_level)

func buy_adventure_accessory(campaign: String, item: String) -> String:
    if not AdventureCatalog.CAMPAIGNS.has(campaign) or not AdventureCatalog.ACCESSORIES.has(item):
        return "Unknown campaign or accessory."
    var progress: Dictionary = data.adventure[campaign]
    if item in progress.owned_accessories:
        return "Already owned. Equip it for free."
    var price: int = AdventureCatalog.ACCESSORIES[item].price
    if int(progress.currency) < price:
        return "Not enough coins. Complete or replay levels to earn more."
    var before := progress.duplicate(true)
    progress.currency -= price
    progress.owned_accessories.append(item)
    progress.equipped_accessories = AdventureCatalog.with_accessory(progress.equipped_accessories, item)
    return _save_adventure_accessory(campaign, before)

func equip_adventure_accessory(campaign: String, item: String, wear: bool = true) -> String:
    if not AdventureCatalog.CAMPAIGNS.has(campaign):
        return "Unknown campaign."
    var progress: Dictionary = data.adventure[campaign]
    if not item.is_empty() and (not AdventureCatalog.ACCESSORIES.has(item) or not item in progress.owned_accessories):
        return "Buy this accessory before equipping it."
    var before := progress.duplicate(true)
    progress.equipped_accessories = AdventureCatalog.with_accessory(progress.equipped_accessories, item, wear)
    return _save_adventure_accessory(campaign, before)

func _save_adventure_accessory(campaign: String, before: Dictionary) -> String:
    if save():
        return ""
    data.adventure[campaign] = before
    return last_save_error + " Nothing changed. Try again."

func record_adventure_answer(campaign: String, grade: int, is_correct: bool, best_streak: int, elapsed: float) -> void:
    data.lifetime.time_played_seconds += roundi(maxf(elapsed, 0.0))
    var progress: Dictionary = data.adventure[campaign]
    progress.best_streak = maxi(int(progress.best_streak), best_streak)
    if is_correct:
        data.lifetime.correct_by_grade[clampi(grade, 1, GRADE_BUCKET_COUNT) - 1] += 1
        progress.correct_answers += 1
    save()

func complete_adventure_level(config: Dictionary, points: int, remaining_lives: int) -> int:
    var progress: Dictionary = data.adventure[config.campaign]
    var reward := int(config.reward)
    if not int(config.number) in progress.completed_levels:
        progress.completed_levels.append(int(config.number))
        progress.completed_levels.sort()
    progress.currency += reward
    progress.highest_unlocked_level = maxi(int(progress.highest_unlocked_level), mini(int(config.number) + 1, 9))
    progress.campaign_completed = 9 in progress.completed_levels
    var key := str(config.number)
    var result: Dictionary = progress.level_results.get(key, {"best_score": 0, "best_lives": 0, "clears": 0})
    result.best_score = maxi(int(result.best_score), points)
    result.best_lives = maxi(int(result.best_lives), remaining_lives)
    result.clears += 1
    progress.level_results[key] = result
    save()
    return reward

func _load_data() -> Dictionary:
    var defaults := _default_data()
    for path in [storage_path, storage_path + ".bak"]:
        if not FileAccess.file_exists(path):
            continue
        var file := FileAccess.open(path, FileAccess.READ)
        if file == null:
            continue
        var parser := JSON.new()
        var parse_error := parser.parse(file.get_as_text())
        file.close()
        if parse_error == OK and parser.data is Dictionary:
            return _merge_defaults(defaults, parser.data)
    return defaults

func _default_data() -> Dictionary:
    return {
        "settings": {
            "master_volume": 10,
            "music_volume": 10,
            "sfx_volume": 10,
            "controller_input_style": "direct",
            "cat_color": "Orange",
            "animated_background": true,
            "practice_lives": 3,
        },
        "records": {
            "highest_score": 0,
            "highest_grade": 1,
            "most_correct_in_run": 0,
            "best_correct_streak": 0,
        },
        "lifetime": {
            "games_played": 0,
            "victories": 0,
            "time_played_seconds": 0,
            "correct_by_grade": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        },
        "achievements": {
            "unlocked": {},
        },
        "adventure": AdventureCatalog.defaults(),
    }

func _merge_defaults(defaults: Dictionary, loaded: Dictionary) -> Dictionary:
    for key in defaults:
        if not loaded.has(key) or not loaded[key] is Dictionary:
            loaded[key] = defaults[key]
            continue
        for child_key in defaults[key]:
            if not loaded[key].has(child_key):
                loaded[key][child_key] = defaults[key][child_key]
    if not loaded.lifetime.correct_by_grade is Array or loaded.lifetime.correct_by_grade.size() != GRADE_BUCKET_COUNT:
        loaded.lifetime.correct_by_grade = defaults.lifetime.correct_by_grade
    loaded.adventure = AdventureCatalog.normalize(loaded.adventure)
    return loaded

func _volume_db(level: int) -> float:
    return -80.0 if level <= 0 else linear_to_db(float(level) / 10.0)

func _set_bus_volume(bus_name: StringName, level: int) -> void:
    var bus_index := AudioServer.get_bus_index(bus_name)
    if bus_index >= 0:
        AudioServer.set_bus_volume_db(bus_index, _volume_db(level))
