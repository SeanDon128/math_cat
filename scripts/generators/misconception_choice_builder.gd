class_name MisconceptionChoiceBuilder
extends RefCounted

static func build(correct_value: int, candidates: Array[int], variant: int) -> Array[String]:
    var available: Array[int] = []
    for candidate in candidates:
        if candidate >= 0 and candidate != correct_value and not available.has(candidate):
            available.append(candidate)

    var fallback_value := correct_value + 10 + variant * 10
    while available.size() < 6:
        if fallback_value != correct_value and not available.has(fallback_value):
            available.append(fallback_value)
        fallback_value += 1

    var choices: Array[String] = [str(correct_value)]
    for candidate_offset in range(3):
        var candidate_index := posmod(variant + candidate_offset, available.size())
        choices.append(str(available[candidate_index]))
    choices.shuffle()
    return choices