extends Node

const Catalog = preload("res://scripts/adventure/adventure_catalog.gd")
var failures: Array[String] = []
var now := 1000

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func _ready() -> void:
    GameManager.answer_registered.disconnect(AudioManager._on_answer_registered)
    GameManager.session_started.disconnect(AudioManager._on_session_started)
    ProgressionManager.promoted.disconnect(AudioManager._on_promoted)
    ProgressionManager.demoted.disconnect(AudioManager._on_demoted)
    var original := ProfileManager.statistics()
    var original_path := ProfileManager.storage_path
    ProfileManager.storage_path = "user://adventure-system-test.json"
    ProfileManager.data = ProfileManager._default_data()
    for campaign in Catalog.CAMPAIGNS:
        var settings: Dictionary = Catalog.CAMPAIGNS[campaign]
        for number in range(1, 10):
            var config := Catalog.level(campaign, number)
            check(config.character == settings.character, "Campaign character is fixed")
            check(config.grade == (settings.start_grade if number == 9 else settings.start_grade + (number - 1) / 2), "Grade mapping")
            check(config.timer_seconds == (settings.seconds if number < 9 and number % 2 == 0 else 0.0), "Timer mapping")
            check(config.correct_target == 10, "Configurable default target")
        check(ProfileManager.adventure_level_unlocked(campaign, 1), "First level unlocked")
        check(not ProfileManager.adventure_level_unlocked(campaign, 2), "Second level locked")
    var legacy := ProfileManager._default_data()
    legacy.erase("adventure")
    check(ProfileManager._merge_defaults(ProfileManager._default_data(), legacy).adventure == Catalog.defaults(), "Old saves get defaults")
    var corrupt := Catalog.normalize({"elementary": {"completed_levels": [1, 1, 2, 99], "currency": -20, "level_results": []}, "middle": false, "high": {"completed_levels": "bad"}})
    check(corrupt.elementary.completed_levels == [1, 2] and corrupt.elementary.currency == 0, "Normalize corrupt fields")
    check(corrupt.high.highest_unlocked_level == 1 and corrupt.middle.highest_unlocked_level == 1, "Corrupt campaigns reset safely")
    var config := Catalog.level("elementary", 1)
    check(ProfileManager.complete_adventure_level(config, 100, 8) == config.reward, "First clear pays")
    check(ProfileManager.last_save_error.is_empty(), "Save succeeds")
    ProfileManager.data = ProfileManager._load_data()
    check(ProfileManager.adventure_level_unlocked("elementary", 2), "Unlock survives reload")
    check(not ProfileManager.adventure_level_unlocked("middle", 2), "Campaign isolation")
    check(ProfileManager.complete_adventure_level(config, 90, 9) == config.reward, "Successful replay awards the configured coins again")
    ProfileManager.data = ProfileManager._load_data()
    check(ProfileManager.adventure_progress("elementary").currency == config.reward * 2, "Replay coins persist across reload")
    check(ProfileManager.adventure_progress("elementary").level_results["1"].clears == 2, "Replay increments clear count")
    check(ProfileManager.adventure_progress("elementary").level_results["1"].best_score == 100, "Best result retained")
    _test_pet_shop()
    _test_sessions()
    _test_statistics()
    _test_boss_timer()
    var valid_path := ProfileManager.storage_path
    ProfileManager.storage_path = "user://missing-adventure-folder/profile.json"
    check(not ProfileManager.save() and not ProfileManager.last_save_error.is_empty(), "Save failures are explicit")
    ProfileManager.storage_path = valid_path
    check(ProfileManager.save(), "Saving can be retried")
    var persisted: Dictionary = JSON.parse_string(JSON.stringify(ProfileManager.statistics()))
    ProfileManager.data = ProfileManager._load_data()
    check(JSON.parse_string(JSON.stringify(ProfileManager.data)) == persisted, "All completed campaigns survive a fresh profile load")
    ProfileManager.save()
    var damaged := FileAccess.open(ProfileManager.storage_path, FileAccess.WRITE)
    damaged.store_string("invalid json")
    damaged.close()
    check(JSON.parse_string(JSON.stringify(ProfileManager._load_data())) == persisted, "Damaged primary profile recovers the last complete backup")
    ProfileManager.save()
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(ProfileManager.storage_path + suffix):
            DirAccess.remove_absolute(ProfileManager.storage_path + suffix)
    ProfileManager.data = original
    ProfileManager.storage_path = original_path
    print("Adventure system checks: %d failures" % failures.size())
    get_tree().quit(0 if failures.is_empty() else 1)

