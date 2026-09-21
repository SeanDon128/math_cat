extends Node

const State = preload("res://scripts/debug/debug_state.gd")
var failures: Array[String] = []
var now := 10000

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func frames() -> void:
    for index in 5:
        await get_tree().process_frame

func button(parent: Node, text: String) -> Button:
    for child in parent.get_children():
        if child is Button and child.text == text:
            return child
        var found := button(child, text)
        if found != null:
            return found
    return null

func key(code: Key, pressed: bool = true, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = pressed
    event.echo = echo
    Input.parse_input_event(event)

func number_field(parent: Node, text: String) -> SpinBox:
    for child in parent.get_children():
        if child is HBoxContainer and child.get_child_count() >= 2 and child.get_child(0) is Label and child.get_child(0).text == text:
            return child.get_child(1) as SpinBox
        var found := number_field(child, text)
        if found != null:
            return found
    return null

func _ready() -> void:
    get_tree().create_timer(60).timeout.connect(func():
        push_error("Debug menu smoke test timed out.")
        get_tree().quit(1))
    ProfileManager.storage_path = "user://debug-profile.json"
    ProfileManager.data = ProfileManager._default_data()
    BlitzLeaderboard.storage_path = "user://debug-solo.json"
    BlitzDuelLeaderboard.storage_path = "user://debug-duel.json"
    check(BlitzLeaderboard.replace_for_debugging(BlitzLeaderboard._empty_boards()), "Initialize solo fixture")
    check(BlitzDuelLeaderboard.replace_for_debugging(BlitzDuelLeaderboard._empty_boards()), "Initialize duel fixture")
    GameManager.clock_msec = func(): return now
    var main := preload("res://scripts/main.gd").new()
    main._configure_input_map()
    main.free()
    get_tree().current_scene = null
    var title := preload("res://scenes/title/title.tscn").instantiate()
    get_tree().root.add_child.call_deferred(title)
    await frames()
    get_tree().current_scene = title
    title._open_options()
    key(KEY_ASCIITILDE)
    await frames()
    check(DebugMenu.opened and get_tree().paused, "Tilde opens over title submenus and pauses the tree")
    check(DebugMenu.tabs.get_tab_count() == 8, "Every state category is available")
    number_field(DebugMenu.panel, "Highest Score").value = 555
    check(DebugMenu.draft.records.highest_score == 555 and DebugMenu.draft.records.best_correct_streak == 0, "Numeric controls edit only their bound field")
    number_field(DebugMenu.panel, "Highest Score").value = 0
    key(KEY_QUOTELEFT, true, true)
    check(DebugMenu.opened, "Key repeat cannot close the menu")
    key(KEY_A)
    check(title.active_view == "OPTIONS", "Typing cannot navigate the underlying menu")
    await capture("debug-menu-records")
    var saved_draft := DebugMenu.draft
    saved_draft.records.highest_score = 1234
    saved_draft.lifetime.correct_by_grade[12] = 30
    saved_draft.settings.cat_color = "Blue"
    saved_draft.settings.music_volume = 3
    saved_draft.settings.fullscreen = true
    saved_draft.achievements.unlocked[AchievementManager.VICTORY] = "2026-09-16T12:00:00"
    saved_draft.adventure.elementary.completed_levels = range(1, 10)
    saved_draft.adventure = ProfileManager.AdventureCatalog.normalize(saved_draft.adventure)
    saved_draft.adventure.elementary.currency = 999
    button(DebugMenu.panel, "Apply profile edits (all profile tabs)").pressed.emit()
    check(DebugMenu.confirmation.visible and ProfileManager.data.records.highest_score == 0, "Saving is confirmation-gated")
    DebugMenu.confirmation.confirmed.emit()
    DebugMenu.confirmation.hide()
    check(ProfileManager.data.records.highest_score == 1234 and GameManager.best_score == 1234, "Saving updates persistent and cached records")
    check(AchievementManager.is_unlocked(AchievementManager.VICTORY), "Achievement can be granted")
    check(ProfileManager.cat_color_name() == "Blue" and ProfileManager.fullscreen_enabled(), "Cosmetic and fullscreen settings can be set")
    check(ProfileManager.adventure_level_unlocked("elementary", 9), "Campaign completion unlocks boss")
    check(JSON.parse_string(JSON.stringify(ProfileManager._load_data())) == JSON.parse_string(JSON.stringify(ProfileManager.data)), "All profile edits survive reload")
    DebugMenu.draft.achievements.unlocked.clear()
    check(State.save_profile(DebugMenu.draft).is_empty(), "Achievements can be revoked")
    check(AchievementManager.consume_pending_notifications().is_empty(), "Revoking achievements clears stale notifications")
    var invalid := DebugMenu.draft.duplicate(true)
    invalid.settings.master_volume = 11
    check(not State.save_profile(invalid).is_empty(), "Invalid settings are rejected")
    check(ProfileManager.master_volume() == 10, "Invalid settings do not mutate data")
    var valid_path := ProfileManager.storage_path
    ProfileManager.storage_path = "user://missing-debug-directory/profile.json"
    invalid = DebugMenu.draft.duplicate(true)
    invalid.records.highest_score = 9876
    check(not State.save_profile(invalid).is_empty(), "Profile save failure is explicit")
    check(ProfileManager.data.records.highest_score == 1234, "Failed save rolls memory back")
    ProfileManager.storage_path = valid_path
    DebugMenu.close_menu()
    await frames()
    check(not get_tree().paused and title.active_view == "OPTIONS", "Closing restores title submenu")
    title.free()
    GameManager.open_adventure("elementary")
    var hub := preload("res://scenes/adventure/adventure_hub.tscn").instantiate()
    get_tree().root.add_child(hub)
    get_tree().current_scene = hub
    await frames()
    key(KEY_QUOTELEFT)
    await frames()
    check(DebugMenu.opened, "Backtick opens over the map's consuming input handler")
    DebugMenu.tabs.current_tab = 4
    button(DebugMenu.panel, "Add score").pressed.emit()
    DebugMenu.board_drafts.solo["1"][0].initials = "CAT"
    DebugMenu.board_drafts.solo["1"][0].score = 42
    number_field(DebugMenu.panel, "Completed levels (0 = reset route, 9 = complete)").value = 8
    check(DebugMenu.draft.adventure.elementary.completed_levels.size() == 8 and not DebugMenu.draft.adventure.elementary.campaign_completed, "Adventure completion control updates derived progress")
    number_field(DebugMenu.panel, "Completed levels (0 = reset route, 9 = complete)").value = 9
    check(DebugMenu.board_drafts.solo["1"][0].score == 42, "Rebuilding profile controls preserves leaderboard drafts")
    button(DebugMenu.panel, "Apply this leaderboard (all grades)").pressed.emit()
    DebugMenu.confirmation.confirmed.emit()
    DebugMenu.confirmation.hide()
    check(BlitzLeaderboard.reload() and BlitzLeaderboard.board(1)[0].score == 42, "Edited solo board persists")
    check(BlitzDuelLeaderboard.board(1).is_empty(), "Solo edits cannot affect duel scores")
    var malformed := BlitzLeaderboard._boards.duplicate(true)
    malformed["1"][0].initials = "!"
    check(not BlitzLeaderboard.replace_for_debugging(malformed), "Invalid leaderboard entries are rejected")
    check(BlitzLeaderboard.board(1)[0].score == 42, "Invalid leaderboard leaves prior data intact")
    button(DebugMenu.panel, "Clear solo leaderboards").pressed.emit()
    check(DebugMenu.confirmation.visible, "Leaderboard clearing is confirmation-gated")
    DebugMenu.confirmation.confirmed.emit()
    check(BlitzLeaderboard.reload() and BlitzLeaderboard.board(1).is_empty(), "Leaderboard clearing persists")
    DebugMenu.close_menu()
    await frames()
    check(hub.level_buttons[8].text == "BOSS\nDONE", "Map reflects saved campaign edits")
    hub.free()
    for mode in ["retro", "blitz", "adventure", "duel"]:
        if mode == "retro":
            GameManager.start_session()
        elif mode == "adventure":
            GameManager.start_adventure_level("elementary", 2)
        else:
            GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
            GameManager.start_blitz_session(3, 2 if mode == "duel" else 1)
        var game := preload("res://scenes/game/game.tscn").instantiate()
        get_tree().root.add_child(game)
        get_tree().current_scene = game
        await frames()
        key(KEY_QUOTELEFT)
        await frames()
        check(DebugMenu.opened, "Debug opens during " + mode)
        var previous_time := GameManager.time_left
        var deadline := GameManager._blitz_deadline_msec
        var adventure_deadline := GameManager._adventure_deadline
        var previous_correct := GameManager.total_correct_answers
        now += 5000
        key(KEY_A)
        key(KEY_ENTER)
        await frames()
        check(GameManager.time_left == previous_time, "Clock freezes in " + mode)
        check(GameManager.total_correct_answers == previous_correct, "Debug input never answers a question in " + mode)
        var values := State.session_snapshot()
        values.score = -12 if mode in ["blitz", "duel"] else 789
        values.time_left = 45
        values.lives = 0 if mode in ["blitz", "duel"] else 4
        values.correct_count = 2
        if mode == "adventure":
            values.question_seconds = 8
        if mode == "duel":
            values.players[0].score = 12
            values.players[1].score = -3
        check(State.apply_session(values).is_empty(), "Live values apply in " + mode)
        check(GameManager.score == int(values.score), "Score changed in " + mode)
        check(game.timer_label.text.contains("45") if mode != "adventure" else game.timer_label.text == "TIME 8.0", "Live timer HUD refreshed in " + mode)
        DebugMenu.close_menu()
        check(not get_tree().paused, "Closing restores processing in " + mode)
        if deadline >= 0:
            check(GameManager._blitz_deadline_msec == now + 45000, "Blitz deadline includes the freeze and edited time")
        if adventure_deadline >= 0:
            check(GameManager._adventure_deadline == now + 8000, "Adventure question deadline includes freeze and edited time")
        await frames()
        check(GameManager.current_state == GameManager.GameState.PLAYING, "Session resumes in " + mode)
        if mode == "retro":
            game._pause_game()
            key(KEY_QUOTELEFT)
            await frames()
            DebugMenu.close_menu()
            check(game.pause_overlay.visible and GameManager.current_state == GameManager.GameState.PAUSED, "Existing gameplay pause is preserved")
        game.free()
    # Launch through the real Session button, including from an existing game.
    for mode in [0, 1, 2, 3, 4]:
        DebugMenu.open_menu()
        var page := DebugMenu.tabs.get_node("Session").get_child(0)
        for child in page.get_children():
            if child is OptionButton:
                child.selected = mode
        number_field(page, "Starting grade / Adventure level").value = 2
        button(page, "Start new session").pressed.emit()
        DebugMenu.confirmation.confirmed.emit()
        await frames()
        check(not DebugMenu.opened and get_tree().current_scene.scene_file_path == "res://scenes/game/game.tscn", "Debug session launch loads gameplay for mode %d" % mode)
        check(ProgressionManager.current_grade == (1 if mode == 4 else 2), "Debug launch sets the requested grade or Adventure level")
        check(GameManager.is_two_player_blitz() == (mode == 3), "Debug launch selects correct player count")
        DebugMenu.open_menu()
        button(DebugMenu.panel, "Finish Blitz round now" if mode in [2, 3] else "Complete / win current attempt").pressed.emit()
        DebugMenu.confirmation.confirmed.emit()
        await frames()
        check(GameManager.current_state in [GameManager.GameState.GAME_OVER, GameManager.GameState.LEVEL_COMPLETE], "Debug completion uses the real result transition")
    get_tree().current_scene.free()
    GameManager.abandon_current_session()
    DebugMenu.open_menu()
    button(DebugMenu.panel, "RESET EVERYTHING and return to title").pressed.emit()
    var score_before_reset := int(ProfileManager.data.records.highest_score)
    check(DebugMenu.confirmation.visible and score_before_reset == 1234, "Full reset waits for confirmation")
    DebugMenu.confirmation.hide()
    check(ProfileManager.data.records.highest_score == 1234, "Cancelling reset changes nothing")
    DebugMenu._reset_all()
    await frames()
    check(JSON.parse_string(JSON.stringify(ProfileManager._load_data())) == JSON.parse_string(JSON.stringify(ProfileManager._default_data())), "Full reset restores persistent defaults")
    check(BlitzLeaderboard.reload() and BlitzLeaderboard.board(1).is_empty(), "Full reset clears solo store")
    check(BlitzDuelLeaderboard.reload() and BlitzDuelLeaderboard.board(1).is_empty(), "Full reset clears duel store")
    check(not DebugMenu.opened and not get_tree().paused and GameManager.current_state == GameManager.GameState.TITLE, "Reset returns to a responsive title")
    check(GameManager.score == 0 and GameManager.total_correct_answers == 0 and GameManager.highest_correct_streak == 0 and GameManager.session_mode == GameManager.SessionMode.STANDARD, "Full reset clears transient session state")
    for player in AudioManager._players + AudioManager._music_players:
        player.stop()
        player.stream = null
    await frames()
    print("Debug menu checks: %d failures" % failures.size())
    get_tree().quit(0 if failures.is_empty() else 1)

func capture(label: String) -> void:
    if "--capture" not in OS.get_cmdline_user_args():
        return
    await frames()
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    check(image.save_png("user://%s.png" % label) == OK, "Capture " + label)
