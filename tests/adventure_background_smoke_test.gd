extends Node

const GameScene = preload("res://scenes/game/game.tscn")
const HubScene = preload("res://scenes/adventure/adventure_hub.tscn")
const Sun = preload("res://scripts/adventure/adventure_sun.gd")
var failures: Array[String] = []
var rendered_stages: Array[PackedByteArray] = []
var world_map_sun_patch := PackedByteArray()
var world_map_sun_edge := PackedByteArray()

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func _ready() -> void:
    get_tree().create_timer(90).timeout.connect(func() -> void:
        push_error("Adventure background smoke test timed out.")
        get_tree().quit(1))
    var main := preload("res://scripts/main.gd").new()
    main._configure_input_map()
    main.free()
    ProfileManager.storage_path = "user://adventure-background-test.json"
    ProfileManager.data = ProfileManager._default_data()
    ProfileManager.set_animated_background(true)
    check(Sun.RADIUS == 98.0, "Stage and map suns share the original 196-pixel diameter")
    GameManager.clock_msec = func(): return 1000
    for campaign in GameManager.AdventureCatalog.CAMPAIGNS:
        for number in range(1, 10):
            ProfileManager.complete_adventure_level(GameManager.AdventureCatalog.level(campaign, number), 100, 9)

    GameManager.open_adventure("elementary")
    var hub := HubScene.instantiate()
    add_child(hub)
    hub.show_map("elementary")
    await _capture("world-map")
    hub.queue_free()
    await _frames()

    GameManager.start_adventure_level("elementary", 9)
    var game := GameScene.instantiate()
    add_child(game)
    await _frames()
    check(game.get_node_or_null("AdventureStageBackground") == null, "Direct boss entry creates no stage scenery")
    await _capture("boss-before")
    for campaign in GameManager.AdventureCatalog.CAMPAIGNS:
        var previous_sun_y := INF
        for number in range(1, 9):
            check(GameManager.start_adventure_level(campaign, number), "Every unlocked stage starts")
            await _frames()
            var backdrop = game.get_node("AdventureStageBackground")
            check(backdrop.visible and not game.get_node("Background").visible, "Only authored scenery is visible on stages 1-8")
            check(backdrop.level_number == number, "Scenery follows the stage number, not its grade")
            var sun_position: Vector2 = backdrop.sun_center() * 4.0
            check(sun_position.is_equal_approx(Vector2(1120, lerpf(416.0, 225.0, float(number - 1) / 7.0))), "Sun rises evenly from the low horizon to the world-map position")
            check(sun_position.y < previous_sun_y, "Every successive stage places the sun higher")
            previous_sun_y = sun_position.y
            if number == 8:
                check(sun_position.is_equal_approx(GameManager.AdventureCatalog.WORLD_MAP_SUN_CENTER), "Stage 8 reaches the exact shared world-map sun position")
            check(backdrop.accent.is_equal_approx(GameManager.adventure_config.highlight_color), "Scenery uses the exact world-map border accent")
            check(backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Scenery cannot intercept gameplay input")
            check(backdrop.get_index() < game.get_node("Content").get_index() and backdrop.get_index() < game.get_node("Answers").get_index(), "Scenery draws behind question and answers")
            check(backdrop.size.is_equal_approx(game.size), "Scenery fills the gameplay viewport")
            ProfileManager.set_animated_background(false)
            var clock: float = backdrop.background_clock
            await _frames()
            check(backdrop.visible and not backdrop.is_processing() and backdrop.background_clock == clock, "Disabling animation freezes, rather than removes, stage art")
            check((backdrop.sun_center() * 4.0).is_equal_approx(sun_position), "Animation settings preserve the stage's sun height")
            if campaign == "elementary":
                await _capture("stage-%d" % number, true)
            elif number in [4, 5, 8]:
                await _capture("%s-stage-%d" % [campaign, number])
            if number == 8:
                await _check_sun_fidelity(game)
            check(game.question_label.get_theme_constant("outline_size") == 4, "Adventure question outline preserves contrast over the stage sun")
            ProfileManager.set_animated_background(true)
            await _frames()
            check(backdrop.is_processing() and backdrop.background_clock > clock, "Enabling animation resumes the stage clock")
            if number == 2:
                game._pause_game()
                game._open_pause_options()
                ProfileManager.set_animated_background(false)
                check(backdrop.visible and not backdrop.is_processing(), "Pause options preserve static stage scenery")
                game._close_pause_options()
                game._resume_game()
                game._restart_game()
                await _frames()
                check(backdrop.visible and backdrop.level_number == 2 and not backdrop.is_processing(), "Restart preserves the stage and static preference")
                check((backdrop.sun_center() * 4.0).is_equal_approx(sun_position), "Restart preserves the stage's sun height")
                ProfileManager.set_animated_background(true)
        GameManager.start_adventure_level(campaign, 9)
        await _frames()
        var backdrop = game.get_node("AdventureStageBackground")
        var background := game.get_node("Background") as ColorRect
        var material := background.material as ShaderMaterial
        check(not backdrop.visible and not backdrop.is_processing() and background.visible, "Boss restores the original background and stops hidden scenery")
        check(material.shader == preload("res://shaders/synthwave_background.gdshader"), "Boss keeps its original shader")
        check(material.get_shader_parameter("grade") == 12.0 and material.get_shader_parameter("stage") == 3.0 and material.get_shader_parameter("shooting_star_intensity") == 0.65 and material.get_shader_parameter("star_density") == 1.0, "Boss keeps the exact Grade 12 palette and atmosphere")
        check(not material.get_shader_parameter("grid_color_override_enabled"), "Boss does not inherit a stage accent")
        check(not game.get_node("Grade13Equations").visible, "Boss remains free of Grade 13 equations")
        check(not game.question_label.has_theme_constant_override("outline_size"), "Boss retains its original question styling")
        if campaign == "elementary":
            await _capture("boss-after")
        ProfileManager.set_animated_background(false)
        check(background.visible and background.material == null and not backdrop.visible, "Boss static preference is unchanged")
        ProfileManager.set_animated_background(true)

    for mode in ["retro", "blitz", "duel"]:
        if mode == "retro":
            GameManager.start_session()
        else:
            GameManager.start_blitz_session(6, 2 if mode == "duel" else 1)
        await _frames()
        check(not game.get_node("AdventureStageBackground").visible and game.get_node("Background").visible, "Leaving Adventure restores " + mode + " background")
        check(not game._animated_background_material.get_shader_parameter("grid_color_override_enabled"), mode + " does not inherit the Adventure accent")
    game.queue_free()
    await _frames()
    for player in AudioManager._players + AudioManager._music_players:
        player.stop()
        player.stream = null
    GameManager.clock_msec = Time.get_ticks_msec
    print("Adventure background checks: %d failures" % failures.size())
    get_tree().quit(0 if failures.is_empty() else 1)

func _frames() -> void:
    for frame in 5:
        await get_tree().process_frame

func _check_sun_fidelity(game: Control) -> void:
    if "--capture" not in OS.get_cmdline_user_args():
        return
    # Long questions can cover the sun's edge; compare scenery rather than glyphs.
    var content := game.get_node("Content") as Control
    var was_visible := content.visible
    content.hide()
    await _frames()
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    content.visible = was_visible
    var scale := Vector2(image.get_size()) / Sun.DESIGN_SIZE
    var sun_patch := Rect2i(Vector2(1072, 160) * scale, Vector2(24, 64) * scale)
    var sun_edge := Vector2i((Vector2(1022, 225) * scale).ceil())
    check(_matches_dimmed_sun(image.get_region(sun_patch).get_data(), world_map_sun_patch), "Stage sun retains the map's gradient and fine row detail at 70% brightness")
    check(_matches_dimmed_sun(image.get_region(Rect2i(sun_edge, Vector2i.ONE)).get_data(), world_map_sun_edge), "Dimmed stage sun retains the map's full-radius edge")

func _matches_dimmed_sun(actual: PackedByteArray, reference: PackedByteArray) -> bool:
    if actual.size() != reference.size():
        return false
    for index in actual.size():
        var expected := float(reference[index]) * (1.0 if index % 4 == 3 else 0.7)
        # Allow one display-byte of rounding while keeping opacity unchanged.
        if absf(float(actual[index]) - expected) > (0.0 if index % 4 == 3 else 1.0):
            return false
    return true

func _capture(label: String, compare_scenery: bool = false) -> void:
    if "--capture" not in OS.get_cmdline_user_args():
        return
    await _frames()
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    var path := "user://adventure-background-%s.png" % label
    check(image.save_png(path) == OK, "Capture " + label)
    print("CAPTURE " + ProjectSettings.globalize_path(path))
    var scale := Vector2(image.get_size()) / Sun.DESIGN_SIZE
    var sun_patch := Rect2i(Vector2(1072, 160) * scale, Vector2(24, 64) * scale)
    var sun_edge := Vector2i((Vector2(1022, 225) * scale).ceil())
    if label == "world-map":
        world_map_sun_patch = image.get_region(sun_patch).get_data()
        world_map_sun_edge = image.get_region(Rect2i(sun_edge, Vector2i.ONE)).get_data()
        check(image.get_pixelv(sun_edge).r > 0.9, "World-map sun retains its original full brightness")
    if compare_scenery:
        # This gutter contains scenery only, so different questions cannot fake distinct art.
        var scenery := image.get_region(Rect2i(0, 120, 200, 250)).get_data()
        check(not scenery in rendered_stages, "Each stage has distinct rendered scenery")
        rendered_stages.append(scenery)
