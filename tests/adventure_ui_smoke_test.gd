extends Node

const HubScene = preload("res://scenes/adventure/adventure_hub.tscn")
const EXPECTED_LEVEL_NAMES := {
    "elementary": ["The Oregon Math Trail", "Duck Count", "River City Subtraction", "ExciteMath", "Mathlevania", "StarCat 64", "Divide Horizon", "Metal Gear Kitten", "The Legend of Math Cat"],
    "middle": ["Mega Math Cat", "Street Fraction II", "Double Decimal", "Super Mathorid", "Streets of Algebra", "The Elder Sums", "Microsoft Flight Calculator", "Gears of Bar Charts", "Teenage Mutant Ninja Mathematicians"],
    "high": ["Super Variable Bros.", "Final Factoring", "F(x)-Zero", "Conker's Bad Equation Day", "Resident Equal", "Derivative Kong Country", "Halo: Calculus Evolved", "Killer Integral", "Chrono Trigonometry"],
}
var failures: Array[String] = []
var now := 1000

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func _ready() -> void:
    var main := preload("res://scripts/main.gd").new()
    main._configure_input_map()
    main.free()
    ProfileManager.storage_path = "user://adventure-ui-test.json"
    ProfileManager.data = ProfileManager._default_data()
    GameManager.clock_msec = func(): return now
    var title = preload("res://scenes/title/title.tscn").instantiate()
    add_child(title)
    await _frames()
    check(title.main_buttons[2].text == "ADVENTURE", "Adventure is the third game mode")
    await _capture("title")
    title.queue_free()
    await _frames()
    GameManager.open_adventure()
    var hub := HubScene.instantiate()
    add_child(hub)
    await get_tree().process_frame
    check(hub.buttons.size() == 4, "Three campaigns and Back")
    check(hub.buttons[0].has_focus() and hub.selected == 0, "Adventure opens with Elementary highlighted")
    await _capture("campaigns")
    var key := InputEventKey.new()
    key.keycode = KEY_RIGHT
    key.pressed = true
    hub._input(key)
    check(hub.buttons[1].has_focus() and hub.selected == 1, "Keyboard highlight and focus agree")
    hub.show_campaigns()
    var controller_right := InputEventJoypadButton.new()
    controller_right.button_index = JOY_BUTTON_DPAD_RIGHT
    controller_right.pressed = true
    hub._input(controller_right)
    check(hub.buttons[1].has_focus() and hub.selected == 1, "Controller selection moves from Elementary to Middle")
    var elementary_hover := hub.buttons[0].get_theme_stylebox("hover") as StyleBoxFlat
    check(elementary_hover.border_color == hub.CYAN, "Controller navigation clears Elementary's stale mouse highlight")
    ProfileManager.set_animated_background(false)
    var frozen_clock: float = hub.background_clock
    await _frames()
    check(not hub.is_processing() and hub.background_clock == frozen_clock, "Disabled background freezes the map sky and grid")
    ProfileManager.set_animated_background(true)
    await _frames()
    check(hub.is_processing() and hub.background_clock > frozen_clock, "Re-enabled background resumes the map sky and grid")
    for campaign in GameManager.AdventureCatalog.CAMPAIGNS:
        hub.show_map(campaign)
        await get_tree().process_frame
        check(hub.level_buttons.size() == 9, "Nine map nodes")
        for number in range(1, 10):
            check(GameManager.AdventureCatalog.level(campaign, number).city_name == EXPECTED_LEVEL_NAMES[campaign][number - 1], "Map title matches the authored " + campaign + " level " + str(number))
        check(hub.buttons.size() == 3, "Only level one, Pet Shop and Back can focus")
        check(hub.level_buttons[0].has_focus(), "Available level focused")
        _check_stage_gradient(hub)
        var stick := InputEventJoypadMotion.new()
        stick.axis = JOY_AXIS_LEFT_Y
        stick.axis_value = 1.0
        hub.navigation_ready_at = 0
        hub._input(stick)
        check(hub.buttons[1].has_focus() and hub.buttons[1].text == "PET SHOP", "Joystick skips locked nodes to Pet Shop")
        hub._input(stick)
        check(hub.buttons[1].has_focus(), "Map joystick enforces its 100ms cooldown")
        hub.buttons[0].grab_focus()
        check(hub.selected == 0, "Mouse or GUI focus keeps the active map selection synchronized")
        for index in range(1, 9):
            check(hub.level_buttons[index].disabled and hub.level_buttons[index].focus_mode == Control.FOCUS_NONE, "Locked nodes not actionable")
        check(not GameManager.start_adventure_level(campaign, 9), "Cannot enter locked boss")
        ProfileManager.complete_adventure_level(GameManager.AdventureCatalog.level(campaign, 1), 100, 9)
        hub.show_map(campaign)
        check(hub.level_buttons[1].has_focus() and hub.level_buttons[0].text.contains("DONE"), "New unlock selected and completed level marked")
        check(hub.map_cat.position == hub.MAP_POINTS[1] + Vector2(0, -66), "Campaign cat stays above the selected stage")
        _check_stage_gradient(hub)
        await _capture("map-" + campaign)
    await _test_map_animations(hub)
    await _test_pet_shop(hub)
    ProfileManager.set_animated_background(false)
    frozen_clock = hub.background_clock
    hub.show_map("elementary")
    await _frames()
    check(not hub.is_processing() and hub.background_clock == frozen_clock, "Rebuilding the map preserves the static background preference")
    await _capture("map-static")
    var original_size: Vector2 = hub.size
    hub.size = Vector2(960, 540)
    hub._resize()
    check(hub.canvas.scale.is_equal_approx(Vector2(0.75, 0.75)), "Map art and buttons share the 960x540 scale")
    for button in hub.level_buttons:
        var number := int(button.get_meta("level"))
        check(button.position == hub.MAP_POINTS[number - 1] - Vector2(58, 32), "Scaled map retains all nine original hit targets")
    await _capture("map-small")
    hub.size = original_size
    hub._resize()
    var elementary_progress: Dictionary = ProfileManager.data.adventure.elementary.duplicate(true)
    for number in range(2, 10):
        ProfileManager.complete_adventure_level(GameManager.AdventureCatalog.level("elementary", number), 100, 9)
    hub.show_map("elementary")
    check(hub.buttons.size() == 11 and hub.level_buttons[8].has_focus(), "Completed map keeps every level and boss replayable, with Pet Shop and Back")
    check(hub.level_buttons[8].text == "BOSS\nDONE", "Boss completion remains distinct in the city-trail map")
    _check_stage_gradient(hub)
    await _capture("map-complete")
    hub.buttons.back().grab_focus()
    await _capture("map-complete-unfocused")
    # Restore the fixture expected by the shared gameplay checks below.
    ProfileManager.data.adventure.elementary = elementary_progress
    ProfileManager.set_animated_background(true)
    hub.queue_free()
    await get_tree().process_frame
    if "--map-only" not in OS.get_cmdline_user_args():
        await _test_gameplay()
        await _test_scene_navigation()
    GameManager.clock_msec = Time.get_ticks_msec
    for player in AudioManager._players + AudioManager._music_players:
        player.stop()
        player.stream = null
    await _frames()
    print("Adventure UI checks: %d failures" % failures.size())
    get_tree().quit(0 if failures.is_empty() else 1)

