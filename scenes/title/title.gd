extends Control

const NumericDisplayFormatterScript = preload("res://scripts/ui/numeric_display_formatter.gd")
const BlitzBoardView = preload("res://scripts/ui/blitz_leaderboard_view.gd")
const DETAIL_PANEL_SIZE := Vector2(1040, 640)
const MENU_BUTTON_COLOR := Color("101f35")
const MENU_BORDER_COLOR := Color("638ab7")
const MENU_HIGHLIGHT_COLOR := Color("2b4269")
const GOLD := Color("f0d35e")
const TEXT := Color("ebf0f7")
const TITLE_STICK_DEAD_ZONE := 0.65
const TITLE_CONTROLLER_NAV_REPEAT_MS := 100
const TAGLINES := [
    "Because worksheets don't have boss battles.",
    "Math is hard. Good thing you have nine lives.",
    "From simple sums to serious cat-culus.",
    "You have nine lives. Math needs one.",
    "Math has never been this catty.",
    "Solve for X. Unlock more cat.",
    "Stay Pawsitive. Solve Everything.",
    "Nine Lives. Zero Excuses. Do the Math.",
    "Think Outside the Litter Box.",
    "From Pawblems to Purrfection.",
]
const KITTEN_FRAMES := preload("res://assets/characters/math_cat/math_cat_kitten_frames.tres")
const BIG_CAT_FRAMES := preload("res://assets/characters/math_cat/math_cat_big_cat_frames.tres")
const TIGER_FRAMES := preload("res://assets/characters/math_cat/math_cat_tiger_frames.tres")
const NERD_CAT_FRAMES := preload("res://assets/characters/math_cat/math_cat_nerd_cat_frames.tres")

@onready var start_button: Button = %StartButton
@onready var main_buttons: Array[Button] = [%StartButton, %BlitzButton, %AdventureButton, %OptionsButton, %StatsButton, %AchievementsButton, %ExitButton]
@onready var subtitle: Label = $Panel/Margin/Layout/Subtitle

static var _last_tagline_index := -1
var selected_main_index := 0
var selected_detail_index := 0
var selected_blitz_grade := 1
var selected_blitz_players := 1
var selected_board_players := 1
var _duel_join_status: Label
var _duel_join_start: Button
var _blitz_board: BlitzBoardView
var active_view := ""
var detail_panel: PanelContainer
var detail_layout: VBoxContainer
var detail_buttons: Array[Control] = []
var _controller_navigation_ready_at := 0

func _ready() -> void:
    DebugMenu.state_edited.connect(_debug_refresh_view)
    GameManager.duel_input.reset()
    GameManager.duel_input.assignments_changed.connect(_refresh_duel_join)
    _select_tagline()
    _apply_button_colors(%StartButton, Color("1a6b2e"), Color("c2f2bb"), Color("26873d"), Color.WHITE)
    _apply_button_colors(%BlitzButton, Color("996608"), Color("ffef9a"), Color("b77e0c"), Color.WHITE)
    _apply_button_colors(%AdventureButton, Color("c4477f"), Color("f5bad4"), Color("d65b94"), Color.WHITE)
    _apply_button_colors(%OptionsButton, Color("215bc2"), Color("afcfff"), Color("337be8"), Color.WHITE)
    _apply_button_colors(%StatsButton, Color("7c3aed"), Color("c4b5fd"), Color("8150e6"), Color.WHITE)
    _apply_button_colors(%AchievementsButton, Color("b85410"), Color("ffd1a3"), Color("d36a20"), Color.WHITE)
    _apply_button_colors(%ExitButton, Color("c02d32"), Color("ffb4b4"), Color("e63d41"), Color.WHITE)
    for button_index in main_buttons.size():
        main_buttons[button_index].pressed.connect(_activate_main_option.bind(button_index))
        main_buttons[button_index].focus_entered.connect(_sync_main_focus.bind(button_index))
        main_buttons[button_index].mouse_entered.connect(_focus_main.bind(button_index))
    _focus_main(0)
    GameManager.set_state(GameManager.GameState.TITLE)
    AudioManager.stop_music()
    await get_tree().process_frame
    if active_view.is_empty():
        _focus_main(0)

