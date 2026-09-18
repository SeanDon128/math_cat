extends CanvasLayer

signal state_edited()

const State = preload("res://scripts/debug/debug_state.gd")
const Store = preload("res://scripts/blitz/blitz_leaderboard_store.gd")

var panel: PanelContainer
var tabs: TabContainer
var status: Label
var confirmation: ConfirmationDialog
var draft: Dictionary = {}
var session_draft: Dictionary = {}
var board_drafts: Dictionary = {}
var opened := false
var edited := false
var _was_paused := false
var _clock: Callable
var _frozen_at := 0
var _focus: Control
var _pending: Callable

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 100
    set_process_input(OS.is_debug_build())

func _input(event: InputEvent) -> void:
    handle_toggle(event)

func handle_toggle(event: InputEvent) -> bool:
    if not OS.is_debug_build() or not event is InputEventKey:
        return false
    var toggle: bool = event.keycode in [KEY_QUOTELEFT, KEY_ASCIITILDE] or event.physical_keycode == KEY_QUOTELEFT
    if not toggle and not (opened and event.keycode == KEY_ESCAPE):
        return false
    get_viewport().set_input_as_handled()
    if event.pressed and not event.echo:
        if opened:
            if confirmation.visible:
                confirmation.hide()
            else:
                request_close()
        elif toggle:
            open_menu()
    return true

func open_menu() -> void:
    if not OS.is_debug_build() or opened:
        return
    _focus = get_viewport().gui_get_focus_owner()
    _was_paused = get_tree().paused
    _clock = GameManager.clock_msec
    _frozen_at = int(_clock.call())
    GameManager.clock_msec = func(): return _frozen_at
    get_tree().paused = true
    opened = true
    edited = false
    draft = ProfileManager.data.duplicate(true)
    session_draft = State.session_snapshot()
    board_drafts = {
        "solo": BlitzLeaderboard._boards.duplicate(true),
        "duel": BlitzDuelLeaderboard._boards.duplicate(true),
    }
    _build()

func request_close() -> void:
    if draft != ProfileManager.data or board_drafts.solo != BlitzLeaderboard._boards or board_drafts.duel != BlitzDuelLeaderboard._boards or session_draft != State.session_snapshot():
        _confirm("Discard unapplied debug edits?", close_menu)
    else:
        close_menu()

func close_menu() -> void:
    if not opened:
        return
    var elapsed := maxi(int(_clock.call()) - _frozen_at, 0)
    GameManager.clock_msec = _clock
    # Absolute deadlines must not count time spent in this developer overlay.
    if GameManager._blitz_deadline_msec >= 0:
        GameManager._blitz_deadline_msec += elapsed
    if GameManager._adventure_deadline >= 0:
        GameManager._adventure_deadline += elapsed
    if GameManager.adventure_question_open:
        GameManager._adventure_started += elapsed
        if GameManager.current_state == GameManager.GameState.PAUSED:
            GameManager._adventure_paused_at += elapsed
    var game := get_tree().get_first_node_in_group("debug_gameplay")
    if game != null:
        game.debug_shift_clock(elapsed)
    panel.hide()
    panel.queue_free()
    confirmation.hide()
    confirmation.queue_free()
    opened = false
    GameManager.duel_input._held.clear()
    get_tree().paused = _was_paused
    if edited:
        state_edited.emit()
    if is_instance_valid(_focus) and _focus.is_visible_in_tree():
        _focus.grab_focus()
    _pending = Callable()
    _clock = Callable()

func _build() -> void:
    panel = PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.offset_left = 24
    panel.offset_top = 24
    panel.offset_right = -24
    panel.offset_bottom = -24
    var style := StyleBoxFlat.new()
    style.bg_color = Color("100c29")
    style.border_color = Color("ffe477")
    style.set_border_width_all(3)
    style.set_content_margin_all(18)
    panel.add_theme_stylebox_override("panel", style)
    panel.add_theme_font_size_override("font_size", 18)
    add_child(panel)
    var layout := VBoxContainer.new()
    panel.add_child(layout)
    var heading := HBoxContainer.new()
    layout.add_child(heading)
    var title := _label(heading, "DEBUG MENU - real saved data")
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _button(heading, "Close (~ / Esc)", request_close)
    _label(layout, "Game and timers are frozen. Edits are drafts until applied. Live-session values are not saved.")
    tabs = TabContainer.new()
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(tabs)
    _profile_pages()
    _board_page("Solo scores", BlitzLeaderboard)
    _board_page("Duel scores", BlitzDuelLeaderboard)
    _session_page()
    _reset_page()
    status = _label(layout, "Ready. Use mouse or Tab to edit.")
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    confirmation = ConfirmationDialog.new()
    confirmation.title = "Confirm debug change"
    confirmation.dialog_autowrap = true
    confirmation.confirmed.connect(func():
        if _pending.is_valid():
            var action := _pending
            _pending = Callable()
            action.call())
    add_child(confirmation)
    heading.get_child(1).grab_focus()

