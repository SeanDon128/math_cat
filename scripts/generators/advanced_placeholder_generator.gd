class_name AdvancedPlaceholderGenerator
extends RefCounted

## Placeholder practice content for Grades 6-13 (Big Cat / Tiger / Nerd Cat tiers).
## Multiplication with operand ranges that widen by grade; swap in real per-grade
## curricula later without touching QuestionBank's routing contract.

const RankedChoiceBuilderScript = preload("res://scripts/generators/ranked_choice_builder.gd")

var grade: int
var _unused_problems: Array[Vector3i] = []

func _init(target_grade: int) -> void:
	grade = target_grade

func next_question() -> QuestionData:
	if grade == 10 and randi_range(0, 7) == 0:
		return _next_pi_question()

	if _unused_problems.is_empty():
		_refill_problem_deck()

	var problem: Vector3i = _unused_problems.pop_back()
	var correct_answer := problem.x * problem.y

	var question := QuestionData.new()
	question.grade = grade
	question.topic = "grade_%d_practice" % grade
	question.question_text = "%d × %d =" % [problem.x, problem.y]
	question.correct_answer = str(correct_answer)
	question.choices = RankedChoiceBuilderScript.build(correct_answer, problem.z)
	return question

func _next_pi_question() -> QuestionData:
	var question := QuestionData.new()
	question.grade = grade
	question.topic = "circle_pi"
	question.uses_pi = true
	question.question_text = "What is pi rounded to the nearest hundredth?"
	question.correct_answer = "3.14"
	question.choices = ["3.04", "3.14", "3.24", "3.41"]
	question.choices.shuffle()
	return question

func _refill_problem_deck() -> void:
	var first_base := 10 * (grade - 4)
	var second_base := grade - 3
	var prompt_index := 0
	for first_offset in range(20):
		for second_offset in range(10):
			var first := first_base + first_offset
			var second := second_base + second_offset
			_unused_problems.append(Vector3i(first, second, prompt_index % 4))
			prompt_index += 1

	_unused_problems.shuffle()
