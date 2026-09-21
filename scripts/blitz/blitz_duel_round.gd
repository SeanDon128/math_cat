extends RefCounted

var scores: Array[int] = [0, 0]
var correct: Array[int] = [0, 0]
var incorrect: Array[int] = [0, 0]
var attempted: Array[bool] = [false, false]
var selections: Array[int] = [-1, -1]
var question_id := 0
var ready := false
var closed := true
var _correct_index := -1

func present(question: QuestionData) -> int:
    question_id += 1
    attempted.assign([false, false])
    selections.assign([-1, -1])
    ready = false
    closed = false
    _correct_index = question.choices.find(question.correct_answer)
    if _correct_index < 0 or question.choices.size() != 4:
        push_error("Two-player Blitz requires four choices including the correct answer.")
        closed = true
    return question_id

func submit(player: int, index: int, expected_question: int) -> Dictionary:
    if player < 0 or player > 1 or index < 0 or index > 3:
        push_error("Invalid two-player Blitz answer.")
        return {}
    if expected_question != question_id or not ready or closed or attempted[player]:
        return {}
    attempted[player] = true
    selections[player] = index
    var is_correct := index == _correct_index
    scores[player] += 1 if is_correct else -1
    if is_correct:
        correct[player] += 1
    else:
        incorrect[player] += 1
    closed = is_correct or (attempted[0] and attempted[1])
    if closed:
        ready = false
    return {"correct": is_correct, "closed": closed}

func snapshot(grade: int) -> Dictionary:
    var winner := -1 if scores[0] == scores[1] else (0 if scores[0] > scores[1] else 1)
    var players: Array[Dictionary] = []
    for player in 2:
        players.append({"score": scores[player], "correct": correct[player], "incorrect": incorrect[player]})
    return {
        "two_player": true, "grade": grade, "winner": winner,
        "score": maxi(scores[0], scores[1]), "players": players,
    }