func _select_tagline() -> void:
    var tagline_index := randi_range(0, TAGLINES.size() - 1)
    if _last_tagline_index >= 0:
        tagline_index = randi_range(0, TAGLINES.size() - 2)
        if tagline_index >= _last_tagline_index:
            tagline_index += 1
    _last_tagline_index = tagline_index
    subtitle.text = TAGLINES[tagline_index]

func _input(event: InputEvent) -> void:
    if DebugMenu.handle_toggle(event):
        return
    if event is InputEventJoypadMotion:
        get_viewport().set_input_as_handled()
    var fresh := GameManager.duel_input.fresh_press(event)
    if selected_blitz_players == 2 and (event is InputEventKey or event is InputEventJoypadButton) and not fresh:
        get_viewport().set_input_as_handled()
        return
    if active_view == "JOIN CONTROLLERS" and event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A:
        if not GameManager.duel_input.complete() or not GameManager.duel_input.devices.has(event.device):
            if fresh:
                GameManager.duel_input.join(event.device)
            get_viewport().set_input_as_handled()
            return
    var direction := _navigation_direction(event)
    var horizontal_direction := _horizontal_navigation_direction(event)
    var accepts: bool = (event is InputEventKey) or (event is InputEventJoypadButton and event.pressed)
    if direction == 0 and horizontal_direction == 0 and not accepts:
        return
    if event is InputEventKey and (not event.pressed or event.echo):
        return

    if active_view.is_empty():
        if direction != 0:
            _focus_main(_main_focus_index() + direction)
        elif event.is_action_pressed("ui_accept"):
            _activate_focused_main()
        else:
            return
    else:
        _handle_detail_input(event, direction, horizontal_direction)
    get_viewport().set_input_as_handled()

func _debug_refresh_view() -> void:
    match active_view:
        "OPTIONS":
            _open_options()
        "MATH CAT CAREER SUMMARY":
            _open_stats()
        "ACHIEVEMENTS":
            _open_achievements()
        "BLITZ HIGH SCORES":
            _open_blitz_scores()

func _focus_main(index: int) -> void:
    selected_main_index = posmod(index, main_buttons.size())
    main_buttons[selected_main_index].grab_focus()

func _sync_main_focus(index: int) -> void:
    selected_main_index = index

func _main_focus_index() -> int:
    var focused := get_viewport().gui_get_focus_owner()
    var index := main_buttons.find(focused as Button)
    return index if index >= 0 else selected_main_index

func _activate_focused_main() -> void:
    var index := _main_focus_index()
    _focus_main(index)
    main_buttons[index].emit_signal("pressed")

func _navigation_direction(event: InputEvent) -> int:
    if event is InputEventJoypadMotion:
        if absf(event.axis_value) < TITLE_STICK_DEAD_ZONE:
            return 0
        if event.axis != JOY_AXIS_LEFT_Y:
            return 0
        if not _accept_controller_navigation():
            return 0
        return -1 if event.axis_value < 0.0 else 1
    if not (event is InputEventKey or event is InputEventJoypadButton) or not event.pressed:
        return 0
    if event.is_action_pressed("ui_up"):
        if event is InputEventJoypadButton and not _accept_controller_navigation():
            return 0
        return -1
    if event.is_action_pressed("ui_down"):
        if event is InputEventJoypadButton and not _accept_controller_navigation():
            return 0
        return 1
    return 0