func _frames() -> void:
    for frame in 5:
        await get_tree().process_frame

func _test_map_animations(hub: Control) -> void:
    var saved_data: Dictionary = ProfileManager.data.duplicate(true)
    ProfileManager.set_animated_background(false)
    for campaign in GameManager.AdventureCatalog.CAMPAIGNS:
        ProfileManager.data.adventure[campaign] = GameManager.AdventureCatalog.default_progress()
        for number in range(1, 9):
            check(GameManager.start_adventure_level(campaign, number), "Animation fixture starts an unlocked level")
            GameManager._finish_adventure(true)
            var transition: Dictionary = GameManager.adventure_map_transition.duplicate()
            GameManager._finish_adventure(true)
            check(GameManager.adventure_map_transition == transition, "Duplicate completion cannot replace the map transition")
            GameManager.open_adventure(campaign)
            hub.show_map(campaign)
            var start: Vector2 = hub.MAP_POINTS[number - 1] + Vector2(0, -66)
            var finish: Vector2 = hub.MAP_POINTS[number] + Vector2(0, -66)
            check(hub.map_cat.position == start and hub.level_buttons[number].has_focus(), "Unlock animation begins at the completed node with the next level selected")
            check(GameManager.adventure_map_transition.is_empty(), "Map consumes the completion animation once")
            var tween: Tween = hub.map_cat_tween
            check(tween != null, "Every new unlock creates a movement tween")
            if tween != null:
                tween.pause()
                tween.custom_step(0.675)
                check(hub.map_cat.position.is_equal_approx(start.lerp(finish, 0.5) + Vector2(0, -24)), "Cat moves halfway along each connector with a visible hop, even with background animation off")
                tween.custom_step(1.0)
                check(hub.map_cat.position == finish and hub.map_cat_tween == null and hub.map_cat.animation == "idle", "Cat lands exactly above the new node and returns to idle")
            hub.show_map(campaign)
            check(hub.map_cat_tween == null and hub.map_cat.position == finish, "Reopening the map does not repeat the unlock")
        for replay in 2:
            GameManager.start_adventure_level(campaign, 9)
            GameManager._finish_adventure(true)
            GameManager.open_adventure(campaign)
            hub.show_map(campaign)
            var home: Vector2 = hub.MAP_POINTS[8] + Vector2(0, -66)
            var tween: Tween = hub.map_cat_tween
            check(tween != null and hub.map_cat.position == home, "Boss wins and replays celebrate at the boss node")
            if tween != null:
                tween.pause()
                tween.custom_step(0.25)
                for jump in 3:
                    tween.custom_step(0.22)
                    check(hub.map_cat.position.is_equal_approx(home - Vector2(0, 28)), "Boss celebration reaches the peak of jump %d" % (jump + 1))
                    tween.custom_step(0.22)
                    check(hub.map_cat.position.is_equal_approx(home), "Boss celebration lands jump %d in place" % (jump + 1))
                    tween.custom_step(0.1)
                tween.custom_step(0.01)
                check(hub.map_cat_tween == null and hub.map_cat.animation == "idle", "Boss celebration stops after exactly three jumps")
        GameManager.start_adventure_level(campaign, 1)
        GameManager._finish_adventure(true)
        hub.show_map(campaign)
        check(hub.map_cat_tween == null, "Ordinary replays do not invent a new unlock")
        GameManager.start_adventure_level(campaign, 9)
        GameManager._finish_adventure(false)
        hub.show_map(campaign)
        check(hub.map_cat_tween == null, "Failed attempts do not celebrate")
        GameManager.start_adventure_level(campaign, 9)
        hub.show_map(campaign)
        check(hub.map_cat_tween == null, "Abandoned attempts do not celebrate")
    GameManager.start_adventure_level("elementary", 9)
    GameManager._finish_adventure(true)
    hub.show_map("elementary")
    var interrupted: Tween = hub.map_cat_tween
    hub.buttons[0].grab_focus()
    check(hub.map_cat_tween == null and not interrupted.is_valid() and hub.map_cat.position == hub.MAP_POINTS[0] + Vector2(0, -66), "Manual stage selection cancels the animation and moves to the selected stage")
    GameManager.start_adventure_level("elementary", 9)
    GameManager._finish_adventure(true)
    hub.show_map("elementary")
    interrupted = hub.map_cat_tween
    hub.show_shop()
    check(hub.map_cat_tween == null and not interrupted.is_valid(), "Leaving the map kills its tween before freeing the cat")
    await _frames()
    hub.show_map("elementary")
    check(hub.map_cat_tween == null, "Returning from the shop does not replay a celebration")
    GameManager.start_adventure_level("elementary", 9)
    GameManager._finish_adventure(true)
    hub.show_map("middle")
    check(hub.map_cat_tween == null, "A different campaign cannot inherit a pending celebration")
    GameManager.start_adventure_level("elementary", 9)
    GameManager._finish_adventure(true)
    GameManager.start_session()
    check(GameManager.adventure_map_transition.is_empty(), "Starting another mode clears pending Adventure animation")
    ProfileManager.data = saved_data
    ProfileManager.save()
    hub._on_setting_changed("animated_background")