func _test_pet_shop() -> void:
    var original := ProfileManager.statistics()
    ProfileManager.data = ProfileManager._default_data()
    var legacy := Catalog.normalize({"elementary": {"currency": 75}})
    check(legacy.elementary.currency == 75 and legacy.elementary.owned_accessories.is_empty() and legacy.elementary.equipped_accessories.is_empty(), "Legacy balances survive shop migration")
    var corrupt := Catalog.normalize({"elementary": {"owned_accessories": ["bow_tie", "bow_tie", "unknown", 12], "equipped_accessory": "crown"}, "middle": {"owned_accessories": false, "equipped_accessory": []}})
    check(corrupt.elementary.owned_accessories == ["bow_tie"] and corrupt.elementary.equipped_accessories.is_empty() and corrupt.middle.owned_accessories.is_empty(), "Unknown, duplicate and unowned cosmetics are normalized")
    var migrated := Catalog.normalize({"elementary": {"currency": 123, "owned_accessories": ["crown", "bandana"], "equipped_accessory": "crown"}, "middle": {"owned_accessories": ["bow_tie"], "equipped_accessory": "bow_tie"}})
    check(migrated.elementary.equipped_accessories == {"head": "crown"} and migrated.elementary.currency == 123 and migrated.elementary.owned_accessories == ["crown", "bandana"], "Single-item saves migrate without changing purchases or coins")
    check(migrated.middle.equipped_accessories == {"neck": "bow_tie"}, "Legacy neck equipment migrates into the neck slot")
    corrupt = Catalog.normalize({"elementary": {"owned_accessories": ["bow_tie", "crown"], "equipped_accessories": {"head": "bandana", "neck": "crown", "unknown": "bow_tie"}}, "middle": {"owned_accessories": ["crown"], "equipped_accessories": [], "equipped_accessory": "crown"}, "high": {"owned_accessories": ["crown"], "equipped_accessories": {}, "equipped_accessory": "crown"}})
    check(corrupt.elementary.equipped_accessories.is_empty() and corrupt.middle.equipped_accessories.is_empty() and corrupt.high.equipped_accessories.is_empty(), "Invalid slots, unowned items and malformed outfits are rejected without resurrecting legacy equipment")
    var before := ProfileManager.statistics()
    check(not ProfileManager.buy_adventure_accessory("unknown", "bow_tie").is_empty(), "Invalid campaign reports an error")
    check(not ProfileManager.buy_adventure_accessory("elementary", "unknown").is_empty(), "Invalid item reports an error")
    check(not ProfileManager.buy_adventure_accessory("elementary", "bow_tie").is_empty(), "Insufficient funds report an error")
    check(not ProfileManager.equip_adventure_accessory("elementary", "crown").is_empty(), "Cannot equip unowned items")
    check(ProfileManager.statistics() == before, "Rejected transactions leave all data unchanged")
    check(Catalog.ACCESSORIES.size() == 7, "Pet Shop has seven cosmetics")
    for campaign in Catalog.CAMPAIGNS:
        var expected_outfit := {}
        for item in Catalog.ACCESSORIES:
            var price: int = Catalog.ACCESSORIES[item].price
            ProfileManager.data.adventure[campaign].currency = price - 1
            check(not ProfileManager.buy_adventure_accessory(campaign, item).is_empty(), "One coin short cannot buy")
            ProfileManager.data.adventure[campaign].currency = price
            before = ProfileManager.statistics()
            check(ProfileManager.buy_adventure_accessory(campaign, item).is_empty(), "Exact balance can buy")
            var progress := ProfileManager.adventure_progress(campaign)
            expected_outfit[Catalog.ACCESSORIES[item].slot] = item
            check(progress.equipped_accessories == expected_outfit, "Every purchase replaces only its slot and preserves compatible items")
            check(progress.currency == 0 and item in progress.owned_accessories and progress.equipped_accessories[Catalog.ACCESSORIES[item].slot] == item, "Purchase charges exactly once and equips its slot")
            check(not ProfileManager.buy_adventure_accessory(campaign, item).is_empty() and ProfileManager.adventure_progress(campaign) == progress, "Duplicate purchase never charges again")
            for other in Catalog.CAMPAIGNS:
                if other != campaign:
                    check(ProfileManager.adventure_progress(other) == before.adventure[other], "Purchase cannot change another campaign")
            ProfileManager.data = ProfileManager._load_data()
            check(ProfileManager.adventure_progress(campaign) == progress, "Purchase and equipment survive reload")
        check(ProfileManager.adventure_progress(campaign).equipped_accessories == {"head": "flower", "face": "sunglasses", "neck": "bell_collar"}, "New cosmetics combine across all three slots")
        check(ProfileManager.equip_adventure_accessory(campaign, "top_hat").is_empty() and ProfileManager.adventure_progress(campaign).equipped_accessories == {"head": "top_hat", "face": "sunglasses", "neck": "bell_collar"}, "Top hat replaces flower without affecting glasses or collar")
        check(ProfileManager.equip_adventure_accessory(campaign, "sunglasses", false).is_empty() and ProfileManager.adventure_progress(campaign).equipped_accessories == {"head": "top_hat", "neck": "bell_collar"}, "Removing face equipment preserves head and neck slots")
        check(ProfileManager.equip_adventure_accessory(campaign, "").is_empty(), "Clear new outfit")
        check(ProfileManager.equip_adventure_accessory(campaign, "crown").is_empty() and ProfileManager.equip_adventure_accessory(campaign, "bandana").is_empty(), "Original two-slot outfits remain available")
        check(ProfileManager.equip_adventure_accessory(campaign, "bow_tie").is_empty(), "Owned equipment is free to switch")
        check(ProfileManager.adventure_progress(campaign).equipped_accessories == {"head": "crown", "neck": "bow_tie"}, "Equipping a neck item replaces only the conflicting slot")
        check(ProfileManager.equip_adventure_accessory(campaign, "bandana", false).is_empty() and ProfileManager.adventure_progress(campaign).equipped_accessories.neck == "bow_tie", "Removing an unworn item cannot remove a different item in its slot")
        check(ProfileManager.equip_adventure_accessory(campaign, "crown", false).is_empty() and ProfileManager.adventure_progress(campaign).equipped_accessories == {"neck": "bow_tie"}, "Removing the crown preserves neck equipment")
        check(ProfileManager.equip_adventure_accessory(campaign, "crown").is_empty(), "Crown can be re-equipped alongside bow tie")
        check(ProfileManager.equip_adventure_accessory(campaign, "bow_tie", false).is_empty() and ProfileManager.adventure_progress(campaign).equipped_accessories == {"head": "crown"}, "Removing neck equipment preserves the crown")
        check(ProfileManager.equip_adventure_accessory(campaign, "").is_empty() and ProfileManager.adventure_progress(campaign).equipped_accessories.is_empty(), "Remove All clears every slot for free")
        check(ProfileManager.adventure_progress(campaign).currency == 0, "Equipping never costs coins")
    check(JSON.parse_string(JSON.stringify(ProfileManager.data.settings)) == JSON.parse_string(JSON.stringify(original.settings)) and JSON.parse_string(JSON.stringify(ProfileManager.data.records)) == JSON.parse_string(JSON.stringify(ProfileManager._default_data().records)), "Cosmetics do not change free colors or records")
    ProfileManager.data = ProfileManager._default_data()
    ProfileManager.data.adventure.elementary.currency = 350
    check(ProfileManager.buy_adventure_accessory("elementary", "bandana").is_empty(), "Set up an existing neck accessory before a failed crown purchase")
    before = ProfileManager.statistics()
    var valid_path := ProfileManager.storage_path
    ProfileManager.storage_path = "user://missing-pet-shop-folder/profile.json"
    check(not ProfileManager.buy_adventure_accessory("elementary", "crown").is_empty(), "Failed purchase save reports an error")
    check(ProfileManager.statistics() == before, "Failed purchase rolls back coins, ownership and equipment")
    ProfileManager.storage_path = valid_path
    check(JSON.parse_string(JSON.stringify(ProfileManager._load_data())) == JSON.parse_string(JSON.stringify(before)), "Failed purchase leaves saved profile unchanged")
    check(ProfileManager.buy_adventure_accessory("elementary", "crown").is_empty(), "Purchase can be retried after storage recovery")
    check(ProfileManager.adventure_progress("elementary").equipped_accessories == {"head": "crown", "neck": "bandana"}, "Purchase retry preserves the existing neck accessory")
    before = ProfileManager.statistics()
    ProfileManager.storage_path = "user://missing-pet-shop-folder/profile.json"
    check(not ProfileManager.equip_adventure_accessory("elementary", "crown", false).is_empty() and ProfileManager.statistics() == before, "Failed single-item removal rolls back the entire outfit")
    ProfileManager.storage_path = valid_path
    check(ProfileManager.equip_adventure_accessory("elementary", "crown", false).is_empty() and ProfileManager.adventure_progress("elementary").equipped_accessories == {"neck": "bandana"}, "Unequip retry succeeds without removing other slots")
    ProfileManager.data = original
    ProfileManager.save()

