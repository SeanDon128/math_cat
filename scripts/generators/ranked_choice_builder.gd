class_name RankedChoiceBuilder
extends RefCounted

static func build(correct_value: int, answer_rank: int) -> Array[String]:
    var choices: Array[String] = [str(correct_value)]

    for offset in _get_distractor_offsets(answer_rank):
        choices.append(str(correct_value + offset))

    choices.shuffle()
    return choices

static func build_zero_variant(variant: int) -> Array[String]:
    var choices: Array[String] = ["0", "1", "2"]
    choices.append(str(3 if variant == 0 else 4))
    choices.shuffle()
    return choices

static func _get_distractor_offsets(answer_rank: int) -> Array[int]:
    match answer_rank:
        0:
            return [1, 2, 3]
        1:
            return [-1, 1, 2]
        2:
            return [-2, -1, 1]
        _:
            return [-3, -2, -1]
