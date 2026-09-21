extends Node

func _ready() -> void:
    AudioManager.stop_music()
    AudioManager._play_grade_music(12)
    assert(AudioManager._current_music_name == AudioManager.MUSIC_FINAL_LEVEL_THEME, "Grade 12 must select the final-level theme.")
    assert(AudioManager._music_player.get_playback_position() < 0.25, "Grade 12 music must start from the beginning.")

    AudioManager._music_player.seek(AudioManager.GRADE_12_LOOP_END_SECONDS + 0.1)
    AudioManager._process(0.0)
    var looped_position := AudioManager._music_player.get_playback_position()
    assert(absf(looped_position - AudioManager.GRADE_12_LOOP_START_SECONDS) < 0.05, "Grade 12 music must loop to its custom start point; got %.3f seconds." % looped_position)

    AudioManager.stop_music()
    AudioManager._play_grade_music(13)
    assert(AudioManager._current_music_name == AudioManager.MUSIC_NERD_CAT_THEME, "Grade 13 must select the Nerd Cat theme.")
    assert(AudioManager._music_player.get_playback_position() < 0.25, "Grade 13 music must start from the beginning.")

    AudioManager._music_player.seek(AudioManager.GRADE_13_LOOP_END_SECONDS + 0.1)
    AudioManager._process(0.0)
    looped_position = AudioManager._music_player.get_playback_position()
    assert(absf(looped_position - AudioManager.GRADE_13_LOOP_START_SECONDS) < 0.05, "Grade 13 music must loop to its custom start point; got %.3f seconds." % looped_position)

    AudioManager._current_music_name = AudioManager.MUSIC_MATH_KITTEN_THEME
    AudioManager._music_player.seek(AudioManager.GRADE_13_LOOP_END_SECONDS + 0.1)
    AudioManager._process(0.0)
    assert(AudioManager._music_player.get_playback_position() > AudioManager.GRADE_13_LOOP_END_SECONDS, "Other grade music must not use the custom loop points.")

    AudioManager.stop_music()
    print("Grade 12 and Grade 13 music loop smoke test passed.")
    get_tree().quit()