func _question() -> int:
    if GameManager.current_state in [GameManager.GameState.LEVEL_UP, GameManager.GameState.DEMOTION]:
        GameManager.set_state(GameManager.GameState.PLAYING)
    var question_id := GameManager.prepare_adventure_question()
    GameManager.ready_adventure_question(GameManager.session_serial, question_id)
    return question_id

func _test_sessions() -> void:
    GameManager.clock_msec = func(): return now
    var original_records: Dictionary = ProfileManager.data.records.duplicate(true)
    for campaign in Catalog.CAMPAIGNS:
        ProfileManager.data.adventure[campaign] = Catalog.default_progress()
        for number in range(1, 10):
            check(GameManager.start_adventure_level(campaign, number), "Unlocked level can start")
            check(GameManager.lives == 9, "Each attempt starts with nine lives")
            var config := GameManager.adventure_config
            if number < 9:
                GameManager.adventure_config.correct_target = 2
                var question_id := _question()
                if config.timed:
                    now += 1000
                    GameManager.set_state(GameManager.GameState.PAUSED)
                    var remaining := GameManager._adventure_remaining
                    now += 30000
                    GameManager.sync_adventure_clock()
                    check(GameManager._adventure_remaining == remaining, "Pause freezes the deadline")
                    GameManager.set_state(GameManager.GameState.PLAYING)
                    now += remaining
                    check(not GameManager.submit_adventure_answer(true, false, GameManager.session_serial, question_id), "Timeout wins an exact-deadline answer race")
                    check(GameManager.lives == 8 and GameManager.total_incorrect_answers == 1 and GameManager.total_correct_answers == 0, "Timeout costs exactly one life and no progress")
                    GameManager.sync_adventure_clock()
                    check(GameManager.lives == 8, "Repeated clock polls cannot repeat timeout")
                else:
                    now += 1000000
                    GameManager.sync_adventure_clock()
                    check(GameManager.adventure_question_open and GameManager.lives == 9, "Untimed questions never expire")
                    GameManager.submit_adventure_answer(false, false, GameManager.session_serial, question_id)
                    check(GameManager.lives == 8, "Wrong answer costs one life")
                for answer in 2:
                    question_id = _question()
                    check(GameManager.submit_adventure_answer(true, true, GameManager.session_serial, question_id), "Accept a ready answer")
                    check(not GameManager.submit_adventure_answer(false, false, GameManager.session_serial, question_id), "Exactly one outcome per question")
                check(GameManager.current_state == GameManager.GameState.LEVEL_COMPLETE, "Configurable fixed-grade completion")
                check(ProgressionManager.current_grade == config.grade, "Fixed grade does not promote")
            else:
                for mistake in 3:
                    _question()
                    GameManager.register_answer(false)
                check(ProgressionManager.current_grade == config.boss_start_grade, "Boss demotion respects campaign floor")
                for answer in 20:
                    _question()
                    GameManager.register_answer(true)
                check(GameManager.current_state == GameManager.GameState.CAMPAIGN_COMPLETE, "Boss stops at campaign victory boundary")
                check(ProgressionManager.current_grade == config.boss_victory_grade, "Boss victory grade")
                check(ProfileManager.adventure_progress(campaign).campaign_completed, "Boss completion persisted")
            check(ProfileManager.last_save_error.is_empty(), "Completion saves immediately")
        for replay_number in [1, 9]:
            var before_replay := ProfileManager.adventure_progress(campaign)
            GameManager.start_adventure_level(campaign, replay_number)
            GameManager.adventure_config.correct_target = 2
            for answer in range(20 if replay_number == 9 else 2):
                _question()
                GameManager.register_answer(true)
            var reward: int = GameManager.adventure_config.reward
            var expected_currency: int = before_replay.currency + reward
            check(GameManager.adventure_reward == reward and ProfileManager.adventure_progress(campaign).currency == expected_currency, "Normal and boss replays each earn their configured coins")
            check(ProfileManager.adventure_progress(campaign).completed_levels == before_replay.completed_levels, "Replay rewards do not duplicate completed map nodes")
            var paid_progress := ProfileManager.adventure_progress(campaign)
            GameManager._finish_adventure(true)
            ProfileManager.save()
            check(ProfileManager.adventure_progress(campaign) == paid_progress, "Duplicate completion and save retry cannot pay a finished attempt twice")
        var completed := ProfileManager.adventure_progress(campaign)
        GameManager.start_adventure_level(campaign, 1)
        for mistake in 9:
            _question()
            GameManager.register_answer(false)
        check(GameManager.current_state == GameManager.GameState.LEVEL_FAILED and GameManager.lives == 0, "Nine mistakes fail the attempt")
        check(ProfileManager.adventure_progress(campaign).completed_levels == completed.completed_levels, "Failure preserves campaign progress")
        GameManager.restart_current_session()
        check(GameManager.is_adventure_mode() and GameManager.adventure_config.number == 1 and GameManager.lives == 9, "Restart restores this level and nine lives")
        var question_id := _question()
        var serial := GameManager.session_serial
        GameManager.restart_current_session()
        check(not GameManager.submit_adventure_answer(true, false, serial, question_id), "Stale answers cannot reach a restarted attempt")
        GameManager.open_adventure(campaign)
        check(ProfileManager.adventure_progress(campaign).completed_levels == completed.completed_levels, "Returning to map does not complete a level")
        GameManager.start_blitz_session(3)
        GameManager.start_session()
        check(ProfileManager.adventure_progress(campaign).completed_levels == completed.completed_levels, "Other modes do not erase Adventure")
    check(ProfileManager.data.records == original_records, "Adventure does not alter Retro records")
    check(AchievementManager.is_unlocked(AchievementManager.PI_DAY), "Adventure permits question-specific achievements")
    check(not AchievementManager.is_unlocked(AchievementManager.VICTORY), "Adventure does not award Retro victory")
    GameManager.start_session()
    check(ProgressionManager.grade_floor == 1, "Retro resets progression floor")
    GameManager.clock_msec = Time.get_ticks_msec

