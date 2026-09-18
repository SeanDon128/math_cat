class_name MathCatStages
extends RefCounted

## Maps a grade number to the character's current evolution stage.

enum Stage { KITTEN, BIG_CAT, TIGER, NERD_CAT }

const _STAGE_NAMES := {
	Stage.KITTEN: "Math Kitten",
	Stage.BIG_CAT: "Math Cat",
	Stage.TIGER: "Math Tiger",
	Stage.NERD_CAT: "Professor Whiskers",
}

static func stage_for_grade(grade: int) -> Stage:
	if grade <= 4:
		return Stage.KITTEN
	if grade <= 8:
		return Stage.BIG_CAT
	if grade <= 12:
		return Stage.TIGER
	return Stage.NERD_CAT

static func stage_name(stage: Stage) -> String:
	return _STAGE_NAMES.get(stage, "Math Cat")
