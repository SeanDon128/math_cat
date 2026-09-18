extends Node

const StoreScript = preload("res://autoload/blitz_leaderboard.gd")
const DuelStoreScript = preload("res://autoload/blitz_duel_leaderboard.gd")
const TEST_PATH := "user://blitz-tests/leaderboard.json"

func _ready() -> void:
    assert(DirAccess.make_dir_recursive_absolute("user://blitz-tests") == OK)
    if "--persistence-write" in OS.get_cmdline_user_args() or "--persistence-read" in OS.get_cmdline_user_args():
        _test_cross_process_persistence()
        get_tree().quit()
        return
    _remove(TEST_PATH)
    var store = DuelStoreScript.new() if "--duel" in OS.get_cmdline_user_args() else StoreScript.new()
    store.storage_path = TEST_PATH
    assert(store.reload())
    _test_ranking(store)
    _test_validation(store)
    _test_failures(store)
    _test_store_isolation()
    store.free()
    _remove(TEST_PATH)
    print("Blitz leaderboard smoke tests passed.")
    get_tree().quit()

func _test_cross_process_persistence() -> void:
    var store = DuelStoreScript.new() if "--duel" in OS.get_cmdline_user_args() else StoreScript.new()
    store.storage_path = "user://blitz-tests/persistence-duel.json" if "--duel" in OS.get_cmdline_user_args() else "user://blitz-tests/persistence.json"
    if "--persistence-write" in OS.get_cmdline_user_args():
        _remove(store.storage_path)
        assert(store.reload())
        assert(store.submit(1, 15, "ONE") == 0)
        assert(store.submit(1, 15, "TWO") == 1)
        assert(store.submit(13, 7, "CAT") == 0)
    else:
        assert(FileAccess.file_exists(store.storage_path))
        assert(store.reload())
        assert(store.board(1)[0].initials == "ONE" and store.board(1)[1].initials == "TWO")
        assert(store.board(13)[0].score == 7 and store.board(2).is_empty())
        _remove(store.storage_path)
    store.free()
    print("Blitz cross-process persistence smoke tests passed.")

func _test_ranking(store: Node) -> void:
    assert(store.board(1).is_empty())
    assert(store.qualifying_rank(1, 1) == 0)
    assert(store.qualifying_rank(1, 0) == -1 and store.qualifying_rank(1, -1) == -1)
    assert(store.submit(1, 20, "abc") == 0)
    assert(store.submit(1, 20, "XYZ") == 1, "Earlier entries win ties.")
    assert(store.submit(1, 21, "ABC") == 0, "Repeated initials are independent entries.")
    for points in range(19, 12, -1):
        assert(store.submit(1, points, "AAA") >= 0)
    assert(store.board(1).size() == 10)
    assert(store.qualifying_rank(1, 13) == -1, "A tie at the cutoff must not qualify.")
    assert(store.submit(1, 25, "TOP") == 0)
    assert(store.board(1).size() == 10 and int(store.board(1)[9].score) == 14)
    assert(store.board(2).is_empty(), "Grades have independent boards.")
    assert(store.submit(13, 1, "CAT") == 0)
    var loaded = StoreScript.new()
    loaded.storage_path = TEST_PATH
    assert(loaded.reload())
    assert(loaded.board(1) == store.board(1) and loaded.board(13) == store.board(13))
    var copy: Array[Dictionary] = loaded.board(1)
    copy[0].score = 999
    assert(int(loaded.board(1)[0].score) == 25, "Callers cannot mutate saved boards.")
    loaded.free()

