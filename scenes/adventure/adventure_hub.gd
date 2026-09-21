extends Control

const Catalog = preload("res://scripts/adventure/adventure_catalog.gd")
const Sun = preload("res://scripts/adventure/adventure_sun.gd")
const CatScene = preload("res://scenes/characters/math_cat.tscn")
const AccessoryArt = preload("res://scripts/character/cat_accessory.gd")
const SHOP_GOLD := Color("f0d35e")
const SHOP_TEXT := Color("ebf0f7")
const SHOP_BORDER := Color("638ab7")
const SHOP_FILL := Color("101f35")
const SHOP_HIGHLIGHT := Color("2b4269")
const MAP_POINTS := [Vector2(150, 515), Vector2(340, 515), Vector2(490, 420), Vector2(680, 420), Vector2(865, 420), Vector2(1060, 330), Vector2(910, 215), Vector2(730, 215), Vector2(520, 215)]
const INK := Color("100c29")
const CYAN := Color("73f5ed")
const PINK := Color("ff65c5")
const GOLD := Color("ffe477")
const STAGE_FILL := Color("203b3a")
const SKYLINE_HEIGHTS := [78, 112, 90, 142, 124, 168, 138, 104, 128, 94, 158, 126, 170, 116, 144, 96, 126, 82]
const RETRO_GRID_SPEED := 0.10
const RETRO_GRID_COLUMNS := 11.0

var canvas: Control
var buttons: Array[Button] = []
var level_buttons: Array[Button] = []
var selected := 0
var navigation_ready_at := 0
var detail: Label
var map_cat: MathCat
var map_cat_tween: Tween
var map_visible := false
var shop_visible := false
var shop_item := "bow_tie"
var shop_cat: MathCat
var shop_action: Button
var shop_status: Label
var shop_preview_label: Label
var shop_wallet: Label
var shop_remove_all: Button
var shop_item_buttons: Dictionary = {}
var shop_slot_labels: Dictionary = {}
var shop_slot_icons: Dictionary = {}
var shop_slot_panels: Dictionary = {}
var shop_styles: Dictionary = {}
var background_clock := 0.0

func _ready() -> void:
    DebugMenu.state_edited.connect(_debug_refresh_view)
    resized.connect(_resize)
    ProfileManager.setting_changed.connect(_on_setting_changed)
    _on_setting_changed("animated_background")
    if GameManager.current_state == GameManager.GameState.WORLD_MAP:
        show_map(GameManager.adventure_campaign)
    else:
        show_campaigns()
        await get_tree().process_frame
        if not map_visible and not buttons.is_empty():
            buttons[0].grab_focus()

func _on_setting_changed(setting: String) -> void:
    if setting == "animated_background":
        set_process(ProfileManager.animated_background_enabled())
        queue_redraw()

func _process(delta: float) -> void:
    background_clock += delta
    queue_redraw()

func _resize() -> void:
    if is_instance_valid(canvas):
        var factor := minf(size.x / 1280.0, size.y / 720.0)
        canvas.scale = Vector2.ONE * factor
        canvas.position = (size - Vector2(1280, 720) * factor) / 2
    queue_redraw()

func _clear() -> void:
    _stop_map_cat_animation()
    if is_instance_valid(canvas):
        remove_child(canvas)
        canvas.queue_free()
    buttons.clear()
    level_buttons.clear()
    map_cat = null
    detail = null
    shop_cat = null
    shop_action = null
    shop_status = null
    shop_wallet = null
    shop_remove_all = null
    shop_item_buttons.clear()
    shop_slot_labels.clear()
    shop_slot_icons.clear()
    shop_slot_panels.clear()
    selected = 0
    canvas = Control.new()
    canvas.size = Vector2(1280, 720)
    add_child(canvas)
    _resize()

func _label(text: String, rect: Rect2, font_size: int = 24) -> Label:
    var label := Label.new()
    label.text = text
    label.position = rect.position
    label.size = rect.size
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("ece5ff"))
    label.add_theme_color_override("font_outline_color", INK)
    label.add_theme_constant_override("outline_size", 4)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(label)
    return label

func _style(fill: Color, border: Color, width: int = 3) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(4)
    return style