func _test_pet_shop(hub: Control) -> void:
    var catalog = GameManager.AdventureCatalog
    var accept := InputEventKey.new()
    accept.keycode = KEY_ENTER
    accept.pressed = true
    var cancel := InputEventJoypadButton.new()
    cancel.button_index = JOY_BUTTON_B
    cancel.pressed = true
    for campaign in catalog.CAMPAIGNS:
        hub.show_map(campaign)
        for button in hub.buttons:
            if button.text == "PET SHOP":
                button.grab_focus()
                break
        hub._input(accept)
        check(hub.shop_visible and not hub.map_visible, "Map opens Pet Shop by keyboard")
        var before := ProfileManager.adventure_progress(campaign)
        hub.shop_item_buttons["crown"].grab_focus()
        check(hub.shop_cat.equipped_accessories == {"head": "crown"} and ProfileManager.adventure_progress(campaign) == before, "Focus previews without spending or equipping")
        hub._input(accept)
        check(hub.shop_action.has_focus(), "Selecting an item focuses its explicit purchase action")
        hub._input(accept)
        check(hub.shop_status.text.contains("Not enough") and ProfileManager.adventure_progress(campaign) == before, "Unaffordable purchase shows an error without changing data")
        if campaign == "elementary":
            await _capture("shop-unaffordable")
        ProfileManager.data.adventure[campaign].currency = 350
        hub.show_shop()
        for index in range(1, 4):
            var item: String = catalog.ACCESSORIES.keys()[index - 1]
            hub.shop_item_buttons[item].grab_focus()
            hub.shop_item_buttons[item].pressed.emit()
            hub.shop_action.pressed.emit()
            check(ProfileManager.adventure_progress(campaign).equipped_accessories[catalog.ACCESSORIES[item].slot] == item and hub.shop_action.text == "REMOVE - FREE", "Mouse purchase equips and offers individual removal")
            await _capture("shop-%s-%s" % [campaign, item])
        check(ProfileManager.adventure_progress(campaign).currency == 0, "Three purchases cost exactly 350 coins")
        ProfileManager.data = ProfileManager._load_data()
        hub.show_shop()
        check(hub.shop_cat.equipped_accessories == {"head": "crown", "neck": "bandana"}, "Combined equipment survives profile reload")
        before = ProfileManager.adventure_progress(campaign)
        hub.shop_item_buttons["bow_tie"].grab_focus()
        check(hub.shop_cat.equipped_accessories == {"head": "crown", "neck": "bow_tie"} and ProfileManager.adventure_progress(campaign) == before, "Preview replaces only conflicting neck equipment without saving")
        await _capture("shop-%s-combined-preview" % campaign)
        hub._input(accept)
        hub._input(accept)
        check(ProfileManager.adventure_progress(campaign).equipped_accessories == {"head": "crown", "neck": "bow_tie"}, "Equipping bow tie preserves the crown")
        hub._input(accept)
        check(ProfileManager.adventure_progress(campaign).equipped_accessories == {"head": "crown"} and hub.shop_cat.equipped_accessories == {"head": "crown"}, "Remove button removes only the selected accessory and updates the cat")
        _check_shop_slots(hub, {"head": "crown"})
        hub.shop_item_buttons["bandana"].grab_focus()
        hub._input(accept)
        hub._input(accept)
        hub.shop_item_buttons["crown"].grab_focus()
        hub._input(accept)
        hub._input(accept)
        check(ProfileManager.adventure_progress(campaign).equipped_accessories == {"neck": "bandana"}, "Removing the crown leaves the bandana on")
        hub._input(accept)
        check(ProfileManager.adventure_progress(campaign).equipped_accessories.size() == 2, "Re-equipping the crown restores both slots before Remove All")
        hub.shop_remove_all.grab_focus()
        hub._input(accept)
        hub._input(accept)
        check(ProfileManager.adventure_progress(campaign).equipped_accessories.is_empty() and hub.shop_cat.equipped_accessories.is_empty(), "Remove All unequips for free")
        _check_shop_slots(hub, {})
        if campaign == "elementary":
            await _capture("shop-remove-all")
        hub.shop_item_buttons["crown"].grab_focus()
        hub._input(accept)
        var storage_path := ProfileManager.storage_path
        ProfileManager.storage_path = "user://missing-pet-shop-ui-folder/profile.json"
        hub._input(accept)
        check(hub.shop_status.text.contains("Nothing changed") and ProfileManager.adventure_progress(campaign).equipped_accessories.is_empty(), "Shop displays save failure and preserves equipment")
        if campaign == "elementary":
            await _capture("shop-save-error")
        ProfileManager.storage_path = storage_path
        hub._input(accept)
        check(ProfileManager.adventure_progress(campaign).equipped_accessories == {"head": "crown"} and ProfileManager.adventure_progress(campaign).currency == 0, "Failed equip can be retried for free")
        hub.shop_item_buttons["bandana"].grab_focus()
        hub._input(accept)
        hub._input(accept)
        await _test_new_cosmetics(hub, campaign)
        hub._input(cancel)
        check(hub.map_visible and hub.map_cat.equipped_accessories == {"head": "top_hat", "face": "sunglasses", "neck": "bell_collar"}, "Controller Back returns to the map wearing the saved three-slot outfit")
    hub.show_campaigns()
    var equipped_cats := 0
    for child in hub.canvas.get_children():
        if child is MathCat and child.equipped_accessories == {"head": "top_hat", "face": "sunglasses", "neck": "bell_collar"}:
            equipped_cats += 1
    check(equipped_cats == 3, "Campaign selection shows each campaign's saved accessory")
    var plain_cat := preload("res://scenes/characters/math_cat.tscn").instantiate()
    add_child(plain_cat)
    check(plain_cat.equipped_accessories.is_empty() and plain_cat._accessory == null, "Cats outside Adventure remain unchanged")
    plain_cat.queue_free()
    GameManager.start_session()
    var game = preload("res://scenes/game/game.tscn").instantiate()
    add_child(game)
    await _frames()
    check(game.math_cat.equipped_accessories.is_empty(), "Retro ignores owned Adventure accessories")
    GameManager.start_adventure_level("high", 1)
    await _frames()
    check(game.math_cat.equipped_accessories == {"head": "top_hat", "face": "sunglasses", "neck": "bell_collar"}, "Reused game scene equips the selected Adventure campaign outfit")
    GameManager.start_blitz_session(3)
    await _frames()
    check(game.math_cat.equipped_accessories.is_empty(), "Switching a reused game scene to Blitz removes Adventure equipment")
    game.queue_free()
    await _frames()

