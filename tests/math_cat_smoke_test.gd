extends SceneTree

const MathCatScene = preload("res://scenes/characters/math_cat.tscn")
const MathCatStagesScript = preload("res://scripts/character/math_cat_stages.gd")

var _captured_evolved_stage := -1

func _init() -> void:
	_test_default_animations()
	_test_pause_and_high_score_animations()
	_test_stage_mapping()
	_test_stage_frames_and_evolution()
	print("MathCat smoke tests passed.")
	quit()

func _test_default_animations() -> void:
	var cat = MathCatScene.instantiate()
	cat._ready()

	var frames = cat.sprite_frames
	assert(frames != null, "MathCat must build placeholder frames when none are assigned.")
	for animation_name in ["idle", "happy", "sad", "level_up", "game_over"]:
		assert(frames.has_animation(animation_name), "MathCat must define the %s animation." % animation_name)
	assert(frames.get_animation_loop("idle"), "Idle must loop by default.")
	assert(not frames.get_animation_loop("game_over"), "Game over must not loop.")
	assert(String(cat.animation) == "idle", "MathCat must play idle by default.")
	assert(cat.current_stage == MathCatStagesScript.Stage.KITTEN, "MathCat must start as a Kitten.")

	cat.play_happy()
	assert(String(cat.animation) == "happy", "play_happy must switch to the happy animation.")
	cat._on_animation_finished()
	assert(String(cat.animation) == "idle", "Happy must return to idle when finished.")

	cat.play_sad()
	cat._on_animation_finished()
	assert(String(cat.animation) == "idle", "Sad must return to idle when finished.")

	cat.play_level_up()
	cat._on_animation_finished()
	assert(String(cat.animation) == "level_up", "Level up must replay its celebration once before returning to idle.")
	cat._on_animation_finished()
	assert(String(cat.animation) == "idle", "Level up must return to idle after its second celebration.")

	cat.play_game_over()
	assert(String(cat.animation) == "game_over", "play_game_over must switch to the game over animation.")
	cat._on_animation_finished()
	assert(String(cat.animation) == "game_over", "Game over must hold instead of returning to idle.")

	cat.free()

func _test_pause_and_high_score_animations() -> void:
	var cat = MathCatScene.instantiate()
	cat._ready()

	assert(cat.sprite_frames.get_animation_loop("pause"), "Pause must loop while the pause menu is open.")
	assert(cat.sprite_frames.get_animation_loop("high_score"), "High score must loop while its celebration is shown.")

	cat.play_pause()
	assert(String(cat.animation) == "pause", "play_pause must switch to the pause animation.")
	cat._on_animation_finished()
	assert(String(cat.animation) == "pause", "Pause must keep looping instead of auto-returning to idle.")
	cat.play_idle()
	assert(String(cat.animation) == "idle", "Resuming must explicitly return to idle.")

	cat.play_high_score()
	assert(String(cat.animation) == "high_score", "play_high_score must switch to the high score animation.")
	cat._on_animation_finished()
	assert(String(cat.animation) == "high_score", "High score must keep looping instead of auto-returning to idle.")
	cat.play_idle()
	assert(String(cat.animation) == "idle", "Closing the celebration must explicitly return to idle.")

	cat.play_evolution_pose()
	assert(String(cat.animation) == "evolution_pose", "play_evolution_pose must switch to the evolution pose animation.")
	cat._on_animation_finished()
	assert(String(cat.animation) == "evolution_pose", "Evolution pose must replay its celebration once before returning to idle.")
	cat._on_animation_finished()
	assert(String(cat.animation) == "idle", "Evolution pose must return to idle after its second celebration.")

	cat.free()

func _test_stage_mapping() -> void:
	var expectations := {
		1: MathCatStagesScript.Stage.KITTEN,
		4: MathCatStagesScript.Stage.KITTEN,
		5: MathCatStagesScript.Stage.BIG_CAT,
		8: MathCatStagesScript.Stage.BIG_CAT,
		9: MathCatStagesScript.Stage.TIGER,
		12: MathCatStagesScript.Stage.TIGER,
		13: MathCatStagesScript.Stage.NERD_CAT,
		20: MathCatStagesScript.Stage.NERD_CAT,
	}
	for grade in expectations:
		var stage: int = MathCatStagesScript.stage_for_grade(grade)
		assert(stage == expectations[grade], "Grade %d must map to stage %d." % [grade, expectations[grade]])

	assert(MathCatStagesScript.stage_name(MathCatStagesScript.Stage.KITTEN) == "Math Kitten", "Kitten stage name mismatch.")
	assert(MathCatStagesScript.stage_name(MathCatStagesScript.Stage.BIG_CAT) == "Math Cat", "Big Cat stage name mismatch.")
	assert(MathCatStagesScript.stage_name(MathCatStagesScript.Stage.TIGER) == "Math Tiger", "Tiger stage name mismatch.")
	assert(MathCatStagesScript.stage_name(MathCatStagesScript.Stage.NERD_CAT) == "Professor Whiskers", "Nerd Cat stage name mismatch.")

func _test_stage_frames_and_evolution() -> void:
	var cat = MathCatScene.instantiate()
	cat._ready()

	for stage in [MathCatStagesScript.Stage.KITTEN, MathCatStagesScript.Stage.BIG_CAT, MathCatStagesScript.Stage.TIGER, MathCatStagesScript.Stage.NERD_CAT]:
		cat.set_stage(stage)
		assert(cat.current_stage == stage, "set_stage must update current_stage.")
		assert(String(cat.animation) == "idle", "set_stage must return to idle without a celebration.")
		for animation_name in ["idle", "happy", "sad", "level_up", "game_over", "pause", "high_score", "evolution_pose"]:
			assert(cat.sprite_frames.has_animation(animation_name), "Stage %d must define the %s animation." % [stage, animation_name])

	cat.evolved.connect(_on_cat_evolved)
	cat.set_stage(MathCatStagesScript.Stage.KITTEN)
	cat.evolve_to(MathCatStagesScript.Stage.BIG_CAT)
	assert(cat.current_stage == MathCatStagesScript.Stage.BIG_CAT, "evolve_to must switch the stage.")
	assert(String(cat.animation) == "evolution_pose", "evolve_to must play the signature evolution pose.")
	assert(_captured_evolved_stage == MathCatStagesScript.Stage.BIG_CAT, "evolve_to must emit the evolved signal with the new stage.")

	cat.free()

func _on_cat_evolved(new_stage: int) -> void:
	_captured_evolved_stage = new_stage
