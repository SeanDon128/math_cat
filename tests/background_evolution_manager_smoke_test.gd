extends Node

const GameScene = preload("res://scenes/game/game.tscn")

func _ready() -> void:
	GameManager.start_session()
	var game: Control = GameScene.instantiate()
	add_child(game)
	await get_tree().process_frame

	var material: ShaderMaterial = game.get_node("Background").material
	var evolution_manager: BackgroundEvolutionManager = game.get_node("BackgroundEvolutionManager")
	assert(material.get_shader_parameter("stage") == 0.0, "Grade 1 must use the minimal early-game background.")
	assert(material.get_shader_parameter("grade") == 1.0, "Grade 1 must initialize the background grade palette signal.")
	assert(material.get_shader_parameter("shooting_star_intensity") == 0.0, "Grade 1 must not show shooting stars.")
	assert(material.get_shader_parameter("star_density") == 0.0, "Grades 1-2 must use the original star density.")
	assert(evolution_manager.star_density_for_grade(2) == 0.0 and evolution_manager.star_density_for_grade(3) == 1.0, "Grade 3 must add the extra twinkling stars.")
	assert(evolution_manager.shooting_star_intensity_for_grade(6) == 0.0, "Grades before 7 must not show shooting stars.")
	assert(evolution_manager.shooting_star_intensity_for_grade(7) == 0.35, "Grades 7-8 must use occasional shooting stars.")
	assert(evolution_manager.shooting_star_intensity_for_grade(9) == 0.65, "Grades 9-12 must increase shooting star frequency.")
	assert(evolution_manager.shooting_star_intensity_for_grade(13) == 1.0, "Grade 13+ must use the highest shooting star frequency.")
	ProgressionManager.promoted.emit(2, 3)
	await get_tree().create_timer(2.4).timeout
	var early_to_kitten_stage: float = material.get_shader_parameter("stage")
	assert(early_to_kitten_stage > 0.0 and early_to_kitten_stage < 1.0, "Grade 3 must cross-fade from the early-game background.")
	await get_tree().create_timer(2.5).timeout
	assert(material.get_shader_parameter("stage") == 1.0, "Grades 3-4 must use the Kitten background.")
	assert(material.get_shader_parameter("star_density") == 1.0, "Grade 3 must show additional top-sky stars.")
	ProgressionManager.promoted.emit(4, 5)
	assert(AudioManager._music_players[0].playing and AudioManager._music_players[1].playing, "Grade 5 must cross-fade the old and new music tracks.")
	assert(AudioManager._music_fade != null and AudioManager._music_fade.is_valid(), "Grade 5 music change must use the evolution transition fade.")
	await get_tree().create_timer(2.4).timeout
	var blended_stage: float = material.get_shader_parameter("stage")
	assert(blended_stage > 1.0 and blended_stage < 2.0, "Grade 5 evolution must blend the Kitten and Big Cat themes.")
	await get_tree().create_timer(2.5).timeout
	assert(material.get_shader_parameter("stage") == 2.0, "Grade 5 must use the Big Cat background.")
	ProgressionManager.promoted.emit(6, 7)
	await get_tree().create_timer(2.5).timeout
	assert(material.get_shader_parameter("shooting_star_intensity") == 0.35, "Grade 7 must activate occasional shooting stars without requiring a visual-stage change.")
	ProgressionManager.promoted.emit(8, 9)
	await get_tree().create_timer(4.9).timeout
	assert(material.get_shader_parameter("stage") == 3.0, "Grade 9 must use the Tiger background.")
	assert(material.get_shader_parameter("shooting_star_intensity") == 0.65, "Grade 9 must increase shooting star frequency.")
	ProgressionManager.promoted.emit(10, 11)
	await get_tree().create_timer(2.5).timeout
	assert(material.get_shader_parameter("grade") == 11.0, "Grade 11 must select its dark background and green grid palette.")
	ProgressionManager.promoted.emit(11, 12)
	await get_tree().create_timer(2.5).timeout
	assert(material.get_shader_parameter("grade") == 12.0, "Grade 12 must select its light-blue Kitten-style palette.")
	ProgressionManager.promoted.emit(12, 13)
	await get_tree().create_timer(4.9).timeout
	assert(material.get_shader_parameter("stage") == 4.0, "Grade 13 must use the Nerd Cat background.")
	assert(material.get_shader_parameter("grade") == 13.0, "Grade 13 must retain the light-blue Grade 12 palette.")
	assert(material.get_shader_parameter("shooting_star_intensity") == 1.0, "Grade 13 must use the highest shooting star frequency.")
	var grade_thirteen_equations: Control = game.get_node("Grade13Equations")
	assert(grade_thirteen_equations.visible, "Grade 13 must show its background equations.")
	assert(grade_thirteen_equations.get_node("FermatEquation").text == "3987¹²+4365¹²=4472¹²", "Grade 13 must show the requested Fermat equation.")
	assert(grade_thirteen_equations.get_node("OmegaEquation").text == "Ω(t₀)>1", "Grade 13 must show the requested Omega equation.")
	ProgressionManager.demoted.emit(13, 12)
	await get_tree().create_timer(4.9).timeout
	assert(material.get_shader_parameter("stage") == 3.0, "Demotion must restore the matching background stage.")
	assert(material.get_shader_parameter("shooting_star_intensity") == 0.65, "Demotion must restore the matching shooting star frequency.")
	assert(not grade_thirteen_equations.visible, "Grade 12 must hide the Grade 13 background equations.")
	GameManager.start_session()
	assert(material.get_shader_parameter("stage") == 0.0, "A new session must reset the early-game background.")
	assert(material.get_shader_parameter("shooting_star_intensity") == 0.0, "A new session must disable shooting stars.")
	assert(material.get_shader_parameter("star_density") == 0.0, "A new session must restore the original star density.")

	print("BackgroundEvolutionManager smoke test passed.")
	get_tree().quit()