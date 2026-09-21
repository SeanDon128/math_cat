extends SceneTree

const AdvancedPlaceholderGeneratorScript = preload("res://scripts/generators/advanced_placeholder_generator.gd")

func _init() -> void:
	for grade in range(6, 14):
		_test_grade(grade)
	print("AdvancedPlaceholderGenerator smoke tests passed.")
	quit()

func _test_grade(grade: int) -> void:
	var generator = AdvancedPlaceholderGeneratorScript.new(grade)
	var expected_topic := "grade_%d_practice" % grade
	var lowest_count := 0
	var highest_count := 0
	var middle_count := 0

	for question_index in range(200):
		var question = generator.next_question()
		assert(question.grade == grade, "Question grade must match the requested grade.")
		assert(question.topic == expected_topic, "Question topic must be tagged for its grade.")
		assert(question.choices.size() == 4, "Every question needs four choices.")
		assert(question.choices.has(question.correct_answer), "Choices must include the correct answer.")

		var unique_choices: Array[String] = []
		for choice in question.choices:
			if not unique_choices.has(choice):
				unique_choices.append(choice)
		assert(unique_choices.size() == 4, "Choices must be unique.")

		var factors: PackedStringArray = question.question_text.trim_suffix(" =").split(" × ")
		var first_factor := int(factors[0])
		var second_factor := int(factors[1])
		var correct_value := int(question.correct_answer)
		assert(first_factor * second_factor == correct_value, "The correct answer must be the product of the two factors.")

		var lower_choice_count := 0
		for choice in question.choices:
			if int(choice) < correct_value:
				lower_choice_count += 1
		if lower_choice_count == 0:
			lowest_count += 1
		elif lower_choice_count == 3:
			highest_count += 1
		else:
			middle_count += 1

	assert(lowest_count == 50, "The correct answer must be lowest in exactly 50 of 200 sets for Grade %d." % grade)
	assert(highest_count == 50, "The correct answer must be highest in exactly 50 of 200 sets for Grade %d." % grade)
	assert(middle_count == 100, "The correct answer must be a middle value in exactly 100 of 200 sets for Grade %d." % grade)
