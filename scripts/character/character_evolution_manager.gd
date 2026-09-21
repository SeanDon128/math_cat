class_name CharacterEvolutionManager
extends Node

const MathCatStagesScript = preload("res://scripts/character/math_cat_stages.gd")

@export var math_cat_path: NodePath

@onready var math_cat: MathCat = get_node(math_cat_path)

func _ready() -> void:
	ProgressionManager.promoted.connect(_on_promoted)
	ProgressionManager.demoted.connect(_on_demoted)
	math_cat.set_stage(MathCatStagesScript.stage_for_grade(ProgressionManager.current_grade))

func _on_promoted(old_grade: int, new_grade: int) -> void:
	if GameManager.is_adventure_mode():
		if GameManager.is_adventure_boss() and new_grade >= int(GameManager.adventure_config.boss_victory_grade):
			math_cat.play_evolution_pose()
		else:
			math_cat.play_level_up()
		return
	var old_stage := MathCatStagesScript.stage_for_grade(old_grade)
	var new_stage := MathCatStagesScript.stage_for_grade(new_grade)
	if new_stage != old_stage:
		math_cat.evolve_to(new_stage)
	else:
		math_cat.play_level_up()

func _on_demoted(_old_grade: int, new_grade: int) -> void:
	if GameManager.is_adventure_mode():
		math_cat.play_sad()
		return
	math_cat.set_stage(MathCatStagesScript.stage_for_grade(new_grade))