func _horizontal_navigation_direction(event: InputEvent) -> int:
    if event is InputEventJoypadMotion:
        if absf(event.axis_value) < TITLE_STICK_DEAD_ZONE or event.axis != JOY_AXIS_LEFT_X:
            return 0
        if not _accept_controller_navigation():
            return 0
        return -1 if event.axis_value < 0.0 else 1
    if not (event is InputEventKey or event is InputEventJoypadButton) or not event.pressed:
        return 0
    if event.is_action_pressed("ui_left"):
        if event is InputEventJoypadButton and not _accept_controller_navigation():
            return 0
        return -1
    if event.is_action_pressed("ui_right"):
        if event is InputEventJoypadButton and not _accept_controller_navigation():
            return 0
        return 1
    return 0

func _accept_controller_navigation() -> bool:
    var now := Time.get_ticks_msec()
    if now < _controller_navigation_ready_at:
        return false
    _controller_navigation_ready_at = now + TITLE_CONTROLLER_NAV_REPEAT_MS
    return true

func _activate_main_option(index: int) -> void:
    if index != 0:
        AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
    match index:
        0:
            _start_game()
        1:
            _open_blitz()
        2:
            GameManager.open_adventure()
            GameManager.goto_scene("res://scenes/adventure/adventure_hub.tscn")
        3:
            _open_options()
        4:
            _open_stats()
        5:
            _open_achievements()
        6:
            _open_exit_confirmation()

func _start_game() -> void:
    if GameManager.current_state != GameManager.GameState.TITLE:
        return
    GameManager.start_session()
    GameManager.goto_scene("res://scenes/game/game.tscn")

func _open_blitz() -> void:
    _begin_detail_view("BLITZ MODE", "%d seconds. +1 correct / -1 wrong. No lives. Time runs even in menus." % (GameManager.BLITZ_TIME_MSEC / 1000))
    _add_blitz_grade_slider()
    _add_blitz_choice("PLAYERS  <  %d PLAYER%s  >" % [selected_blitz_players, "S" if selected_blitz_players == 2 else ""], _toggle_blitz_players)
    if selected_blitz_players == 2:
        var controllers := GameManager.duel_input.controls == GameManager.DuelInput.Controls.CONTROLLERS
        _add_blitz_choice("CONTROLS  <  %s  >" % ("TWO CONTROLLERS" if controllers else "SHARED KEYBOARD"), _toggle_blitz_controls)
        _add_detail_label("First correct wins. One attempt each per question.\n%s" % ("Each controller: Y / X / B / A or D-pad answers directly." if controllers else "P1: W / A / D / S     P2: UP / LEFT / RIGHT / DOWN"), "DuelRules", 18, TEXT)
    _apply_button_colors(_add_detail_button("START BLITZ", _start_blitz), Color("1a6b2e"), Color("c2f2bb"), Color("26873d"), Color.WHITE)
    _add_detail_button("HIGH SCORES", func():
        selected_board_players = selected_blitz_players
        _open_blitz_scores())
    _add_detail_button("BACK", _close_detail_view)
    _focus_detail(0)

func _start_blitz() -> void:
    GameManager.duel_input.refresh_devices()
    if selected_blitz_players == 2 and not GameManager.duel_input.complete():
        _open_duel_join()
        return
    AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
    GameManager.start_blitz_session(selected_blitz_grade, selected_blitz_players)
    GameManager.goto_scene("res://scenes/game/game.tscn")

func _add_blitz_choice(text: String, callback: Callable) -> void:
    var button := _add_detail_button(text, callback)
    button.set_meta("blitz_choice", true)

func _toggle_blitz_players() -> void:
    selected_blitz_players = 3 - selected_blitz_players
    _open_blitz()
    _focus_detail(1)

func _toggle_blitz_controls() -> void:
    var next := 1 - int(GameManager.duel_input.controls)
    GameManager.duel_input.reset()
    GameManager.duel_input.controls = next
    _open_blitz()
    _focus_detail(2)