func _test_new_cosmetics(hub: Control, campaign: String) -> void:
    ProfileManager.data.adventure[campaign].currency = 425
    hub.show_shop()
    check(hub.buttons.size() == 10, "Seven cosmetics, Remove All, action and map are focusable")
    check(hub.shop_cat.position.y - 40 * hub.shop_cat.scale.y >= 178 and hub.shop_cat.position.y + 32 * hub.shop_cat.scale.y < hub.shop_preview_label.position.y, "Tallest accessory preview fits below the dressing-room heading and above its caption")
    check(hub.shop_item_buttons.size() == 7 and hub.shop_remove_all.position.y > hub.buttons[6].get_rect().end.y, "Remove All is separate from merchandise in the footer")
    check(hub.shop_wallet.text == "425", "Coin wallet displays the active campaign balance")
    check(hub.shop_slot_labels.keys() == ["head", "face", "neck"], "Preview shows three labeled equipment slots")
    for item in hub.shop_item_buttons:
        var button: Button = hub.shop_item_buttons[item]
        check(button.text == GameManager.AdventureCatalog.ACCESSORIES[item].name and not button.text.contains("|"), "Inventory uses item names without text separators")
        check(button.get_node("ItemIcon").icon_item == item and button.get_node("ItemState").horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "Rows reuse accessory art and right-align price or ownership")
        check(button.get_node("ItemState").mouse_filter == Control.MOUSE_FILTER_IGNORE, "State labels cannot intercept mouse clicks")
        check(button.get_theme_stylebox("normal") is StyleBoxTexture, "Shop rows use pixel-art nine-slice frames")
    var right := InputEventKey.new()
    right.keycode = KEY_RIGHT
    right.pressed = true
    hub.buttons[0].grab_focus()
    for index in range(1, 7):
        hub._input(right)
        check(hub.buttons[index].has_focus(), "Keyboard reaches every catalog row")
        check(hub.buttons[index - 1].get_rect().end.y <= hub.buttons[index].position.y and hub.buttons[index].get_rect().end.y < hub.shop_status.position.y, "Expanded catalog rows fit without overlapping each other or status")
    for index in range(7, 10):
        hub._input(right)
        check(hub.buttons[index].has_focus(), "Keyboard reaches purchase, Remove All and World Map footer actions")
    hub._input(right)
    check(hub.buttons[0].has_focus(), "Footer navigation wraps back to the first accessory")
    var expected_outfit := {"head": "crown", "neck": "bandana"}
    var expected_coins := 425
    for item in ["top_hat", "flower", "sunglasses", "bell_collar"]:
        var before := ProfileManager.adventure_progress(campaign)
        hub.shop_item_buttons[item].grab_focus()
        var config: Dictionary = GameManager.AdventureCatalog.ACCESSORIES[item]
        expected_outfit[config.slot] = item
        check(hub.shop_cat.equipped_accessories == expected_outfit and ProfileManager.adventure_progress(campaign) == before, "New item preview preserves other slots without saving")
        _check_shop_slots(hub, expected_outfit)
        hub.shop_item_buttons[item].pressed.emit()
        hub.shop_action.pressed.emit()
        expected_coins -= int(config.price)
        check(ProfileManager.adventure_progress(campaign).currency == expected_coins and hub.shop_cat.equipped_accessories == expected_outfit, "New cosmetic purchase deducts the exact price and equips")
        check(hub.shop_wallet.text == str(expected_coins) and hub.shop_item_buttons[item].get_node("ItemState").text == "EQUIPPED", "Purchase updates the wallet and aligned row state")
        _check_shop_slots(hub, expected_outfit)
        await _capture("shop-%s-%s" % [campaign, item])
    check(expected_coins == 0 and ProfileManager.adventure_progress(campaign).owned_accessories.size() == 7, "Four additions cost 425 coins and all seven items are owned")
    hub.shop_item_buttons["top_hat"].grab_focus()
    hub.shop_item_buttons["top_hat"].pressed.emit()
    hub.shop_action.pressed.emit()
    var outfit := {"head": "top_hat", "face": "sunglasses", "neck": "bell_collar"}
    ProfileManager.data = ProfileManager._load_data()
    hub.show_shop()
    check(hub.shop_cat.equipped_accessories == outfit and ProfileManager.adventure_progress(campaign).equipped_accessories == outfit, "Three-slot outfit persists across a fresh profile load")
    _check_shop_slots(hub, outfit)
    await _capture("shop-%s-full-outfit" % campaign)
    if campaign == "elementary":
        var balance: int = ProfileManager.data.adventure[campaign].currency
        ProfileManager.data.adventure[campaign].currency = 1000000000
        hub.show_shop()
        check(hub.shop_wallet.get_theme_font("font").get_string_size(hub.shop_wallet.text, HORIZONTAL_ALIGNMENT_LEFT, -1, hub.shop_wallet.get_theme_font_size("font_size")).x <= hub.shop_wallet.size.x, "Maximum saved coin balance fits the wallet")
        var original_size := hub.size
        hub.size = Vector2(960, 540)
        await _frames()
        check(hub.canvas.scale == Vector2(0.75, 0.75) and Rect2(Vector2.ZERO, hub.size).encloses(hub.canvas.get_global_transform() * Rect2(Vector2.ZERO, Vector2(1280, 720))), "Shop remains within the viewport at a smaller window size")
        hub.size = original_size
        ProfileManager.data.adventure[campaign].currency = balance
        hub.show_shop()

func _check_shop_slots(hub: Control, outfit: Dictionary) -> void:
    for slot in ["head", "face", "neck"]:
        var item: String = outfit.get(slot, "")
        var expected_name: String = GameManager.AdventureCatalog.ACCESSORIES[item].name if not item.is_empty() else "EMPTY"
        check(hub.shop_slot_labels[slot].text == expected_name and hub.shop_slot_icons[slot].icon_item == item, "Equipment slot labels and icons reflect the displayed outfit")

func _check_stage_gradient(hub: Control) -> void:
    const EXPECTED_BORDERS := ["59f7ff", "64dfff", "83bcff", "7fffd4", "efff7f", "ffd76a", "ff9cda", "ffb3a3", "ffbc87"]
    for index in hub.level_buttons.size():
        var button: Button = hub.level_buttons[index]
        var expected := Color(EXPECTED_BORDERS[index])
        check(GameManager.AdventureCatalog.level(GameManager.adventure_campaign, index + 1).highlight_color == expected, "Stage record owns the map highlight color")
        for state in ["normal", "disabled", "focus", "hover", "pressed", "hover_pressed"]:
            var style := button.get_theme_stylebox(state) as StyleBoxFlat
            check(style.bg_color == Color("203b3a"), "Stage fills stay dark teal in " + state)
            var expected_border := expected.darkened(0.25) if state == "disabled" else expected
            check(style.border_color.is_equal_approx(expected_border), "Stage %d preserves its neon border in %s" % [index + 1, state])
            var expected_width := 4 if state in ["normal", "disabled"] else 7
            check(style.border_width_left == expected_width and style.border_width_top == expected_width and style.border_width_right == expected_width and style.border_width_bottom == expected_width, "Interaction thickens the stage border without replacing its color")
            check(style.shadow_size == (0 if state == "disabled" else 4 if state == "normal" else 7), "Unlocked borders glow and selection strengthens the glow")
        for state in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
            check(button.get_theme_color(state) == Color.WHITE, "Stage labels stay white in " + state)
        var fill: Color = button.get_theme_stylebox("normal").bg_color
        var luminance := fill.srgb_to_linear().get_luminance()
        check(1.05 / (luminance + 0.05) >= 4.5, "White stage text retains at least 4.5:1 contrast")
        check((expected.srgb_to_linear().get_luminance() + 0.05) / (luminance + 0.05) >= 4.5, "Neon border contrasts at least 4.5:1 against the stage fill")
        check(expected.s >= 0.35, "Intermediate borders stay saturated rather than muddy")
        for background in [Color("100c29"), Color("211638"), Color("201638"), Color("54317d"), Color("633277")]:
            var contrast: float = (expected.srgb_to_linear().get_luminance() + 0.05) / (background.srgb_to_linear().get_luminance() + 0.05)
            check(contrast >= 4.5, "Every unlocked stage border contrasts at least 4.5:1 against the purple sky, buildings, grid, and roof trim")
        if index in [6, 7]:
            var previous_color := Color("ff8dae") if index == 6 else Color("ffa58f")
            check(expected.srgb_to_linear().get_luminance() >= previous_color.srgb_to_linear().get_luminance() * 1.1, "Stage 7 and 8 borders are at least 10% brighter than the previous palette")

