class_name BackgroundEvolutionManager
extends Node

const EVOLUTION_TRANSITION_SECONDS := 4.8
const ATMOSPHERE_TRANSITION_SECONDS := 2.4

enum VisualStage { EARLY, KITTEN, BIG_CAT, TIGER, NERD_CAT }

@export var background_path: NodePath
@export var grade_thirteen_equations_path: NodePath

@onready var background: ColorRect = get_node(background_path)
@onready var grade_thirteen_equations: Control = get_node(grade_thirteen_equations_path)

var _equation_base_positions: Array[Vector2] = []

func _ready() -> void:
	for equation in grade_thirteen_equations.get_children():
		_equation_base_positions.append(equation.position)
	ProgressionManager.promoted.connect(_on_grade_changed)
	ProgressionManager.demoted.connect(_on_grade_changed)
	GameManager.session_started.connect(_on_session_started)
	_apply_grade(ProgressionManager.current_grade)

func _on_grade_changed(_old_grade: int, new_grade: int) -> void:
	if GameManager.is_adventure_mode():
		return
	var old_stage := visual_stage_for_grade(_old_grade)
	var new_stage := visual_stage_for_grade(new_grade)
	if new_stage != old_stage:
		_transition_shader_parameter("stage", float(new_stage))
	_transition_shader_parameter("shooting_star_intensity", shooting_star_intensity_for_grade(new_grade))
	_transition_shader_parameter("star_density", star_density_for_grade(new_grade))
	_transition_shader_parameter("grade", float(new_grade))
	_set_grade_thirteen_equations_visible(new_grade >= 13)

func _on_session_started() -> void:
	_apply_grade(ProgressionManager.current_grade)

func _apply_grade(grade: int) -> void:
	if GameManager.is_adventure_boss():
		grade = 12
	_set_stage(visual_stage_for_grade(grade))
	_set_shader_parameter(shooting_star_intensity_for_grade(grade), "shooting_star_intensity")
	_set_shader_parameter(star_density_for_grade(grade), "star_density")
	_set_shader_parameter(float(grade), "grade")
	_set_grade_thirteen_equations_visible(grade >= 13)

func _process(_delta: float) -> void:
	if not grade_thirteen_equations.visible:
		return
	for equation_index in grade_thirteen_equations.get_child_count():
		var equation := grade_thirteen_equations.get_child(equation_index) as Control
		equation.position = _equation_base_positions[equation_index] + Vector2(0.0, sin(Time.get_ticks_msec() * 0.0007 + equation_index * 2.4) * 5.0)

func _set_grade_thirteen_equations_visible(should_show: bool) -> void:
	grade_thirteen_equations.visible = should_show
	grade_thirteen_equations.modulate.a = 1.0 if should_show else 0.0

func _transition_shader_parameter(parameter: StringName, target_value: float) -> void:
	var material := background.material as ShaderMaterial
	if material == null:
		return
	var current_value: float = material.get_shader_parameter(parameter)
	if is_equal_approx(current_value, target_value):
		return
	var transition := create_tween()
	transition.tween_method(_set_shader_parameter.bind(parameter), current_value, target_value, transition_seconds_for_parameter(parameter, target_value)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_stage(new_stage: float) -> void:
	_set_shader_parameter(new_stage, "stage")

func _set_shader_parameter(value: float, parameter: StringName) -> void:
	var material := background.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter(parameter, value)

func shooting_star_intensity_for_grade(grade: int) -> float:
	if grade < 7:
		return 0.0
	if grade <= 8:
		return 0.35
	if grade <= 12:
		return 0.65
	return 1.0

func star_density_for_grade(grade: int) -> float:
	return 1.0 if grade >= 3 else 0.0

func transition_seconds_for_parameter(parameter: StringName, target_value: float) -> float:
	if parameter == "stage":
		return EVOLUTION_TRANSITION_SECONDS
	return ATMOSPHERE_TRANSITION_SECONDS

func visual_stage_for_grade(grade: int) -> VisualStage:
	if grade <= 2:
		return VisualStage.EARLY
	if grade <= 4:
		return VisualStage.KITTEN
	if grade <= 8:
		return VisualStage.BIG_CAT
	if grade <= 12:
		return VisualStage.TIGER
	return VisualStage.NERD_CAT