func _open_duel_join() -> void:
    _begin_detail_view("JOIN CONTROLLERS", "Press A on Player 1's controller, then A on a different controller for Player 2.\nB: Back")
    _add_detail_label("", "JoinStatus", 26, GOLD)
    _duel_join_status = detail_layout.get_node("JoinStatus")
    _duel_join_start = _add_detail_button("START BLITZ", _start_blitz)
    _apply_button_colors(_duel_join_start, Color("1a6b2e"), Color("c2f2bb"), Color("26873d"), Color.WHITE)
    _add_detail_button("BACK", _open_blitz)
    _refresh_duel_join()
    _focus_detail(0 if GameManager.duel_input.complete() else 1)

func _refresh_duel_join() -> void:
    if active_view != "JOIN CONTROLLERS" or not is_instance_valid(_duel_join_status):
        return
    _duel_join_status.text = GameManager.duel_input.status_text()
    _duel_join_start.disabled = not GameManager.duel_input.complete()
    if not _duel_join_start.disabled:
        _focus_detail(0)

func _open_blitz_scores() -> void:
    _begin_detail_view("BLITZ HIGH SCORES", "Local top 10 per grade. Earlier scores win ties.")
    _add_blitz_grade_slider()
    _add_blitz_choice("MODE  <  %s  >" % ("TWO PLAYERS" if selected_board_players == 2 else "SOLO"), func():
        selected_board_players = 3 - selected_board_players
        _open_blitz_scores()
        _focus_detail(1))
    _blitz_board = BlitzBoardView.new()
    _blitz_board.two_player = selected_board_players == 2
    _blitz_board.store = BlitzDuelLeaderboard if _blitz_board.two_player else BlitzLeaderboard
    _blitz_board.store.reload()
    detail_layout.add_child(_blitz_board)
    _blitz_board.display(selected_blitz_grade)
    _add_detail_button("BACK", _open_blitz)
    _focus_detail(0)

func _open_options() -> void:
    _begin_detail_view("OPTIONS", "Use LEFT / RIGHT or A to change settings. Settings save automatically.")
    _add_volume_slider("Master Volume", "master_volume", ProfileManager.master_volume())
    _add_volume_slider("Music Volume", "music_volume", ProfileManager.music_volume())
    _add_volume_slider("Sound Effects Volume", "sfx_volume", ProfileManager.sfx_volume())
    _add_option_button("Fullscreen", "fullscreen", "fullscreen")
    _add_option_button("Controller Input", "controller_input_style", "controller")
    _add_option_button("Cat Color", "cat_color", "color")
    _add_option_button("Animated Background", "animated_background", "background")
    _add_detail_button("BACK", _close_detail_view)
    _focus_detail(0)

func _open_stats() -> void:
    _begin_detail_view("MATH CAT CAREER SUMMARY", "Personal records and lifetime performance.", Vector2(840, 640))
    var profile := ProfileManager.statistics()
    var records: Dictionary = profile.records
    var lifetime: Dictionary = profile.lifetime
    _add_detail_label("Games Played: %s    Victories: %s" % [NumericDisplayFormatterScript.format_integer(lifetime.games_played), NumericDisplayFormatterScript.format_integer(lifetime.victories)], "Summary", 20, GOLD)
    _add_detail_label("Highest Grade: %s    Best Streak: %s" % [NumericDisplayFormatterScript.format_integer(records.highest_grade), NumericDisplayFormatterScript.format_integer(records.best_correct_streak)], "Progress", 20, TEXT)
    _add_detail_label("Highest Score: %s    Most Correct In One Run: %s" % [NumericDisplayFormatterScript.format_integer(records.highest_score), NumericDisplayFormatterScript.format_integer(records.most_correct_in_run)], "Records", 20, TEXT)
    _add_detail_label("Total Correct Answers: %s    Time Played: %s" % [NumericDisplayFormatterScript.format_integer(_grand_total(lifetime.correct_by_grade)), _format_duration(int(lifetime.time_played_seconds))], "Lifetime", 20, TEXT)
    _add_detail_label("Correct Answers", "CorrectAnswersHeader", 22, GOLD)
    var grades := HBoxContainer.new()
    grades.alignment = BoxContainer.ALIGNMENT_CENTER
    grades.add_theme_constant_override("separation", 120)
    detail_layout.add_child(grades)
    for grade_range in [Vector2i(1, 4), Vector2i(5, 8), Vector2i(9, 13)]:
        var column := VBoxContainer.new()
        column.alignment = BoxContainer.ALIGNMENT_BEGIN
        column.add_theme_constant_override("separation", 5)
        grades.add_child(column)
        for grade in range(grade_range.x, grade_range.y + 1):
            var grade_index := grade - 1
            var grade_label := Label.new()
            grade_label.text = "Grade %s: %s" % [NumericDisplayFormatterScript.format_integer(grade), NumericDisplayFormatterScript.format_integer(lifetime.correct_by_grade[grade_index])]
            grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            grade_label.add_theme_font_size_override("font_size", 19)
            grade_label.add_theme_color_override("font_color", TEXT)
            column.add_child(grade_label)
    _add_detail_button("BACK", _close_detail_view)
    _focus_detail(0)

