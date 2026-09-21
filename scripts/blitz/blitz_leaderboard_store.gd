extends Node

signal storage_failed(message: String)

const SAVE_PATH := "user://math_cat_blitz_scores.json"
const VERSION := 1
const BOARD_SIZE := 10

var storage_path := SAVE_PATH
var last_error := ""
var _boards: Dictionary = {}
var _loaded := false

func _ready() -> void:
    reload()

func reload() -> bool:
    last_error = ""
    _loaded = false
    if not FileAccess.file_exists(storage_path):
        _boards = _empty_boards()
        _loaded = true
        return true
    var file := FileAccess.open(storage_path, FileAccess.READ)
    if file == null:
        return _fail("Could not read Blitz scores: %s." % error_string(FileAccess.get_open_error()))
    var text := file.get_as_text()
    var read_error := file.get_error()
    file.close()
    if read_error != OK and read_error != ERR_FILE_EOF:
        return _fail("Could not read Blitz scores: %s." % error_string(read_error))
    var json := JSON.new()
    if json.parse(text) != OK:
        return _fail("Blitz scores are damaged. The original file has been preserved.")
    if not _valid_data(json.data):
        return _fail("Blitz scores have an invalid or unsupported format. The original file has been preserved.")
    _boards = json.data.boards.duplicate(true)
    for entries in _boards.values():
        for entry in entries:
            entry.score = int(entry.score)
    _loaded = true
    return true

func board(grade: int) -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
    if grade < 1 or grade > 13:
        _fail("Blitz grade must be between 1 and 13.")
        return entries
    if _loaded:
        for entry in _boards[str(grade)]:
            entries.append(entry.duplicate(true))
    return entries

func qualifying_rank(grade: int, score: int) -> int:
    if grade < 1 or grade > 13:
        _fail("Blitz grade must be between 1 and 13.")
        return -1
    if not _loaded or score <= 0:
        return -1
    var entries: Array = _boards[str(grade)]
    var rank := 0
    while rank < entries.size() and int(entries[rank].score) >= score:
        rank += 1
    return rank if rank < BOARD_SIZE else -1

func submit(grade: int, score: int, initials: String) -> int:
    if grade < 1 or grade > 13:
        _fail("Blitz grade must be between 1 and 13.")
        return -1
    if score <= 0 or score > 2147483647:
        _fail("Only positive Blitz scores up to 2147483647 can be saved.")
        return -1
    var normalized := initials.to_upper()
    if not valid_initials(normalized):
        _fail("Enter exactly three letters, A-Z.")
        return -1
    if not reload():
        return -1
    var rank := qualifying_rank(grade, score)
    if rank < 0:
        _fail("This score does not qualify for the selected grade's top 10.")
        return -1
    var updated := _boards.duplicate(true)
    var entries: Array = updated[str(grade)]
    entries.insert(rank, {"initials": normalized, "score": score})
    if entries.size() > BOARD_SIZE:
        entries.resize(BOARD_SIZE)
    if not _save(updated):
        return -1
    _boards = updated
    return rank

func valid_initials(initials: String) -> bool:
    if initials.length() != 3:
        return false
    for index in 3:
        var letter := initials.unicode_at(index)
        if letter < 65 or letter > 90:
            return false
    return true

func replace_for_debugging(boards: Dictionary) -> bool:
    if not OS.is_debug_build():
        return _fail("Debug editing is unavailable in release builds.")
    if not _valid_data({"version": VERSION, "boards": boards}):
        return _fail("Each board needs at most 10 positive scores, sorted highest first, with three A-Z initials.")
    if not _save(boards):
        return false
    _boards = boards.duplicate(true)
    _loaded = true
    return true

func _save(boards: Dictionary) -> bool:
    var temporary_path := storage_path + ".tmp"
    var file := FileAccess.open(temporary_path, FileAccess.WRITE)
    if file == null:
        return _fail("Could not save Blitz scores: %s. Retry Save or Skip." % error_string(FileAccess.get_open_error()))
    file.store_string(JSON.stringify({"version": VERSION, "boards": boards}))
    file.flush()
    var write_error := file.get_error()
    file.close()
    if write_error != OK:
        _remove_temporary(temporary_path)
        return _fail("Could not write Blitz scores: %s. Retry Save or Skip." % error_string(write_error))
    var replace_error := DirAccess.rename_absolute(temporary_path, storage_path)
    if replace_error != OK:
        _remove_temporary(temporary_path)
        return _fail("Could not replace Blitz scores: %s. Retry Save or Skip." % error_string(replace_error))
    last_error = ""
    return true

func _remove_temporary(path: String) -> void:
    var error := DirAccess.remove_absolute(path)
    if error != OK:
        push_warning("Could not remove temporary Blitz save: %s." % error_string(error))

func _valid_data(value: Variant) -> bool:
    if not value is Dictionary or value.get("version") != VERSION or not value.get("boards") is Dictionary:
        return false
    if value.boards.size() != 13:
        return false
    for grade in range(1, 14):
        var entries: Variant = value.boards.get(str(grade))
        if not entries is Array or entries.size() > BOARD_SIZE:
            return false
        var previous_score := 9223372036854775807
        for entry in entries:
            if not entry is Dictionary or not entry.get("initials") is String or not valid_initials(entry.initials):
                return false
            var points: Variant = entry.get("score")
            if not (points is int or points is float):
                return false
            if not is_finite(float(points)) or float(points) != floorf(float(points)) or points <= 0 or points > 2147483647:
                return false
            if int(points) > previous_score:
                return false
            previous_score = int(points)
    return true

func _empty_boards() -> Dictionary:
    var boards: Dictionary = {}
    for grade in range(1, 14):
        boards[str(grade)] = []
    return boards

func _fail(message: String) -> bool:
    last_error = message
    push_warning(message)
    storage_failed.emit(message)
    return false