func _test_gameplay() -> void:
    for campaign in GameManager.AdventureCatalog.CAMPAIGNS:
        GameManager.start_adventure_level(campaign, 2)
        var game = preload("res://scenes/game/game.tscn").instantiate()
        add_child(game)
        game.adventure.auto_return = false
        await _frames()
        check(game.math_cat.equipped_accessories == {"head": "top_hat", "face": "sunglasses", "neck": "bell_collar"}, "All three accessory slots appear in Adventure gameplay")
        check(not game.answer_locked and GameManager.adventure_question_open, "Question input arms after layout")
        check(game.timer_label.visible and game.timer_label.text == "TIME %.1f" % GameManager.adventure_config.timer_seconds, "Timer uses the Retro TIME label with seconds and tenths")
        check(game.timer_label.horizontal_alignment == game._solo_timer_alignment and Vector4(game.timer_label.offset_left, game.timer_label.offset_top, game.timer_label.offset_right, game.timer_label.offset_bottom) == game._solo_timer_offsets, "Timed Adventure levels retain Retro timer positioning")
        check(not game.adventure.banner.visible, "Level location is not shown in gameplay")
        var storage_path := ProfileManager.storage_path
        ProfileManager.storage_path = "user://missing-adventure-ui-folder/profile.json"
        ProfileManager.save()
        game.adventure.refresh_hud()
        check(game.adventure.banner.visible and game.adventure.banner.text == "SAVE PENDING: CHECK STORAGE", "Removing the location banner preserves save-error warnings")
        ProfileManager.storage_path = storage_path
        ProfileManager.save()
        game.adventure.refresh_hud()
        check(not game.adventure.banner.visible, "Successful save clears the gameplay warning without showing a location")
        await _capture("level-" + campaign)
        now += 160
        GameManager.sync_adventure_clock()
        check(game.timer_label.text == "TIME %.1f" % (float(GameManager.adventure_config.timer_seconds) - 0.1), "Timer displays TIME with tenths")
        game._pause_game()
        check(not game.timer_label.visible and not game.adventure.banner.visible, "Pause hides the question timer and level location")
        await _capture("paused-" + campaign)
        game._open_pause_options()
        game.adventure.refresh_hud()
        check(not game.timer_label.visible and not game.adventure.banner.visible, "Options and HUD refresh cannot reveal paused labels")
        await _capture("paused-options-" + campaign)
        ProfileManager.set_cat_color("Blue")
        check(game.math_cat.modulate == ProfileManager.cat_modulate(), "Saved cat color applies in Adventure options")
        game._close_pause_options()
        ProfileManager.set_cat_color("Orange")
        var paused_text: String = game.timer_label.text
        now += 5000
        GameManager.sync_adventure_clock()
        check(game.timer_label.text == paused_text, "Pause freezes visible countdown")
        game._resume_game()
        await _frames()
        check(game.timer_label.visible and not game.adventure.banner.visible, "Resume restores the question timer without the level location")
        check(game.timer_label.text == paused_text, "Restoring the timer label preserves its remaining time")
        check(game.math_cat.current_stage == GameManager.adventure_config.character, "Campaign character applied")
        _check_background(game, int(GameManager.adventure_config.grade))
        check(not game.correct_pips[0].is_visible_in_tree(), "Fixed grade hides progression meters")
        var question_id: int = game.adventure.question_id
        GameManager._adventure_deadline = int(GameManager.clock_msec.call())
        GameManager.sync_adventure_clock()
        check(GameManager.lives == 8 and game.adventure.question_id > question_id, "Timeout immediately replaces question and costs one life")
        check(game.feedback_label.modulate == game.INCORRECT_PIP_COLOR, "Timeout feedback is red")
        await _frames()
        check(not game.answer_locked, "Replacement question becomes ready")
        check(game.feedback_label.text.is_empty(), "Replacement question clears timeout feedback")
        game._select_answer(game.current_question.choices.find(game.current_question.correct_answer))
        check(game.feedback_label.text == "Correct!" and game.feedback_label.modulate == game.CORRECT_PIP_COLOR, "Correct feedback is green after a timeout")
        await _capture("correct-feedback-" + campaign)
        game._pause_game()
        await get_tree().create_timer(0.8).timeout
        await _frames()
        check(not game.timer_label.visible and not game.adventure.banner.visible, "Feedback completion while paused keeps labels hidden")
        game._resume_game()
        await _frames()
        game._select_answer((game.current_question.choices.find(game.current_question.correct_answer) + 1) % 4)
        check(game.feedback_label.text == "Not quite." and game.feedback_label.modulate == game.INCORRECT_PIP_COLOR, "Incorrect feedback returns to red after a correct answer")
        await _capture("incorrect-feedback-" + campaign)
        game._pause_game()
        game._resume_game()
        check(game.answer_locked, "Pause and resume cannot bypass answer feedback")
        await get_tree().create_timer(0.8).timeout
        await _frames()
        check(not game.answer_locked, "Feedback finishes with a fresh question")
        GameManager.adventure_config.correct_target = 1
        var original_path := ProfileManager.storage_path
        if campaign == "elementary":
            ProfileManager.storage_path = "user://missing-adventure-ui-folder/profile.json"
        game._select_answer(game.current_question.choices.find(game.current_question.correct_answer))
        check(GameManager.current_state == GameManager.GameState.LEVEL_COMPLETE and game.adventure.finished, "Completion stops gameplay and shows rewards")
        check(game.adventure.overlay != null and game.answer_buttons[0].disabled, "Reward overlay locks answers")
        if campaign == "elementary":
            var paid: int = ProfileManager.adventure_progress(campaign).currency
            var pending_transition: Dictionary = GameManager.adventure_map_transition.duplicate()
            check(not ProfileManager.last_save_error.is_empty() and game.adventure.actions[1].disabled, "Save failure prevents leaving an unsaved reward")
            ProfileManager.storage_path = original_path
            game.adventure._primary_action()
            check(ProfileManager.last_save_error.is_empty() and ProfileManager.adventure_progress(campaign).currency == paid, "Save retry does not double-pay")
            check(not pending_transition.is_empty() and GameManager.adventure_map_transition == pending_transition, "Save retry preserves the pending unlock animation")
        await _capture("reward-" + campaign)
        check(ProfileManager.adventure_level_unlocked(campaign, 3), "Completion unlocks next map level")
        game._restart_game()
        await _frames()
        check(GameManager.is_adventure_mode() and GameManager.lives == 9 and not game.adventure.finished, "Restart preserves Adventure level")
        var replay_coins: int = ProfileManager.adventure_progress(campaign).currency
        GameManager.adventure_config.correct_target = 1
        game._select_answer(game.current_question.choices.find(game.current_question.correct_answer))
        check(GameManager.current_state == GameManager.GameState.LEVEL_COMPLETE and GameManager.adventure_reward == GameManager.adventure_config.reward, "Successful replay shows the configured reward again")
        check(ProfileManager.adventure_progress(campaign).currency == replay_coins + GameManager.adventure_reward and game.adventure.reward_tween != null and game.adventure.reward_tween.is_running(), "Replay coins are saved and animated like the first clear")
        await _capture("replay-reward-" + campaign)
        GameManager.start_adventure_level(campaign, 1)
        await _frames()
        _check_background(game, int(GameManager.adventure_config.grade))
        check(not game.timer_label.visible, "Untimed level hides question timer")
        game._pause_game()
        check(not game.adventure.banner.visible, "Pause hides the untimed level location")
        game._resume_game()
        await _frames()
        check(not game.adventure.banner.visible and not game.timer_label.visible, "Untimed resume keeps both location and question timer hidden")
        GameManager.lives = 1
        game._select_answer((game.current_question.choices.find(game.current_question.correct_answer) + 1) % 4)
        check(GameManager.current_state == GameManager.GameState.LEVEL_FAILED and game.adventure.overlay != null, "Failure screen replaces gameplay")
        await _capture("failure-" + campaign)
        for level_number in range(3, 9):
            check(GameManager.start_adventure_level(campaign, level_number), "Unlocked level starts for background verification")
            await _frames()
            _check_background(game, int(GameManager.adventure_config.grade))
            ProfileManager.complete_adventure_level(GameManager.AdventureCatalog.level(campaign, level_number), 100, 9)
        GameManager.start_adventure_level(campaign, 9)
        game.adventure.auto_return = true
        await _frames()
        _check_background(game, 12)
        check(AudioManager._current_music_name == AudioManager.MUSIC_NERD_CAT_THEME, "Every Adventure boss uses Grade 13 music")
        check(game.math_cat.current_stage == GameManager.adventure_config.character, "Boss keeps the campaign cat instead of Professor Wiskers")
        check(game.score_label.text == "FINAL BOSS", "Every campaign boss is labeled FINAL BOSS")
        var boss_font_size: int = game.score_label.get_theme_font_size("font_size")
        check(boss_font_size == game.grade_label.get_theme_font_size("font_size") and boss_font_size == game.get_node("Content/Layout/HeaderBar/Margin/Header/LivesLabel").get_theme_font_size("font_size"), "FINAL BOSS font size matches Grade and LIVES")
        check(game.score_label.get_theme_font("font").get_string_size(game.score_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, boss_font_size).x <= game.score_label.size.x, "FINAL BOSS text fits the existing header box")
        check(not game.adventure.banner.visible, "Boss location is not shown in gameplay")
        check(game.timer_label.visible and game.timer_label.text == "TIME 02:00", "Boss shows Retro's two-minute session clock")
        game._pause_game()
        var boss_paused_time := GameManager.time_left
        GameManager._process(30.0)
        game.adventure.refresh_hud()
        check(GameManager.time_left == boss_paused_time and not game.timer_label.visible and not game.adventure.banner.visible, "Boss pause freezes time and hides the clock and location")
        game._resume_game()
        await _frames()
        check(game.timer_label.visible, "Boss resume restores the session clock")
        var start_grade: int = ProgressionManager.current_grade
        for answer in 4:
            game._select_answer(game.current_question.choices.find(game.current_question.correct_answer))
            await get_tree().create_timer(0.85).timeout
            await _frames()
        var before_promotion := GameManager.time_left
        var promotion_question: int = game.adventure.question_id
        var correct_index: int = game.current_question.choices.find(game.current_question.correct_answer)
        game._select_answer(correct_index)
        check(GameManager.current_state == GameManager.GameState.LEVEL_UP and ProgressionManager.current_grade == start_grade + 1, "Five correct boss answers enter the shared level-up state")
        check(GameManager.time_left == before_promotion + start_grade * 10 and game.time_bonus_label.text == "+%d Seconds!" % (start_grade * 10), "Boss promotion shows Retro's grade time bonus")
        check(game.feedback_label.text == "Level Up! Grade %d" % (start_grade + 1) and game.feedback_label.modulate == game.CORRECT_PIP_COLOR, "Boss promotion shows green Level Up text with a capital U")
        check(game.answer_buttons[correct_index].get_theme_stylebox("disabled") == game.promotion_answer_style, "Boss promotion uses Retro's blue answer highlight")
        check(game.math_cat.animation == MathCat.ANIM_LEVEL_UP and game.math_cat._level_up_plays_remaining == 2, "Normal happy feedback cannot interrupt the two-cycle level-up celebration")
        check(game.math_cat.current_stage == GameManager.adventure_config.character, "Level-up celebration retains the campaign sprite")
        for pip in game.correct_pips:
            check(pip.get("filled"), "All five correct pips remain filled during the promotion flash")
        var celebration_time := GameManager.time_left
        await _capture("boss-level-up-" + campaign)
        await get_tree().create_timer(1.0).timeout
        check(GameManager.time_left == celebration_time and game.answer_locked and game.adventure.question_id == promotion_question, "Boss level-up holds feedback beyond a normal answer and freezes the clock")
        await get_tree().create_timer(1.1).timeout
        await _frames()
        check(GameManager.current_state == GameManager.GameState.PLAYING and not game.answer_locked and game.adventure.question_id > promotion_question, "Boss resumes with a new ready question after the full Retro celebration")
        for mistake in 3:
            game._select_answer((game.current_question.choices.find(game.current_question.correct_answer) + 1) % 4)
            if mistake < 2:
                await get_tree().create_timer(0.85).timeout
                await _frames()
        check(GameManager.current_state == GameManager.GameState.DEMOTION and game.feedback_label.modulate == game.INCORRECT_PIP_COLOR, "Boss demotion retains red incorrect feedback")
        await get_tree().create_timer(2.1).timeout
        await _frames()
        check(GameManager.current_state == GameManager.GameState.PLAYING and not game.answer_locked, "Boss demotion returns to a playable question")
        _check_background(game, 12)
        check(AudioManager._current_music_name == AudioManager.MUSIC_NERD_CAT_THEME, "Boss music stays Grade 13 through progression")
        game._restart_game()
        await _frames()
        _check_background(game, 12)
        check(game.timer_label.text == "TIME 02:00", "Boss restart restores the two-minute display")
        check(AudioManager._current_music_name == AudioManager.MUSIC_NERD_CAT_THEME and game.math_cat.current_stage == GameManager.adventure_config.character, "Boss restart preserves Grade 13 music and the campaign cat")
        ProfileManager.set_animated_background(false)
        check(game.get_node("Background").material == null, "Adventure respects the disabled animated-background option")
        ProfileManager.set_animated_background(true)
        _check_background(game, 12)
        check(game.correct_pips[0].is_visible_in_tree() and game.timer_label.visible, "Boss shows progression meters alongside its session clock")
        await _capture("boss-playing-" + campaign)
        GameManager.time_left = 0.01
        GameManager._process(0.1)
        check(GameManager.current_state == GameManager.GameState.LEVEL_FAILED and game.adventure.overlay.get_node("ResultHeading").text == "TIME'S UP!", "Boss timer expiry shows a time-up failure, not an out-of-lives message")
        check(GameManager.lives == 9 and game.answer_locked, "Boss time-up locks input without losing a life")
        await _capture("boss-time-up-" + campaign)
        game._restart_game()
        await _frames()
        ProgressionManager.current_grade = int(GameManager.adventure_config.boss_victory_grade) - 1
        ProgressionManager.correct_count = ProgressionManager.PROMOTE_THRESHOLD - 1
        var victory_time := GameManager.time_left
        if campaign == "elementary":
            ProfileManager.storage_path = "user://missing-adventure-ui-folder/profile.json"
        var final_answer: int = game.current_question.choices.find(game.current_question.correct_answer)
        game._select_answer(final_answer)
        check(GameManager.current_state == GameManager.GameState.CAMPAIGN_COMPLETE, "Boss promotion opens campaign victory")
        check(GameManager.time_left == victory_time, "Final promotion wins without adding another time bonus")
        _check_background(game, 12)
        check(game.math_cat.current_stage == GameManager.adventure_config.character, "Boss victory never evolves campaign character")
        check(not game.game_over_overlay.visible, "Boss victory cannot open Retro results")
        check(game.adventure.overlay == null and game.question_label.is_visible_in_tree() and game.math_cat.visible, "Final answer and cat remain visible before the victory screen")
        check(game.answer_buttons[final_answer].get_theme_stylebox("disabled") == game.correct_answer_style, "Final correct answer remains highlighted during victory delay")
        check(game.feedback_label.text == "VICTORY!" and game.feedback_label.modulate == game.CORRECT_PIP_COLOR, "Final-answer victory feedback is green")
        check(game.math_cat.animation == MathCat.ANIM_EVOLUTION_POSE and game.math_cat.is_playing(), "Boss final answer shows the campaign cat's evolution animation")
        var confirm := InputEventKey.new()
        confirm.keycode = KEY_ENTER
        confirm.pressed = true
        game.adventure.handle_input(confirm)
        game.adventure._finished(true)
        await _capture("boss-final-answer-" + campaign)
        await get_tree().create_timer(0.4).timeout
        check(game.adventure.overlay == null and game.answer_locked and GameManager.time_left == victory_time, "Victory reveal waits a full second with input locked and time frozen")
        await get_tree().create_timer(0.7).timeout
        await _frames()
        check(game.adventure.overlay.get_node("ResultHeading").text == "VICTORY!", "Boss has a dedicated VICTORY screen")
        check(game.adventure.overlay.get_node("ResultHeading").get_theme_color("font_color") == game.CORRECT_PIP_COLOR, "Victory screen heading is green")
        check(not game.question_label.is_visible_in_tree() and not game.answer_buttons[0].is_visible_in_tree() and not game.math_cat.visible, "Victory hides the old gameplay so questions, answers, and duplicate cats cannot show through")
        var victory_cat: MathCat = game.adventure.overlay.get_node("ResultCat")
        check(victory_cat.equipped_accessories == {"head": "top_hat", "face": "sunglasses", "neck": "bell_collar"}, "All three accessory slots appear in boss victory results")
        check(victory_cat.current_stage == GameManager.adventure_config.character and victory_cat.animation == MathCat.ANIM_HIGH_SCORE, "Victory celebrates with the existing campaign cat")
        check(AudioManager._current_music_name == AudioManager.MUSIC_VICTORY_THEME, "Boss completion plays victory music")
        var victory_overlay: Control = game.adventure.overlay
        game.adventure._finished(true)
        check(game.adventure.overlay == victory_overlay, "Duplicate completion cannot recreate the victory screen or restart its music")
        if campaign == "elementary":
            var paid: int = ProfileManager.adventure_progress(campaign).currency
            ProfileManager.storage_path = original_path
            game.adventure._primary_action()
            check(ProfileManager.last_save_error.is_empty() and ProfileManager.adventure_progress(campaign).currency == paid, "Victory save retry preserves the single boss reward")
        var victory_player := AudioManager._music_player
        check(victory_player.playing and victory_player.stream.resource_path == AudioManager.MUSIC_TRACKS[AudioManager.MUSIC_VICTORY_THEME], "Victory track is actively playing")
        check(not victory_player.stream.loop, "Victory music plays once without looping")
        await _capture("boss-" + campaign)
        await get_tree().create_timer(2.0).timeout
        check(GameManager.current_state == GameManager.GameState.CAMPAIGN_COMPLETE and game.adventure.overlay == victory_overlay, "Victory remains open so automatic map return cannot cut off its music")
        check(not game.adventure.actions[1].disabled and game.adventure.actions[1].has_focus(), "Victory enables a focused World Map action after saving the reward")
        await _capture("boss-victory-ready-" + campaign)
        victory_player.seek(victory_player.stream.get_length() - 0.1)
        var playback_deadline := Time.get_ticks_msec() + 2000
        while victory_player.playing and Time.get_ticks_msec() < playback_deadline:
            await get_tree().process_frame
        game.adventure._finished(true)
        check(not victory_player.playing and AudioManager._music_player == victory_player, "Victory music stays stopped after its single playback, including repeated finish notifications")
        game._restart_game()
        await _frames()
        check(game.question_label.is_visible_in_tree() and game.answer_buttons[0].is_visible_in_tree() and game.math_cat.visible and not game.answer_locked, "A new boss attempt restores gameplay hidden by victory")
        ProgressionManager.current_grade = int(GameManager.adventure_config.boss_victory_grade) - 1
        ProgressionManager.correct_count = ProgressionManager.PROMOTE_THRESHOLD - 1
        var boss_replay_coins: int = ProfileManager.adventure_progress(campaign).currency
        game._select_answer(game.current_question.choices.find(game.current_question.correct_answer))
        check(GameManager.adventure_reward == GameManager.adventure_config.reward and ProfileManager.adventure_progress(campaign).currency == boss_replay_coins + GameManager.adventure_reward, "Boss replay earns another reward before its delayed victory reveal")
        game._restart_game()
        await get_tree().create_timer(1.1).timeout
        await _frames()
        check(game.adventure.overlay == null and not game.adventure.finished and not game.answer_locked, "Restart cancels the pending victory reveal without hiding the new attempt")
        game.queue_free()
        await _frames()
    AudioManager.stop_music()

