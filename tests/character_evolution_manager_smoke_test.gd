extends Node

const MathCatScene = preload("res://scenes/characters/math_cat.tscn")
const CharacterEvolutionManagerScript = preload("res://scripts/character/character_evolution_manager.gd")
const MathCatStagesScript = preload("res://scripts/character/math_cat_stages.gd")

func _ready() -> void:
	var cat: MathCat = MathCatScene.instantiate()
	cat.name = "MathCat"
	add_child(cat)

	var evolution_manager: CharacterEvolutionManager = CharacterEvolutionManagerScript.new()
	evolution_manager.math_cat_path = NodePath("../MathCat")
	add_child(evolution_manager)
	await get_tree().process_frame

	ProgressionManager.promoted.emit(1, 2)
	assert(String(cat.animation) == "level_up", "A promotion within a stage must play level_up.")
	assert(cat.current_stage == MathCatStagesScript.Stage.KITTEN, "A Grade 1 to 2 promotion must keep the Kitten stage.")

	ProgressionManager.promoted.emit(4, 5)
	assert(String(cat.animation) == "evolution_pose", "A stage-crossing promotion must play evolution_pose.")
	assert(cat.current_stage == MathCatStagesScript.Stage.BIG_CAT, "Grade 5 must evolve to Big Cat.")

	ProgressionManager.demoted.emit(5, 4)
	assert(String(cat.animation) == "idle", "A demotion must settle the new stage at idle.")
	assert(cat.current_stage == MathCatStagesScript.Stage.KITTEN, "Grade 4 must return to Kitten.")

	print("CharacterEvolutionManager smoke test passed.")
	get_tree().quit()