func _page(title: String) -> VBoxContainer:
    var scroll := ScrollContainer.new()
    scroll.name = title
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    tabs.add_child(scroll)
    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 8)
    scroll.add_child(box)
    return box

func _label(parent: Node, text: String) -> Label:
    var label := Label.new()
    label.text = text
    parent.add_child(label)
    return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _row(parent: Node, text: String) -> HBoxContainer:
    var row := HBoxContainer.new()
    parent.add_child(row)
    var label := _label(row, text)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return row

func _number(parent: Node, text: String, value: float, changed: Callable, minimum: float = 0, maximum: float = State.LIMIT, step: float = 1) -> SpinBox:
    var row := _row(parent, text)
    var input := SpinBox.new()
    input.min_value = minimum
    input.max_value = maximum
    input.step = step
    input.value = value
    input.custom_minimum_size.x = 200
    input.value_changed.connect(func(number: float):
        changed.call(number))
    row.add_child(input)
    return input

func _choice(parent: Node, text: String, values: Array, selected: String, changed: Callable) -> void:
    var row := _row(parent, text)
    var input := OptionButton.new()
    for value in values:
        input.add_item(str(value))
    input.selected = values.find(selected)
    input.item_selected.connect(func(index: int):
        changed.call(values[index]))
    row.add_child(input)

func _check(parent: Node, text: String, value: bool, changed: Callable) -> void:
    var input := CheckBox.new()
    input.text = text
    input.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    input.tooltip_text = text
    input.button_pressed = value
    input.toggled.connect(func(enabled: bool):
        changed.call(enabled))
    parent.add_child(input)

func _profile_apply(parent: Node) -> void:
    _button(parent, "Apply profile edits (all profile tabs)", func():
        _confirm("Save the edited records, achievements, cosmetics, settings, and Adventure progress?", func():
            var error := State.save_profile(draft)
            _result(error, "Profile saved.")
            if error.is_empty():
                edited = true))