func _test_store_isolation() -> void:
    var solo = StoreScript.new()
    var duel = DuelStoreScript.new()
    assert(solo.storage_path != duel.storage_path)
    solo.storage_path = "user://blitz-tests/isolation-solo.json"
    duel.storage_path = "user://blitz-tests/isolation-duel.json"
    _remove(solo.storage_path)
    _remove(duel.storage_path)
    assert(solo.reload() and duel.reload())
    for grade in range(1, 14):
        assert(solo.submit(grade, grade, "ONE") == 0)
        assert(duel.submit(grade, grade + 20, "TWO") == 0)
        assert(solo.board(grade)[0].score == grade)
    var original := FileAccess.get_file_as_string(solo.storage_path)
    _write(duel.storage_path, "{damaged")
    assert(not duel.reload())
    assert(solo.reload() and solo.board(1)[0].initials == "ONE")
    assert(FileAccess.get_file_as_string(solo.storage_path) == original)
    _remove(solo.storage_path)
    _remove(duel.storage_path)
    solo.free()
    duel.free()

func _test_validation(store: Node) -> void:
    var failures: Array[String] = []
    var callback := func(message: String): failures.append(message)
    store.storage_failed.connect(callback)
    for initials in ["", "AB", "ABCD", "A1B", "A B", "!!!"]:
        assert(store.submit(1, 100, initials) == -1)
    assert(failures.size() == 6, "Invalid input must surface an explicit error.")
    assert(store.submit(0, 100, "ABC") == -1)
    assert(store.submit(14, 100, "ABC") == -1)
    assert(store.submit(1, 0, "ABC") == -1)
    var valid: Dictionary = {"version": 1, "boards": store._empty_boards()}
    assert(store._valid_data(valid))
    for points in [-1, 0, 1.5, "20", true]:
        var data := valid.duplicate(true)
        data.boards["1"] = [{"initials": "ABC", "score": points}]
        assert(not store._valid_data(data))
    valid.boards["1"] = [{"initials": "ABC", "score": 1}, {"initials": "DEF", "score": 2}]
    assert(not store._valid_data(valid), "Out-of-order boards are invalid, not silently reordered.")
    store.storage_failed.disconnect(callback)

func _test_failures(store: Node) -> void:
    var original := FileAccess.get_file_as_string(TEST_PATH)
    _write(TEST_PATH, "{damaged")
    assert(not store.reload() and not store.last_error.is_empty())
    assert(store.submit(1, 100, "ABC") == -1)
    assert(FileAccess.get_file_as_string(TEST_PATH) == "{damaged", "Damaged saves must not be overwritten.")
    _write(TEST_PATH, JSON.stringify({"version": 99, "boards": {}}))
    assert(not store.reload(), "Unsupported versions must report an error.")
    _write(TEST_PATH, original)
    assert(store.reload())

    store.storage_path = "user://blitz-tests/missing-parent/scores.json"
    assert(store.reload())
    assert(store.submit(1, 1, "ABC") == -1 and not store.last_error.is_empty())
    assert(store.board(1).is_empty(), "Failed saves must not insert in-memory scores.")
    assert(DirAccess.make_dir_recursive_absolute("user://blitz-tests/missing-parent") == OK)
    assert(store.submit(1, 1, "ABC") == 0, "Retry must succeed once storage is writable.")
    assert(store.board(1).size() == 1, "Retry must not duplicate the entry.")
    _remove(store.storage_path)
    assert(DirAccess.remove_absolute("user://blitz-tests/missing-parent") == OK)

    store.storage_path = "user://blitz-tests/directory.json"
    assert(DirAccess.make_dir_recursive_absolute(store.storage_path) == OK)
    assert(store.submit(1, 1, "ABC") == -1, "A failed replacement must report an error.")
    assert(DirAccess.dir_exists_absolute(store.storage_path), "Failed replacement must preserve the original target.")
    assert(not FileAccess.file_exists(store.storage_path + ".tmp"))
    assert(DirAccess.remove_absolute(store.storage_path) == OK)
    assert(FileAccess.get_file_as_string(TEST_PATH) == original)

func _write(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    assert(file != null)
    file.store_string(text)
    file.close()

func _remove(path: String) -> void:
    if FileAccess.file_exists(path):
        assert(DirAccess.remove_absolute(path) == OK)