func _open_achievements() -> void:
    _begin_detail_view("ACHIEVEMENTS", "Grade progression, evolutions, streaks, high scores, and career milestones.", Vector2(1040, 680))
    _add_detail_label("Achievements Unlocked: %s / %s" % [NumericDisplayFormatterScript.format_integer(AchievementManager.unlocked_count()), NumericDisplayFormatterScript.format_integer(AchievementManager.ACHIEVEMENTS.size())], "AchievementSummary", 22, GOLD)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(0, 440)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    detail_layout.add_child(scroll)
    var list := VBoxContainer.new()
    list.add_theme_constant_override("separation", 8)
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(list)
    for achievement in AchievementManager.get_all_achievements():
        var card := _make_achievement_card(achievement)
        list.add_child(card)
        _register_detail_control(card)
        card.focus_entered.connect(scroll.ensure_control_visible.bind(card))
    _add_detail_button("BACK", _close_detail_view)
    _focus_detail(0)

func _make_achievement_card(achievement: Dictionary) -> Button:
    var unlocked := bool(achievement.unlocked)
    var card := _make_button("", 18)
    card.custom_minimum_size = Vector2(0, 92)
    card.add_theme_stylebox_override("normal", _button_style(Color("1a243c"), GOLD if unlocked else Color("596273"), 2))
    card.add_theme_stylebox_override("hover", _button_style(Color("2b4269"), GOLD, 3))
    card.add_theme_stylebox_override("focus", _button_style(Color("2b4269"), GOLD, 3))
    card.modulate = Color.WHITE if unlocked else Color("8a92a0")

    var row := HBoxContainer.new()
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.add_theme_constant_override("separation", 14)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(row)

    var artwork := TextureRect.new()
    artwork.custom_minimum_size = Vector2(86, 86)
    artwork.texture = _achievement_texture(str(achievement.artwork))
    artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(artwork)

    var copy := VBoxContainer.new()
    copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    copy.alignment = BoxContainer.ALIGNMENT_CENTER
    copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(copy)
    _add_achievement_label(copy, str(achievement.name), 20, TEXT)
    _add_achievement_label(copy, str(achievement.description), 15, TEXT)

    var status := Label.new()
    status.text = "ACHIEVED" if unlocked else "NOT ACHIEVED"
    status.custom_minimum_size = Vector2(150, 0)
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size", 17)
    status.add_theme_color_override("font_color", GOLD if unlocked else Color("c2c9d2"))
    status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(status)
    return card

func _add_achievement_label(container: Container, text: String, font_size: int, color: Color) -> void:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(label)