func _profile_pages() -> void:
    var records := _page("Records")
    _profile_apply(records)
    for section in ["records", "lifetime"]:
        _label(records, section.capitalize())
        for key in draft[section]:
            if key == "correct_by_grade":
                for index in 13:
                    _number(records, "Grade %d lifetime correct" % (index + 1), draft.lifetime.correct_by_grade[index], func(value: float): draft.lifetime.correct_by_grade[index] = int(value))
            else:
                _number(records, str(key).capitalize(), draft[section][key], func(value: float): draft[section][key] = int(value), 1 if key == "highest_grade" else 0, 13 if key == "highest_grade" else State.LIMIT)
    var settings := _page("Cosmetics & settings")
    _profile_apply(settings)
    _choice(settings, "Cat color (all existing cosmetics)", ProfileManager.CAT_COLORS.keys(), draft.settings.cat_color, func(value: String): draft.settings.cat_color = value)
    _choice(settings, "Controller input", ["direct", "navigation"], draft.settings.controller_input_style, func(value: String): draft.settings.controller_input_style = value)
    _check(settings, "Animated background", draft.settings.animated_background, func(value: bool): draft.settings.animated_background = value)
    for key in ["master_volume", "music_volume", "sfx_volume", "practice_lives"]:
        _number(settings, str(key).capitalize(), draft.settings[key], func(value: float): draft.settings[key] = int(value), 1 if key == "practice_lives" else 0, 9 if key == "practice_lives" else 10)
    var achievements := _page("Achievements")
    _profile_apply(achievements)
    _button(achievements, "Unlock all achievements (draft)", func():
        for definition in AchievementManager.ACHIEVEMENTS:
            if not draft.achievements.unlocked.has(definition.id):
                draft.achievements.unlocked[definition.id] = Time.get_datetime_string_from_system()
        _rebuild())
    for definition in AchievementManager.ACHIEVEMENTS:
        var id: String = definition.id
        _check(achievements, "%s - %s" % [definition.name, definition.description], draft.achievements.unlocked.has(id), func(enabled: bool):
            if enabled:
                draft.achievements.unlocked[id] = Time.get_datetime_string_from_system()
            else:
                draft.achievements.unlocked.erase(id))
    var adventure := _page("Adventure")
    _profile_apply(adventure)
    _label(adventure, "Completed levels are sequential. Unlocks and campaign completion follow this count.")
    for campaign in ProfileManager.AdventureCatalog.CAMPAIGNS:
        _label(adventure, str(campaign).to_upper())
        var progress: Dictionary = draft.adventure[campaign]
        _number(adventure, "Completed levels (0 = reset route, 9 = complete)", progress.completed_levels.size(), func(value: float):
            progress.completed_levels = range(1, int(value) + 1)
            draft.adventure = ProfileManager.AdventureCatalog.normalize(draft.adventure)
            _rebuild(), 0, 9)
        for key in ["currency", "correct_answers", "best_streak"]:
            _number(adventure, str(key).capitalize(), progress[key], func(value: float): progress[key] = int(value))
        for number in progress.completed_levels:
            var result: Dictionary = progress.level_results.get(str(number), {"best_score": 0, "best_lives": 0, "clears": 1})
            progress.level_results[str(number)] = result
            for key in ["best_score", "best_lives", "clears"]:
                _number(adventure, "Level %d %s" % [number, str(key).capitalize()], result[key], func(value: float): result[key] = int(value), 1 if key == "clears" else 0, 9 if key == "best_lives" else State.LIMIT)

func _board_page(title: String, store: Store) -> void:
    var page := _page(title)
    if not store._loaded:
        _label(page, "Cannot edit unreadable scores: " + store.last_error)
        return
    var boards: Dictionary = board_drafts["solo" if store == BlitzLeaderboard else "duel"]
    var grade := OptionButton.new()
    for number in range(1, 14):
        grade.add_item("Grade %d" % number)
    page.add_child(grade)
    var rows := VBoxContainer.new()
    page.add_child(rows)
    var render := func():
        for child in rows.get_children():
            rows.remove_child(child)
            child.queue_free()
        var entries: Array = boards[str(grade.selected + 1)]
        for index in entries.size():
            var entry: Dictionary = entries[index]
            var row := HBoxContainer.new()
            rows.add_child(row)
            var initials := LineEdit.new()
            initials.text = entry.initials
            initials.max_length = 3
            initials.custom_minimum_size.x = 120
            initials.text_changed.connect(func(value: String):
                entry.initials = value.to_upper())
            row.add_child(initials)
            _number(row, "Score", entry.score, func(value: float): entry.score = int(value), 1, 2147483647)
            _button(row, "Remove", func():
                entries.remove_at(index)
                grade.item_selected.emit(grade.selected))
    grade.item_selected.connect(func(_index: int): render.call())
    _button(page, "Add score", func():
        var entries: Array = boards[str(grade.selected + 1)]
        if entries.size() >= store.BOARD_SIZE:
            _result("Remove an entry first; each grade has at most 10 scores.", "")
            return
        entries.append({"initials": "DBG", "score": 1})
        render.call())
    _button(page, "Apply this leaderboard (all grades)", func():
        _confirm("Replace this leaderboard with the edited entries? Removed scores will be deleted.", func():
            for entries in boards.values():
                # Insertion sort preserves the original order of tied scores.
                for index in range(1, entries.size()):
                    var position := index
                    while position > 0 and int(entries[position].score) > int(entries[position - 1].score):
                        var entry: Dictionary = entries[position]
                        entries[position] = entries[position - 1]
                        entries[position - 1] = entry
                        position -= 1
            var saved := store.replace_for_debugging(boards)
            _result("" if saved else store.last_error, "Leaderboard saved.")
            edited = edited or saved))
    render.call()