func _button(text: String, rect: Rect2, callback: Callable, unlocked: bool = true) -> Button:
    var button := Button.new()
    button.text = text
    button.position = rect.position
    button.size = rect.size
    button.add_theme_font_size_override("font_size", 22)
    button.add_theme_stylebox_override("normal", _style(Color("201638"), CYAN))
    button.add_theme_stylebox_override("focus", _style(Color("35234e"), GOLD, 5))
    button.add_theme_stylebox_override("hover", _style(Color("35234e"), GOLD, 5))
    button.add_theme_stylebox_override("disabled", _style(Color("19132c"), Color("635473")))
    button.add_theme_color_override("font_color", Color("ece5ff"))
    button.add_theme_color_override("font_disabled_color", Color("a99abf"))
    if shop_visible:
        button.add_theme_stylebox_override("normal", _shop_style(SHOP_FILL, SHOP_BORDER))
        button.add_theme_stylebox_override("focus", _shop_style(SHOP_HIGHLIGHT, SHOP_GOLD))
        button.add_theme_stylebox_override("hover", _shop_style(SHOP_HIGHLIGHT, SHOP_GOLD))
        button.add_theme_color_override("font_color", SHOP_TEXT)
    button.disabled = not unlocked
    button.focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE
    button.pressed.connect(func():
        AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
        callback.call())
    canvas.add_child(button)
    if unlocked:
        buttons.append(button)
        var index := buttons.size() - 1
        button.focus_entered.connect(_sync_focus.bind(index))
        button.mouse_entered.connect(_focus_with_pointer.bind(button))
    return button