func _test_boss_timer() -> void:
    for campaign in Catalog.CAMPAIGNS:
        var saved_progress := ProfileManager.adventure_progress(campaign)
        GameManager.start_adventure_level(campaign, 9)
        check(GameManager.time_left == 120.0, "Boss starts with Retro's two-minute session timer")
        _question()
        GameManager._process(1.25)
        check(GameManager.time_left == 118.75, "Boss uses the Retro countdown")
        GameManager.register_answer(true)
        GameManager._process(0.75)
        check(GameManager.time_left == 118.0, "Normal answer feedback consumes boss time like Retro")
        _question()
        check(GameManager.time_left == 118.0, "New boss questions do not reset session time")
        GameManager.set_state(GameManager.GameState.PAUSED)
        GameManager._process(30.0)
        check(GameManager.time_left == 118.0, "Pause freezes the boss session clock")
        GameManager.set_state(GameManager.GameState.PLAYING)
        for answer in 4:
            _question()
            GameManager.register_answer(true)
        var promoted_time := 118.0 + float(Catalog.CAMPAIGNS[campaign].start_grade) * GameManager.TIME_BONUS_PER_COMPLETED_GRADE
        check(GameManager.time_left == promoted_time and GameManager.current_state == GameManager.GameState.LEVEL_UP, "Five correct answers earn the Retro grade time bonus and celebration state")
        GameManager._process(2.0)
        check(GameManager.time_left == promoted_time, "Level-up celebration freezes the boss timer")
        for mistake in 3:
            _question()
            GameManager.register_answer(false)
        check(GameManager.current_state == GameManager.GameState.DEMOTION, "Boss demotion uses the Retro feedback state")
        GameManager._process(2.0)
        check(GameManager.time_left == promoted_time, "Demotion feedback freezes the boss timer")
        _question()
        GameManager.time_left = 0.25
        var remaining_lives := GameManager.lives
        var results: Array[bool] = []
        var on_finished := func(success: bool): results.append(success)
        GameManager.adventure_finished.connect(on_finished)
        GameManager._process(1.0)
        GameManager._process(1.0)
        check(GameManager.time_left == 0.0 and GameManager.current_state == GameManager.GameState.LEVEL_FAILED, "Boss expires at zero without a negative timer")
        check(GameManager.last_end_reason == "time_up" and GameManager.lives == remaining_lives and results == [false], "Expiry fails the attempt once, without a per-question life penalty")
        GameManager.adventure_finished.disconnect(on_finished)
        var progress := ProfileManager.adventure_progress(campaign)
        for key in ["highest_unlocked_level", "completed_levels", "campaign_completed", "currency", "level_results"]:
            check(progress[key] == saved_progress[key], "Boss timeout preserves " + key)
        GameManager.restart_current_session()
        check(GameManager.time_left == 120.0 and GameManager.lives == 9, "Boss restart restores two minutes and nine lives")
        var token := _question()
        GameManager.time_left = 0.0
        check(not GameManager.submit_adventure_answer(true, false, GameManager.session_serial, token), "An answer at zero cannot rescue an expired boss")
    GameManager.abandon_current_session()