func _achievement_texture(artwork: String) -> Texture2D:
    var frames: SpriteFrames = KITTEN_FRAMES
    if artwork.begins_with("big_cat"):
        frames = BIG_CAT_FRAMES
    elif artwork.begins_with("tiger"):
        frames = TIGER_FRAMES
    elif artwork.begins_with("nerd_cat"):
        frames = NERD_CAT_FRAMES
    var animation := &"happy"
    if artwork.contains("thinking") or artwork.contains("determined") or artwork.contains("calculator") or artwork.ends_with("_idle"):
        animation = &"idle"
    elif artwork.contains("celebrate") or artwork.contains("victory") or artwork.contains("graduate"):
        animation = &"level_up"
    elif artwork.contains("energetic"):
        animation = &"evolution_pose"
    return frames.get_frame_texture(animation, 0)

func _open_exit_confirmation() -> void:
    _begin_detail_view("EXIT GAME", "Are you sure you want to exit?", Vector2(560, 360))
    var yes_button := _add_detail_button("YES", _exit_game)
    _apply_button_colors(yes_button, Color("c02d32"), Color("ffb4b4"), Color("e63d41"), Color.WHITE)
    _add_detail_button("NO", _close_detail_view)
    _focus_detail(1)

func _begin_detail_view(title: String, subtitle: String, panel_size: Vector2 = DETAIL_PANEL_SIZE) -> void:
    if detail_panel != null:
        remove_child(detail_panel)
        detail_panel.queue_free()
    _blitz_board = null
    active_view = title
    $Panel.hide()
    detail_buttons.clear()
    detail_panel = PanelContainer.new()
    detail_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    detail_panel.size = panel_size
    detail_panel.position = -panel_size * 0.5
    detail_panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(detail_panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 32)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_right", 32)
    margin.add_theme_constant_override("margin_bottom", 24)
    detail_panel.add_child(margin)
    detail_layout = VBoxContainer.new()
    detail_layout.add_theme_constant_override("separation", 10)
    detail_layout.alignment = BoxContainer.ALIGNMENT_CENTER
    margin.add_child(detail_layout)
    _add_detail_label(title, "DetailTitle", 38, GOLD)
    _add_detail_label(subtitle, "DetailSubtitle", 18, Color("96d0f0"))

func _add_option_button(label: String, key: String, kind: String) -> void:
    var button := _make_button("", 24)
    button.set_meta("option_label", label)
    button.set_meta("option_key", key)
    button.set_meta("option_kind", kind)
    button.pressed.connect(_change_option.bind(button, 1))
    detail_layout.add_child(button)
    _register_detail_control(button)
    _refresh_option_button(button, label)

func _add_volume_slider(label: String, key: String, value: int) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    detail_layout.add_child(row)
    var name_label := Label.new()
    name_label.text = label
    name_label.custom_minimum_size = Vector2(260, 40)
    name_label.add_theme_font_size_override("font_size", 24)
    name_label.add_theme_color_override("font_color", TEXT)
    row.add_child(name_label)
    var slider := HSlider.new()
    slider.min_value = 0
    slider.max_value = 10
    slider.step = 1
    slider.value = value
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.custom_minimum_size = Vector2(420, 40)
    slider.set_meta("option_key", key)
    slider.value_changed.connect(_set_slider_volume.bind(key, slider))
    row.add_child(slider)
    var value_label := Label.new()
    value_label.name = "%sValue" % key
    value_label.text = "%d / 10" % value
    value_label.custom_minimum_size = Vector2(100, 40)
    value_label.add_theme_font_size_override("font_size", 22)
    value_label.add_theme_color_override("font_color", GOLD)
    row.add_child(value_label)
    slider.set_meta("value_label", value_label)
    _register_detail_control(slider)