func _check_background(game: Control, grade: int) -> void:
    var backdrop := game.get_node_or_null("AdventureStageBackground") as Control
    if not GameManager.is_adventure_boss():
        check(backdrop != null and backdrop.visible, "Stages 1-8 show authored Adventure scenery")
        if backdrop != null:
            check(backdrop.get("level_number") == int(GameManager.adventure_config.number), "Background identity follows the map stage")
            check(backdrop.get("accent").is_equal_approx(GameManager.adventure_config.highlight_color), "Background accent matches the map border")
        check(not game.get_node("Background").visible, "Authored scenery replaces the visible Retro grid")
        check(not game.get_node("Grade13Equations").visible, "Standard stages do not show Grade 13 equations")
        return
    check(backdrop == null or not backdrop.visible, "Boss does not show stage scenery")
    check(game.get_node("Background").visible, "Boss retains the original visible background")
    var material := game.get_node("Background").material as ShaderMaterial
    check(material != null, "Adventure uses the shared animated background")
    if material == null:
        return
    var evolution: BackgroundEvolutionManager = game.get_node("BackgroundEvolutionManager")
    check(material.shader == preload("res://shaders/synthwave_background.gdshader"), "Adventure uses Retro's 80s grid shader")
    check(material.get_shader_parameter("grade") == float(grade), "Adventure background matches the associated Retro grade")
    check(material.get_shader_parameter("stage") == float(evolution.visual_stage_for_grade(grade)), "Adventure background uses the associated Retro visual stage")
    check(material.get_shader_parameter("shooting_star_intensity") == evolution.shooting_star_intensity_for_grade(grade), "Adventure atmosphere matches Retro")
    check(material.get_shader_parameter("star_density") == evolution.star_density_for_grade(grade), "Adventure background matches Retro star density")
    var uses_stage_color := not GameManager.is_adventure_boss()
    check(material.get_shader_parameter("grid_color_override_enabled") == uses_stage_color, "Only non-boss Adventure stages override the Retro grid color")
    if uses_stage_color:
        check(material.get_shader_parameter("grid_color_override").is_equal_approx(GameManager.adventure_config.highlight_color), "Adventure grid matches the stage rectangle highlight")
    check(game.get_node("Grade13Equations").visible == (grade == 13), "Grade 13 equations are hidden on the Grade 12 boss background")