func _test_statistics() -> void:
    GameManager.clock_msec = func(): return now
    ProfileManager.data.achievements.unlocked.clear()
    ProfileManager.data.lifetime.correct_by_grade.fill(0)
    ProfileManager.data.lifetime.correct_by_grade[0] = 759
    var records: Dictionary = ProfileManager.data.records.duplicate(true)
    GameManager.start_adventure_level("elementary", 1)
    _question()
    GameManager.register_answer(true)
    check(ProfileManager.data.lifetime.correct_by_grade[0] == 760, "Adventure answer persists exactly once")
    check(not AchievementManager.is_unlocked(AchievementManager.TRUST_THE_PROCESS), "Session totals are not added twice for lifetime achievements")
    _question()
    GameManager.register_answer(true)
    check(AchievementManager.is_unlocked(AchievementManager.TRUST_THE_PROCESS), "Lifetime threshold unlocks at the exact count")
    for answer in 8:
        _question()
        GameManager.register_answer(true)
    check(AchievementManager.is_unlocked(AchievementManager.HOT_STREAK), "Adventure streaks unlock eligible achievements")
    GameManager.start_adventure_level("elementary", 7)
    _question()
    now += 1500
    GameManager.set_state(GameManager.GameState.PAUSED)
    now += 20000
    GameManager.set_state(GameManager.GameState.PLAYING)
    now += 1000
    GameManager.register_answer(true, true)
    check(AchievementManager.is_unlocked(AchievementManager.THAT_WAS_FAST), "Paused time is excluded from response achievements")
    check(AchievementManager.is_unlocked(AchievementManager.PI_DAY), "Pi question remains eligible")
    check(ProfileManager.data.lifetime.correct_by_grade[3] == 1, "Adventure answer reaches the correct grade bucket")
    GameManager.start_adventure_level("middle", 9)
    for answer in 5:
        _question()
        GameManager.register_answer(true)
    check(ProgressionManager.current_grade == 6, "Boss uses the shared five-correct promotion rule")
    for mistake in 3:
        _question()
        GameManager.register_answer(false)
    check(ProgressionManager.current_grade == 5 and GameManager.lives == 6, "Boss uses three-incorrect demotion and single life losses")
    for achievement in [AchievementManager.MATH_KITTEN, AchievementManager.MATH_CAT, AchievementManager.MATH_TIGER, AchievementManager.VICTORY, AchievementManager.PERFECT_GAME]:
        check(not AchievementManager.is_unlocked(achievement), "Adventure excludes Retro-only achievement: " + achievement)
    check(ProfileManager.data.records == records, "Adventure statistics never overwrite Retro records")
    GameManager.abandon_current_session()
    GameManager.clock_msec = Time.get_ticks_msec