func _add_blitz_grade_slider() -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    detail_layout.add_child(row)
    var name_label := Label.new()
    name_label.text = "Grade Level"
    name_label.custom_minimum_size = Vector2(260, 48)
    name_label.add_theme_font_size_override("font_size", 28)
    name_label.add_theme_color_override("font_color", TEXT)
    row.add_child(name_label)
    var slider := HSlider.new()
    slider.min_value = 1
    slider.max_value = 13
    slider.step = 1
    slider.value = selected_blitz_grade
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.custom_minimum_size = Vector2(420, 48)
    slider.value_changed.connect(_set_blitz_grade.bind(slider))
    row.add_child(slider)
    var value_label := Label.new()
    value_label.text = str(selected_blitz_grade)
    value_label.custom_minimum_size = Vector2(110, 48)
    value_label.add_theme_font_size_override("font_size", 26)
    value_label.add_theme_color_override("font_color", GOLD)
    row.add_child(value_label)
    slider.set_meta("value_label", value_label)
    _register_detail_control(slider)

func _set_blitz_grade(value: float, slider: HSlider) -> void:
    selected_blitz_grade = roundi(value)
    if _blitz_board != null:
        _blitz_board.display(selected_blitz_grade)
    var value_label := slider.get_meta("value_label") as Label
    if value_label != null:
        value_label.text = str(selected_blitz_grade)

func _set_slider_volume(value: float, key: String, slider: HSlider) -> void:
    ProfileManager.set_volume(key, roundi(value))
    var value_label := slider.get_meta("value_label") as Label
    if value_label != null:
        value_label.text = "%d / 10" % roundi(value)

func _change_option(button: Button, direction: int) -> void:
    var key := str(button.get_meta("option_key"))
    var kind := str(button.get_meta("option_kind"))
    match kind:
        "volume":
            var current := ProfileManager.master_volume() if key == "master_volume" else ProfileManager.music_volume() if key == "music_volume" else ProfileManager.sfx_volume()
            ProfileManager.set_volume(key, posmod(current + direction, 11))
        "controller":
            ProfileManager.set_controller_input_style("navigation" if not ProfileManager.controller_navigation_mode() else "direct")
        "color":
            var colors := ProfileManager.CAT_COLORS.keys()
            var current_index := colors.find(ProfileManager.cat_color_name())
            ProfileManager.set_cat_color(colors[posmod(current_index + direction, colors.size())])
        "background":
            ProfileManager.set_animated_background(not ProfileManager.animated_background_enabled())
        "fullscreen":
            ProfileManager.set_fullscreen(not ProfileManager.fullscreen_enabled())
            button.grab_focus()
    _refresh_option_button(button, str(button.get_meta("option_label")))
    AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)

func _refresh_option_button(button: Button, label: String) -> void:
    var key := str(button.get_meta("option_key"))
    var value := ""
    match key:
        "master_volume": value = "%d / 10" % ProfileManager.master_volume()
        "music_volume": value = "%d / 10" % ProfileManager.music_volume()
        "sfx_volume": value = "%d / 10" % ProfileManager.sfx_volume()
        "controller_input_style": value = "Navigation Mode" if ProfileManager.controller_navigation_mode() else "Direct Button Mode"
        "cat_color": value = ProfileManager.cat_color_name()
        "animated_background": value = "On" if ProfileManager.animated_background_enabled() else "Off"
        "fullscreen": value = "On" if ProfileManager.fullscreen_enabled() else "Off"
    button.text = "%s  <  %s  >" % [label, value]

func _add_detail_button(text: String, callback: Callable) -> Button:
    var button := _make_button(text, 26)
    button.pressed.connect(callback)
    detail_layout.add_child(button)
    _register_detail_control(button)
    return button

func _register_detail_control(control: Control) -> void:
    control.focus_mode = Control.FOCUS_ALL
    detail_buttons.append(control)
    control.focus_entered.connect(_sync_detail_focus.bind(control))
    control.mouse_entered.connect(control.grab_focus)

