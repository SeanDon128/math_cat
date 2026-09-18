class_name MathCatQuestionBank
extends Node

const AdditionGeneratorScript = preload("res://scripts/generators/addition_generator.gd")
const SubtractionGeneratorScript = preload("res://scripts/generators/subtraction_generator.gd")
const MultiplicationGeneratorScript = preload("res://scripts/generators/multiplication_generator.gd")
const MultiDigitAddSubGeneratorScript = preload("res://scripts/generators/multi_digit_add_sub_generator.gd")
const MultiDigitMultiplicationGeneratorScript = preload("res://scripts/generators/multi_digit_multiplication_generator.gd")
const LongDivisionGeneratorScript = preload("res://scripts/generators/long_division_generator.gd")
const GradeFiveGeneratorScript = preload("res://scripts/generators/grade_five_generator.gd")
const GradeSixGeneratorScript = preload("res://scripts/generators/grade_six_generator.gd")
const GradeSevenGeneratorScript = preload("res://scripts/generators/grade_seven_generator.gd")
const GradeEightGeneratorScript = preload("res://scripts/generators/grade_eight_generator.gd")
const GradeNineGeneratorScript = preload("res://scripts/generators/grade_nine_generator.gd")
const GradeTenGeneratorScript = preload("res://scripts/generators/grade_ten_generator.gd")
const GradeElevenGeneratorScript = preload("res://scripts/generators/grade_eleven_generator.gd")
const GradeTwelveGeneratorScript = preload("res://scripts/generators/grade_twelve_generator.gd")
const GradeThirteenGeneratorScript = preload("res://scripts/generators/grade_thirteen_generator.gd")
const AdvancedPlaceholderGeneratorScript = preload("res://scripts/generators/advanced_placeholder_generator.gd")

var addition_generator = AdditionGeneratorScript.new()
var subtraction_generator = SubtractionGeneratorScript.new()
var multiplication_generator = MultiplicationGeneratorScript.new()
var multi_digit_add_sub_generator = MultiDigitAddSubGeneratorScript.new()
var multi_digit_multiplication_generator = MultiDigitMultiplicationGeneratorScript.new()
var long_division_generator = LongDivisionGeneratorScript.new()
var grade_five_generator = GradeFiveGeneratorScript.new()
var grade_six_generator = GradeSixGeneratorScript.new()
var grade_seven_generator = GradeSevenGeneratorScript.new()
var grade_eight_generator = GradeEightGeneratorScript.new()
var grade_nine_generator = GradeNineGeneratorScript.new()
var grade_ten_generator = GradeTenGeneratorScript.new()
var grade_eleven_generator = GradeElevenGeneratorScript.new()
var grade_twelve_generator = GradeTwelveGeneratorScript.new()
var grade_thirteen_generator = GradeThirteenGeneratorScript.new()
var _advanced_placeholder_generators: Dictionary = {}

func get_question(grade: int) -> QuestionData:
    if grade == 1:
        return addition_generator.next_question()
    if grade == 2:
        return subtraction_generator.next_question()
    if grade == 3:
        return multiplication_generator.next_question()
    if grade == 4:
        return long_division_generator.next_question()
    if grade == 5:
        return grade_five_generator.next_question()
    if grade == 6:
        return grade_six_generator.next_question()
    if grade == 7:
        return grade_seven_generator.next_question()
    if grade == 8:
        return grade_eight_generator.next_question()
    if grade == 9:
        return grade_nine_generator.next_question()
    if grade == 10:
        return grade_ten_generator.next_question()
    if grade == 11:
        return grade_eleven_generator.next_question()
    if grade == 12:
        return grade_twelve_generator.next_question()
    if grade == 13:
        return grade_thirteen_generator.next_question()
    if grade >= 6:
        return _get_advanced_placeholder_generator(grade).next_question()

    return addition_generator.next_question()

func _get_advanced_placeholder_generator(grade: int) -> AdvancedPlaceholderGenerator:
    if not _advanced_placeholder_generators.has(grade):
        _advanced_placeholder_generators[grade] = AdvancedPlaceholderGeneratorScript.new(grade)
    return _advanced_placeholder_generators[grade]