func _session_page() -> void:
    var page := _page("Session")
    _label(page, "Mode: %s | State: %s | Grade: %d" % [GameManager.SessionMode.keys()[GameManager.session_mode], GameManager.GameState.keys()[GameManager.current_state], ProgressionManager.current_grade])
    _label(page, "Use Start below to change mode/grade safely. This abandons the current attempt.")
    var mode := OptionButton.new()
    for text in ["Retro", "Practice", "Solo Blitz", "Two-player Blitz", "Elementary Adventure", "Middle Adventure", "High Adventure"]:
        mode.add_item(text)
    page.add_child(mode)
    var start_grade := _number(page, "Starting grade / Adventure level", 1, func(_value: float): pass, 1, 13)
    _button(page, "Start new session", func():
        var selected_mode := mode.selected
        var number := int(start_grade.value)
        if selected_mode >= 4 and number > 9:
            _result("Adventure levels range from 1 to 9.", "")
            return
        if selected_mode >= 4:
            var campaign: String = ["elementary", "middle", "high"][selected_mode - 4]
            if not ProfileManager.adventure_level_unlocked(campaign, number):
                _result("Unlock and apply this level in the Adventure tab first.", "")
                return
        _confirm("Abandon this attempt and start the selected session? Unapplied edits will be discarded.", func():
            _launch_session.call_deferred(selected_mode, number)))
    _button(page, "Abandon session / return to title", func():
        _confirm("Abandon this attempt without recording a result? Unapplied edits will be discarded.", func():
            close_menu()
            GameManager.abandon_current_session()
            GameManager.goto_scene("res://scenes/title/title.tscn")))
    if GameManager.current_state not in [GameManager.GameState.PLAYING, GameManager.GameState.PAUSED]:
        _label(page, "Start a session to edit live values.")
        return
    _button(page, "Finish Blitz round now" if GameManager.is_blitz_mode() else "Complete / win current attempt", func():
        _confirm("Complete this attempt and record its debug-modified result?", func():
            close_menu()
            if GameManager.is_blitz_mode():
                GameManager._blitz_deadline_msec = int(GameManager.clock_msec.call())
                GameManager.sync_blitz_clock()
            elif GameManager.is_adventure_mode():
                GameManager._finish_adventure(true)
            else:
                GameManager.end_session(GameManager.VICTORY_REASON)))
    if not GameManager.is_blitz_mode():
        _button(page, "Fail current attempt", func():
            _confirm("End this attempt with no lives and record its result?", func():
                close_menu()
                GameManager.lives = 0
                GameManager.lives_changed.emit(0)
                GameManager.end_session("out_of_lives")))
    _button(page, "Apply live session values", func():
        _result(State.apply_session(session_draft), "Live session updated."))
    for key in State.SESSION_FIELDS:
        var fractional: bool = key in ["time_left", "time_survived_seconds"]
        var minimum: float = -State.LIMIT if key == "score" and GameManager.is_blitz_mode() else 1 if key == "max_grade_achieved" or (key == "lives" and not GameManager.is_blitz_mode()) else 0.1 if key == "time_left" else 0
        _number(page, str(key).capitalize(), session_draft[key], func(value: float): session_draft[key] = value if fractional else int(value), minimum, 9 if key == "lives" else 13 if key == "max_grade_achieved" else State.LIMIT, 0.1 if fractional else 1)
    for key in ["correct_count", "incorrect_count"]:
        _number(page, "Grade " + str(key).capitalize(), session_draft[key], func(value: float): session_draft[key] = int(value), 0, 4 if key == "correct_count" else 2)
    for index in 13:
        _number(page, "Grade %d session correct" % (index + 1), session_draft.correct_by_grade[index], func(value: float): session_draft.correct_by_grade[index] = int(value))
    if GameManager.is_adventure_mode() and not GameManager.is_adventure_boss() and GameManager.adventure_config.timed:
        _number(page, "Question seconds remaining", session_draft.question_seconds, func(value: float): session_draft.question_seconds = value, 0.1, State.LIMIT, 0.1)
    if session_draft.has("players"):
        for player in 2:
            for key in ["score", "correct", "incorrect"]:
                _number(page, "Player %d %s" % [player + 1, key], session_draft.players[player][key], func(value: float): session_draft.players[player][key] = int(value), -State.LIMIT if key == "score" else 0)