func _make_button(text: String, font_size: int) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(0, 48)
    button.add_theme_font_size_override("font_size", font_size)
    button.add_theme_color_override("font_color", TEXT)
    button.add_theme_color_override("font_outline_color", Color.BLACK)
    button.add_theme_constant_override("outline_size", 3)
    button.add_theme_stylebox_override("normal", _button_style(MENU_BUTTON_COLOR, MENU_BORDER_COLOR, 2))
    button.add_theme_stylebox_override("hover", _button_style(MENU_HIGHLIGHT_COLOR, GOLD, 3))
    button.add_theme_stylebox_override("focus", _button_style(MENU_HIGHLIGHT_COLOR, GOLD, 3))
    return button

func _apply_button_colors(button: Button, normal: Color, normal_border: Color, highlighted: Color, highlighted_border: Color) -> void:
    button.add_theme_stylebox_override("normal", _button_style(normal, normal_border, 2))
    button.add_theme_stylebox_override("hover", _button_style(highlighted, highlighted_border, 3))
    button.add_theme_stylebox_override("focus", _button_style(highlighted, highlighted_border, 3))

func _add_detail_label(text: String, node_name: String, font_size: int, color: Color) -> void:
    var label := Label.new()
    label.name = node_name
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    detail_layout.add_child(label)

func _handle_detail_input(event: InputEvent, vertical_direction: int, horizontal_direction: int) -> void:
    if event.is_action_pressed("ui_cancel"):
        if active_view == "BLITZ HIGH SCORES" or active_view == "JOIN CONTROLLERS":
            _open_blitz()
        else:
            _close_detail_view()
    elif vertical_direction != 0:
        _focus_detail(_detail_focus_index() + vertical_direction)
    elif horizontal_direction != 0:
        _adjust_focused_option(horizontal_direction)
    elif event.is_action_pressed("ui_accept"):
        _activate_detail_control(_focused_detail_control())
    else:
        return

func _focus_detail(index: int) -> void:
    if detail_buttons.is_empty():
        return
    selected_detail_index = posmod(index, detail_buttons.size())
    detail_buttons[selected_detail_index].grab_focus()

func _sync_detail_focus(control: Control) -> void:
    var index := detail_buttons.find(control)
    if index >= 0:
        selected_detail_index = index
    for candidate in detail_buttons:
        if candidate is HSlider:
            candidate.modulate = Color.WHITE
    if control is HSlider:
        control.modulate = GOLD

func _detail_focus_index() -> int:
    var focused := get_viewport().gui_get_focus_owner() as Control
    var index := detail_buttons.find(focused)
    return index if index >= 0 else selected_detail_index

func _focused_detail_control() -> Control:
    _focus_detail(_detail_focus_index())
    return detail_buttons[selected_detail_index]

func _adjust_focused_option(direction: int) -> void:
    if detail_buttons.is_empty():
        return
    var control := _focused_detail_control()
    if control is HSlider:
        control.value = clampf(control.value + direction, control.min_value, control.max_value)
    elif control is Button and control.has_meta("blitz_choice"):
        control.emit_signal("pressed")
    elif control is Button and control.has_meta("option_key"):
        _change_option(control, direction)

func _activate_detail_control(control: Control) -> void:
    if control is HSlider:
        control.value = clampf(control.value + 1.0, control.min_value, control.max_value)
    elif control is Button:
        control.emit_signal("pressed")

func _close_detail_view() -> void:
    if detail_panel != null:
        detail_panel.free()
    detail_panel = null
    _blitz_board = null
    active_view = ""
    $Panel.show()
    _focus_main(selected_main_index)

func _exit_game() -> void:
    ProfileManager.save()
    get_tree().quit()

func _grand_total(grade_totals: Array) -> int:
    var total := 0
    for count in grade_totals:
        total += int(count)
    return total

func _format_duration(total_seconds: int) -> String:
    return "%dh %dm %ds" % [total_seconds / 3600, total_seconds % 3600 / 60, total_seconds % 60]

func _panel_style() -> StyleBoxFlat:
    return _button_style(Color("1a243c"), GOLD, 3)

func _button_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_width_left = width
    style.border_width_top = width
    style.border_width_right = width
    style.border_width_bottom = width
    style.border_color = border
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    return style