func _test_scene_navigation() -> void:
    get_tree().current_scene = null
    ProfileManager.data.adventure.elementary = GameManager.AdventureCatalog.default_progress()
    GameManager.goto_scene("res://scenes/title/title.tscn")
    await _frames()
    get_tree().current_scene._activate_main_option(2)
    await _frames()
    check(GameManager.current_state == GameManager.GameState.CAMPAIGN_SELECT, "Title opens campaign selection")
    get_tree().current_scene.buttons[0].pressed.emit()
    check(GameManager.current_state == GameManager.GameState.WORLD_MAP, "Campaign button opens its map")
    get_tree().current_scene.level_buttons[0].pressed.emit()
    await _frames()
    var game = get_tree().current_scene
    check(GameManager.adventure_config.number == 1 and GameManager.adventure_question_open, "Map button opens a ready level")
    var previous_question := ""
    for answer in 10:
        check(game.current_question.question_text != previous_question, "Shared question bank avoids consecutive duplicates")
        previous_question = game.current_question.question_text
        game._select_answer(game.current_question.choices.find(game.current_question.correct_answer))
        if answer < 9:
            check(GameManager.current_state == GameManager.GameState.PLAYING, "Default target does not complete early")
            await get_tree().create_timer(0.8).timeout
            await _frames()
    check(GameManager.current_state == GameManager.GameState.LEVEL_COMPLETE, "Default ten correct answers complete the level")
    await get_tree().create_timer(2.0).timeout
    await _frames()
    check(GameManager.current_state == GameManager.GameState.WORLD_MAP, "Payment automatically returns to the world map")
    check(get_tree().current_scene.level_buttons[1].has_focus(), "Next unlocked level owns focus after payment")
    var hub = get_tree().current_scene
    check(hub.map_cat_tween != null and hub.map_cat.position != hub.MAP_POINTS[1] + Vector2(0, -66), "Real results-to-map scene change animates instead of teleporting to the unlock")
    await get_tree().create_timer(1.2).timeout
    check(hub.map_cat_tween == null and hub.map_cat.position == hub.MAP_POINTS[1] + Vector2(0, -66), "Live map tween reaches the unlocked level")
    get_tree().current_scene.level_buttons[1].pressed.emit()
    await _frames()
    game = get_tree().current_scene
    game._pause_game()
    var completed: Array = ProfileManager.adventure_progress("elementary").completed_levels
    game.pause_buttons[3].pressed.emit()
    await _frames()
    check(GameManager.current_state == GameManager.GameState.WORLD_MAP, "Pause menu returns to map")
    check(get_tree().current_scene.map_cat_tween == null, "Pause-to-map does not replay the previous clear")
    check(ProfileManager.adventure_progress("elementary").completed_levels == completed, "Leaving an incomplete level cannot unlock it")
    get_tree().current_scene.buttons.back().pressed.emit()
    get_tree().current_scene.buttons.back().pressed.emit()
    await _frames()
    check(get_tree().current_scene.scene_file_path == "res://scenes/title/title.tscn", "Back through campaigns returns to title")
    get_tree().current_scene.queue_free()
    get_tree().current_scene = null
    await _frames()

func _capture(label: String) -> void:
    if "--capture" not in OS.get_cmdline_user_args():
        return
    await _frames()
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    var path := "user://adventure-%s.png" % label
    check(image.save_png(path) == OK, "Capture " + label)
    print("CAPTURE " + ProjectSettings.globalize_path(path))