func _reset_page() -> void:
    var page := _page("Reset")
    _label(page, "Resets save immediately after confirmation. No files outside these three game stores are touched.")
    for section in ["records", "lifetime", "achievements", "settings", "adventure"]:
        _button(page, "Reset " + str(section), func():
            _confirm("Reset saved %s to defaults? Other unapplied profile edits will be discarded." % section, func():
                var updated := ProfileManager.data.duplicate(true)
                updated[section] = ProfileManager._default_data()[section]
                var error := State.save_profile(updated)
                if error.is_empty():
                    draft = updated.duplicate(true)
                    edited = true
                    _rebuild()
                _result(error, "Saved %s reset." % section)))
    for store in [BlitzLeaderboard, BlitzDuelLeaderboard]:
        _button(page, "Clear " + ("solo" if store == BlitzLeaderboard else "duel") + " leaderboards", func():
            _confirm("Permanently clear all 13 grade leaderboards in this score store?", func():
                var saved: bool = store.replace_for_debugging(store._empty_boards())
                edited = edited or saved
                if saved:
                    board_drafts["solo" if store == BlitzLeaderboard else "duel"] = store._boards.duplicate(true)
                    _rebuild()
                _result("" if saved else store.last_error, "Leaderboards cleared.")))
    _button(page, "RESET EVERYTHING and return to title", func():
        _confirm("Reset ALL saved progress, records, achievements, cosmetics, settings, and both leaderboards? This also abandons the current attempt.", _reset_all))

func _reset_all() -> void:
    if not OS.is_debug_build():
        _result(State.fail("Debug editing is unavailable in release builds."), "")
        return
    var errors: Array[String] = []
    var error := State.save_profile(ProfileManager._default_data())
    if not error.is_empty():
        errors.append(error)
    for store in [BlitzLeaderboard, BlitzDuelLeaderboard]:
        if not store.replace_for_debugging(store._empty_boards()):
            errors.append(store.last_error)
    edited = true
    if not errors.is_empty():
        draft = ProfileManager.data.duplicate(true)
        board_drafts.solo = BlitzLeaderboard._boards.duplicate(true)
        board_drafts.duel = BlitzDuelLeaderboard._boards.duplicate(true)
        _rebuild()
        _result("Reset incomplete; some stores may already be reset. " + " ".join(errors), "")
        return
    _reset_runtime.call_deferred()

func _free_current_scene() -> void:
    if get_tree().current_scene != null:
        get_tree().current_scene.free()

func _launch_session(mode: int, number: int) -> void:
    if not OS.is_debug_build():
        return
    close_menu()
    _free_current_scene()
    if mode == 0:
        GameManager.start_session()
        ProgressionManager.current_grade = number
        GameManager.max_grade_achieved = number
    elif mode == 1:
        GameManager.start_practice_session(number, ProfileManager.practice_lives())
    elif mode in [2, 3]:
        if mode == 3:
            GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
        GameManager.start_blitz_session(number, 2 if mode == 3 else 1)
    else:
        GameManager.start_adventure_level(["elementary", "middle", "high"][mode - 4], number)
    GameManager.goto_scene("res://scenes/game/game.tscn")

func _reset_runtime() -> void:
    if not OS.is_debug_build():
        return
    close_menu()
    _free_current_scene()
    GameManager.start_session()
    GameManager.abandon_current_session()
    GameManager.practice_lives = ProfileManager.practice_lives()
    GameManager.blitz_grade = 1
    GameManager.blitz_players = 1
    GameManager.adventure_campaign = "elementary"
    GameManager.adventure_config.clear()
    GameManager._adventure_remaining = 0
    GameManager._adventure_started = 0
    GameManager._adventure_paused_at = 0
    GameManager.last_final_score = 0
    GameManager.last_final_grade = 1
    GameManager.duel_input.reset()
    GameManager.goto_scene("res://scenes/title/title.tscn")

func _confirm(text: String, callback: Callable) -> void:
    _pending = callback
    confirmation.dialog_text = text
    confirmation.popup_centered(Vector2i(600, 180))

func _result(error: String, success: String) -> void:
    status.text = success if error.is_empty() else error
    status.modulate = Color("7fffd4") if error.is_empty() else Color("ff9c9c")

func _rebuild() -> void:
    var index := tabs.current_tab
    panel.hide()
    panel.queue_free()
    confirmation.hide()
    confirmation.queue_free()
    _build()
    tabs.current_tab = index
