class_name QuestionChoiceBuilder
extends RefCounted

static func build(correct_value: int, candidates: Array[int]) -> Array[String]:
    var choices: Array[String] = [str(correct_value)]

    for candidate in candidates:
        if candidate >= 0 and not choices.has(str(candidate)):
            choices.append(str(candidate))
        if choices.size() == 4:
            break

    var fallback_offset := 1
    while choices.size() < 4:
        var candidate := correct_value + fallback_offset
        if not choices.has(str(candidate)):
            choices.append(str(candidate))
        fallback_offset += 1

    choices.shuffle()
    return choices