func _shop_style(fill: Color, border: Color) -> StyleBoxTexture:
    var key := fill.to_html() + border.to_html()
    if shop_styles.has(key):
        return shop_styles[key]
    var image := Image.create(20, 20, false, Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    image.fill_rect(Rect2i(4, 2, 16, 18), Color("080e19"))
    image.fill_rect(Rect2i(2, 4, 18, 16), Color("080e19"))
    image.fill_rect(Rect2i(2, 0, 14, 18), border)
    image.fill_rect(Rect2i(0, 2, 18, 14), border)
    image.fill_rect(Rect2i(2, 2, 14, 14), fill)
    var style := StyleBoxTexture.new()
    style.texture = ImageTexture.create_from_image(image)
    for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
        style.set_texture_margin(side, 6 if side in [SIDE_LEFT, SIDE_TOP] else 8)
        style.set_content_margin(side, 8)
    shop_styles[key] = style
    return style

func _shop_panel(rect: Rect2, border: Color = SHOP_BORDER) -> Panel:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", _shop_style(SHOP_FILL, border))
    canvas.add_child(panel)
    return panel

func _shop_label(text: String, rect: Rect2, font_size: int = 22, color: Color = SHOP_TEXT, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var label := _label(text, rect, font_size)
    label.horizontal_alignment = alignment
    label.add_theme_color_override("font_color", color)
    label.add_theme_constant_override("outline_size", 0)
    return label

func _shop_icon(parent: Node, item: String, position: Vector2, box_size: Vector2) -> Node2D:
    var icon := AccessoryArt.new()
    icon.position = position
    icon.configure_icon(item, box_size)
    parent.add_child(icon)
    return icon

func show_campaigns() -> void:
    GameManager.open_adventure()
    AudioManager.stop_music()
    map_visible = false
    shop_visible = false
    _clear()
    _label("MATH CAT ADVENTURE", Rect2(120, 50, 1040, 60), 40)
    var campaign_index := 0
    for campaign in Catalog.CAMPAIGNS:
        var settings: Dictionary = Catalog.CAMPAIGNS[campaign]
        var position := Vector2(110 + campaign_index * 360, 210)
        _button("\n\n\n%s\nGrades %d-%d" % [settings.name, settings.start_grade, int(settings.victory_grade) - 1], Rect2(position, Vector2(340, 290)), show_map.bind(campaign))
        var cat := CatScene.instantiate()
        canvas.add_child(cat)
        cat.set_stage(int(settings.character))
        cat.modulate = ProfileManager.cat_modulate()
        cat.set_accessories(ProfileManager.adventure_progress(campaign).equipped_accessories)
        cat.position = position + Vector2(170, 82)
        cat.scale = Vector2(1.7, 1.7)
        campaign_index += 1
    _button("BACK", Rect2(490, 604, 300, 56), _back)
    buttons[0].grab_focus()

func show_map(campaign: String) -> void:
    GameManager.open_adventure(campaign)
    map_visible = true
    shop_visible = false
    _clear()
    var progress := ProfileManager.adventure_progress(campaign)
    _label("%s CITY TRAIL" % Catalog.CAMPAIGNS[campaign].name, Rect2(80, 20, 1120, 60), 36)
    _label("NEXT ATTEMPT: 9 LIVES   |   COINS %d%s" % [progress.currency, "   |   CAMPAIGN COMPLETE" if progress.campaign_completed else ""], Rect2(120, 82, 1040, 42), 22)
    for number in range(1, 10):
        var unlocked := ProfileManager.adventure_level_unlocked(campaign, number)
        var status := "DONE" if number in progress.completed_levels else "NEXT" if unlocked else "LOCK"
        var node_name := "BOSS" if number == 9 else str(number)
        var button := _button("%s\n%s" % [node_name, status], Rect2(MAP_POINTS[number - 1] - Vector2(58, 32), Vector2(116, 70)), _start_level.bind(number), unlocked)
        button.set_meta("level", number)
        var border: Color = Catalog.level(campaign, number).highlight_color
        for state in ["normal", "disabled", "focus", "hover", "pressed", "hover_pressed"]:
            var active: bool = state not in ["normal", "disabled"]
            var style := _style(STAGE_FILL, border.darkened(0.25) if state == "disabled" else border, 7 if active else 4)
            if state != "disabled":
                style.shadow_color = Color(border, 0.35 if active else 0.2)
                style.shadow_size = 7 if active else 4
            button.add_theme_stylebox_override(state, style)
        for state in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
            button.add_theme_color_override(state, Color.WHITE)
        level_buttons.append(button)
    detail = _label("", Rect2(80, 583, 1120, 46), 20)
    _button("PET SHOP", Rect2(675, 642, 300, 52), show_shop)
    _button("BACK", Rect2(305, 642, 300, 52), show_campaigns)
    map_cat = CatScene.instantiate()
    canvas.add_child(map_cat)
    map_cat.set_stage(int(Catalog.CAMPAIGNS[campaign].character))
    map_cat.modulate = ProfileManager.cat_modulate()
    map_cat.set_accessories(progress.equipped_accessories)
    level_buttons[int(progress.highest_unlocked_level) - 1].grab_focus()
    var transition := GameManager.adventure_map_transition
    GameManager.adventure_map_transition = {}
    if not transition.is_empty():
        _animate_map_completion(transition)
    queue_redraw()

func _stop_map_cat_animation() -> void:
    if map_cat_tween != null:
        map_cat_tween.kill()
        map_cat_tween = null
        if is_instance_valid(map_cat):
            map_cat.play_idle()

func _animate_map_completion(transition: Dictionary) -> void:
    var start: Vector2 = MAP_POINTS[int(transition.from_level) - 1] + Vector2(0, -66)
    var finish: Vector2 = MAP_POINTS[int(transition.to_level) - 1] + Vector2(0, -66)
    map_cat.position = start
    map_cat_tween = canvas.create_tween()
    map_cat_tween.tween_interval(0.25)
    if transition.boss:
        map_cat.play_high_score()
        for jump in 3:
            map_cat_tween.tween_property(map_cat, "position:y", start.y - 28, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            map_cat_tween.tween_property(map_cat, "position:y", start.y, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            map_cat_tween.tween_interval(0.1)
    else:
        map_cat.play_happy()
        map_cat_tween.tween_method(func(progress: float):
            map_cat.position = start.lerp(finish, progress) + Vector2(0, -sin(progress * PI) * 24), 0.0, 1.0, 0.85)
    map_cat_tween.tween_callback(func():
        map_cat.position = finish
        map_cat.play_idle()
        map_cat_tween = null)

func show_shop(notice: String = "") -> void:
    map_visible = false
    shop_visible = true
    _clear()
    var campaign := GameManager.adventure_campaign
    var progress := ProfileManager.adventure_progress(campaign)
    _shop_label("PET SHOP", Rect2(72, 26, 700, 56), 44, SHOP_GOLD)
    _shop_label("%s CAMPAIGN  /  COSMETICS ONLY" % Catalog.CAMPAIGNS[campaign].name, Rect2(76, 86, 780, 28), 20)
    _shop_panel(Rect2(928, 30, 304, 82), SHOP_GOLD)
    var coin := PixelMeterIcon.new()
    coin.kind = PixelMeterIcon.Kind.COIN
    coin.position = Vector2(950, 54)
    coin.size = Vector2(36, 36)
    coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(coin)
    _shop_label("COINS", Rect2(1000, 38, 208, 24), 16, SHOP_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
    shop_wallet = _shop_label(str(progress.currency), Rect2(1000, 64, 208, 34), 28, SHOP_TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
    _shop_panel(Rect2(48, 132, 660, 452))
    _shop_panel(Rect2(736, 132, 496, 452))
    _shop_label("ACCESSORIES", Rect2(76, 148, 600, 30), 22, SHOP_GOLD)
    _shop_label("DRESSING ROOM", Rect2(768, 148, 432, 30), 22, SHOP_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
    var items: Array = Catalog.ACCESSORIES.keys()
    for index in items.size():
        var item: String = items[index]
        var item_name: String = Catalog.ACCESSORIES[item].name
        var equipped: bool = item in progress.equipped_accessories.values()
        var owned: bool = item in progress.owned_accessories
        var state := "EQUIPPED" if equipped else "OWNED" if owned else "%d COINS" % Catalog.ACCESSORIES[item].price
        var button := _button(item_name, Rect2(68, 190 + index * 54, 620, 48), _select_shop_item.bind(item))
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.tooltip_text = "%s - %s - %s" % [item_name, str(Catalog.ACCESSORIES[item].slot).to_upper(), state]
        for style_name in ["normal", "focus", "hover"]:
            var row_style := button.get_theme_stylebox(style_name).duplicate() as StyleBoxTexture
            row_style.set_content_margin(SIDE_LEFT, 64)
            row_style.set_content_margin(SIDE_RIGHT, 202)
            button.add_theme_stylebox_override(style_name, row_style)
        var state_label := _shop_label(state, Rect2(402, 4, 200, 40), 20, SHOP_GOLD if equipped or not owned else SHOP_TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
        state_label.reparent(button, false)
        state_label.name = "ItemState"
        var icon := _shop_icon(button, item, Vector2(32, 24), Vector2(40, 32))
        icon.name = "ItemIcon"
        button.set_meta("shop_item", item)
        shop_item_buttons[item] = button
    var rug := Polygon2D.new()
    rug.polygon = PackedVector2Array([Vector2(842, 384), Vector2(1126, 384), Vector2(1150, 400), Vector2(1126, 416), Vector2(842, 416), Vector2(818, 400)])
    rug.color = Color("2b4269")
    canvas.add_child(rug)
    var rug_center := Polygon2D.new()
    rug_center.polygon = PackedVector2Array([Vector2(850, 390), Vector2(1118, 390), Vector2(1134, 400), Vector2(1118, 410), Vector2(850, 410), Vector2(834, 400)])
    rug_center.color = Color("638ab7")
    canvas.add_child(rug_center)
    shop_cat = CatScene.instantiate()
    canvas.add_child(shop_cat)
    shop_cat.position = Vector2(984, 306)
    shop_cat.scale = Vector2(3, 3)
    shop_cat.set_stage(int(Catalog.CAMPAIGNS[campaign].character))
    shop_cat.modulate = ProfileManager.cat_modulate()
    shop_preview_label = _shop_label("", Rect2(768, 422, 432, 30), 22, SHOP_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    for index in 3:
        var slot: String = ["head", "face", "neck"][index]
        var position := Vector2(768 + index * 148, 466)
        shop_slot_panels[slot] = _shop_panel(Rect2(position, Vector2(136, 94)))
        _shop_label(slot.to_upper(), Rect2(position + Vector2(4, 4), Vector2(128, 22)), 16, SHOP_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
        shop_slot_icons[slot] = _shop_icon(canvas, "", position + Vector2(68, 48), Vector2(40, 26))
        shop_slot_labels[slot] = _shop_label("", Rect2(position + Vector2(4, 70), Vector2(128, 18)), 14, SHOP_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    shop_action = _button("", Rect2(736, 604, 496, 50), _shop_activate)
    shop_remove_all = _button("REMOVE ALL", Rect2(286, 604, 252, 50), _select_shop_item.bind(""))
    shop_remove_all.set_meta("shop_item", "")
    shop_status = _shop_label("", Rect2(48, 662, 1184, 24), 18, SHOP_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    _button("WORLD MAP", Rect2(48, 604, 220, 50), show_map.bind(campaign))
    _shop_label("ARROWS / D-PAD: BROWSE    ENTER / A: SELECT    ESC / B: MAP", Rect2(48, 692, 1184, 20), 16, SHOP_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    if shop_item.is_empty():
        shop_remove_all.grab_focus()
    else:
        shop_item_buttons[shop_item].grab_focus()
    _preview_shop_item(shop_item)
    if not notice.is_empty():
        shop_status.text = notice
    elif not ProfileManager.last_save_error.is_empty():
        shop_status.text = ProfileManager.last_save_error

func _preview_shop_item(item: String) -> void:
    shop_item = item
    if not is_instance_valid(shop_cat):
        return
    var progress := ProfileManager.adventure_progress(GameManager.adventure_campaign)
    var outfit := Catalog.with_accessory(progress.equipped_accessories, item)
    shop_cat.set_accessories(outfit)
    _refresh_shop_slots(outfit, str(Catalog.ACCESSORIES[item].slot) if not item.is_empty() else "")
    var owned: bool = item.is_empty() or item in progress.owned_accessories
    var equipped: bool = item in progress.equipped_accessories.values()
    shop_preview_label.text = "PREVIEW: " + (str(Catalog.ACCESSORIES[item].name) if not item.is_empty() else "NO ACCESSORIES")
    shop_action.text = "REMOVE ALL - FREE" if item.is_empty() else "REMOVE - FREE" if equipped else "EQUIP - FREE" if owned else "BUY & EQUIP - %d COINS" % Catalog.ACCESSORIES[item].price
    shop_status.text = "Preview only. Select Buy & Equip to purchase." if not owned else "Owned accessories can be changed for free."
    if not owned and int(progress.currency) < int(Catalog.ACCESSORIES[item].price):
        shop_status.text = "Need %d more coins. Complete or replay levels to earn more." % (int(Catalog.ACCESSORIES[item].price) - int(progress.currency))

func _refresh_shop_slots(outfit: Dictionary, preview_slot: String = "") -> void:
    for slot in shop_slot_labels:
        var item: String = outfit.get(slot, "")
        shop_slot_labels[slot].text = str(Catalog.ACCESSORIES[item].name) if not item.is_empty() else "EMPTY"
        shop_slot_icons[slot].configure_icon(item, Vector2(40, 26))
        shop_slot_panels[slot].add_theme_stylebox_override("panel", _shop_style(SHOP_HIGHLIGHT if slot == preview_slot else SHOP_FILL, SHOP_GOLD if slot == preview_slot else SHOP_BORDER))

func _select_shop_item(item: String) -> void:
    _preview_shop_item(item)
    shop_action.grab_focus()

func _shop_activate() -> void:
    var campaign := GameManager.adventure_campaign
    var progress := ProfileManager.adventure_progress(campaign)
    var owned: bool = shop_item.is_empty() or shop_item in progress.owned_accessories
    var removing: bool = shop_item.is_empty() or shop_item in progress.equipped_accessories.values()
    var error := ProfileManager.equip_adventure_accessory(campaign, shop_item, not removing) if owned else ProfileManager.buy_adventure_accessory(campaign, shop_item)
    if not error.is_empty():
        shop_status.text = error
        return
    show_shop("Saved. All accessories removed." if shop_item.is_empty() else "Saved. Accessory removed." if removing else "Saved. Accessory equipped!" if owned else "Purchased, equipped, and saved!")
    shop_cat.set_accessories(ProfileManager.adventure_progress(campaign).equipped_accessories)
    _refresh_shop_slots(shop_cat.equipped_accessories)
    shop_preview_label.text = "YOUR CAT"
    shop_action.grab_focus()

func _sync_focus(index: int) -> void:
    var was_animating := map_cat_tween != null
    _stop_map_cat_animation()
    if was_animating and is_instance_valid(map_cat):
        var level := int(buttons[selected].get_meta("level", 0))
        if level > 0:
            map_cat.position = MAP_POINTS[level - 1] + Vector2(0, -66)
    selected = index
    if shop_visible and buttons[index].has_meta("shop_item"):
        _preview_shop_item(str(buttons[index].get_meta("shop_item")))
    if map_visible and is_instance_valid(detail):
        var number := int(buttons[index].get_meta("level", 0))
        if number > 0:
            var config := Catalog.level(GameManager.adventure_campaign, number)
            var rule := "BOSS: GRADES %d-%d" % [config.boss_start_grade, int(config.boss_victory_grade) - 1] if number == 9 else "GRADE %d   |   %d CORRECT   |   %s" % [config.grade, config.correct_target, "%.1fs / QUESTION" % config.timer_seconds if config.timed else "UNTIMED"]
            detail.text = "%s   |   %s" % [config.city_name.to_upper(), rule]
            if is_instance_valid(map_cat):
                map_cat.position = MAP_POINTS[number - 1] + Vector2(0, -66)

func _focus_with_pointer(button: Button) -> void:
    if not map_visible and not shop_visible:
        for candidate in buttons:
            candidate.add_theme_stylebox_override("hover", _style(Color("35234e"), GOLD, 5))
    button.grab_focus()

func _prioritize_focus_highlight() -> void:
    if map_visible or shop_visible:
        return
    for button in buttons:
        button.add_theme_stylebox_override("hover", _style(Color("201638"), CYAN))

func _start_level(number: int) -> void:
    if GameManager.start_adventure_level(GameManager.adventure_campaign, number):
        GameManager.goto_scene("res://scenes/game/game.tscn")

func _back() -> void:
    GameManager.abandon_current_session()
    GameManager.goto_scene("res://scenes/title/title.tscn")

func _input(event: InputEvent) -> void:
    if DebugMenu.handle_toggle(event):
        return
    if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
        return
    get_viewport().set_input_as_handled()
    _prioritize_focus_highlight()
    var direction := 0
    if event is InputEventJoypadMotion:
        if event.axis not in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] or absf(event.axis_value) < 0.65:
            return
        if Time.get_ticks_msec() < navigation_ready_at:
            return
        navigation_ready_at = Time.get_ticks_msec() + 100
        direction = -1 if event.axis_value < 0 else 1
    else:
        if not event.is_pressed() or (event is InputEventKey and event.echo):
            return
        if event.is_action_pressed("ui_cancel"):
            AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
            if shop_visible:
                show_map(GameManager.adventure_campaign)
            elif map_visible:
                show_campaigns()
            else:
                _back()
            return
        if event.is_action_pressed("ui_accept"):
            if not buttons.is_empty() and not buttons[selected].disabled:
                buttons[selected].pressed.emit()
            return
        if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
            direction = -1
        elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
            direction = 1
    if direction != 0 and not buttons.is_empty():
        buttons[posmod(selected + direction, buttons.size())].grab_focus()
        AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("0b1820") if shop_visible else INK)
    if not is_instance_valid(canvas):
        return
    draw_set_transform(canvas.position, 0, canvas.scale)
    if shop_visible:
        for row in 18:
            for column in 32:
                var tile := Rect2(column * 40, row * 40, 38, 38)
                var tile_color := Color("244e44") if (row + column) % 3 else Color("28564a")
                draw_rect(tile, tile_color.darkened(0.55))
        draw_set_transform(Vector2.ZERO)
        return
    _draw_sky()
    _draw_skyline()
    _draw_grid()
    if map_visible:
        _draw_rooftops()
        for index in range(MAP_POINTS.size() - 1):
            var unlocked := not level_buttons[index + 1].disabled
            var edge := CYAN if unlocked else Color("77608c")
            draw_line(MAP_POINTS[index], MAP_POINTS[index + 1], INK, 12)
            draw_line(MAP_POINTS[index], MAP_POINTS[index + 1], Color(edge, 0.15), 8)
            draw_line(MAP_POINTS[index], MAP_POINTS[index + 1], edge, 2)
        for button in level_buttons:
            draw_rect(Rect2(button.position, button.size).grow(6), INK)
        draw_rect(Rect2(64, 580, 1152, 52), Color("19132c"))
        draw_line(Vector2(80, 580), Vector2(1200, 580), Color("633277"), 2)
    # Keep sky details behind a quiet header, not behind its text.
    draw_rect(Rect2(64, 16, 1152, 110), INK)
    draw_line(Vector2(160, 126), Vector2(1120, 126), Color("633277"), 2)
    draw_set_transform(Vector2.ZERO)

func _debug_refresh_view() -> void:
    if map_visible:
        show_map(GameManager.adventure_campaign)
    else:
        show_campaigns()

func _draw_sky() -> void:
    for index in 65:
        var point := Vector2(posmod(index * 137 + 39, 1240) + 20, posmod(index * 71, 390) + 30)
        var star_seed := float(posmod(index * 17, 19)) / 18.0
        var twinkle := 0.5 + 0.5 * sin(background_clock * (1.2 + star_seed * 1.8) + star_seed * 18.0)
        draw_rect(Rect2(point, Vector2(2, 2)), Color(0.65, 0.7, 1, 0.60 * twinkle))
    Sun.draw_on(self, Catalog.WORLD_MAP_SUN_CENTER)

func _draw_skyline() -> void:
    for index in SKYLINE_HEIGHTS.size():
        var height := float(SKYLINE_HEIGHTS[index])
        var roof := Vector2(index * 76, 438 - height)
        if roof.x >= 1280:
            break
        var width := minf(65, 1280 - roof.x)
        draw_rect(Rect2(roof, Vector2(width, height)), Color("211638"))
        draw_line(roof, roof + Vector2(width, 0), Color("633277"), 2)
        for row in 3:
            for column in 2:
                draw_rect(Rect2(roof + Vector2(12 + column * 28, 16 + row * 22), Vector2(7, 9)), Color("854578"))
        if index % 3 == 0:
            var gable := PackedVector2Array([roof, roof + Vector2(32, -18), roof + Vector2(65, 0)])
            draw_colored_polygon(gable, Color("211638"))
            draw_polyline(gable, Color("633277"), 2)
            draw_rect(Rect2(roof + Vector2(12, -24), Vector2(8, 14)), Color("633277"))
        elif index % 3 == 1:
            draw_line(roof + Vector2(32, 0), roof + Vector2(32, -24), Color("633277"), 2)
            draw_rect(Rect2(roof + Vector2(30, -26), Vector2(4, 4)), PINK)

func _draw_grid() -> void:
    draw_rect(Rect2(0, 438, 1280, 282), INK)
    var grid_color := Color("54317d")
    draw_line(Vector2(0, 438), Vector2(1280, 438), grid_color, 2)
    const horizon := 438.0
    const ground_height := 282.0
    for column in range(-7, 8):
        for segment in 36:
            var start_ground := maxf(0.025, float(segment) / 36.0)
            var end_ground := float(segment + 1) / 36.0
            var middle_ground := (start_ground + end_ground) * 0.5
            var start := Vector2(640.0 + float(column) * 1280.0 * start_ground / RETRO_GRID_COLUMNS, horizon + ground_height * start_ground)
            var end := Vector2(640.0 + float(column) * 1280.0 * end_ground / RETRO_GRID_COLUMNS, horizon + ground_height * end_ground)
            draw_line(start, end, Color(grid_color, _grid_opacity(middle_ground)), 1)
    var time_phase := fmod(background_clock * RETRO_GRID_SPEED * 1.5, 1.0)
    for line in range(1, 62):
        var ground := 1.5 / (float(line) + 0.5 - time_phase)
        if ground >= 0.025 and ground <= 1.0:
            var y := floorf(horizon + ground_height * ground)
            draw_line(Vector2(0, y), Vector2(1280, y), Color(grid_color, _grid_opacity(ground)), 1)

func _grid_opacity(ground: float) -> float:
    return smoothstep(0.02, 0.52, ground) * (0.55 + ground * 0.45)

func _draw_rooftops() -> void:
    # Only stages 6-9 retain buildings; keep the lower grid unobstructed.
    for index in range(MAP_POINTS.size() - 1, 4, -1):
        var roof: Vector2 = MAP_POINTS[index] + Vector2(-76, 42)
        var edge := PINK if index == 8 else CYAN
        draw_rect(Rect2(roof, Vector2(152, 76)), Color("201638"))
        draw_rect(Rect2(roof, Vector2(152, 7)), Color(edge, 0.15))
        draw_line(roof, roof + Vector2(152, 0), edge, 3)
        for window in 4:
            draw_rect(Rect2(roof + Vector2(18 + window * 34, 21), Vector2(10, 16)), Color(edge, 0.3))
