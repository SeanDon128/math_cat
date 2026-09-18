extends Node

signal sfx_played(sfx_name: String)

const SFX_CORRECT_ANSWER := "correct_answer"
const SFX_INCORRECT_ANSWER := "incorrect_answer"
const SFX_LEVEL_UP := "level_up"
const SFX_DEMOTION := "demotion"
const SFX_UI_CONFIRM := "ui_confirm"
const SFX_PAUSE := "pause"
const SFX_UNPAUSE := "unpause"
const MUSIC_MATH_KITTEN_THEME := "mathkitten_theme"
const MUSIC_MATH_CAT_THEME := "mathcat_theme"
const MUSIC_MATH_TIGER_THEME := "mathtiger_theme"
const MUSIC_GRADE_11_THEME := "grade11_theme"
const MUSIC_FINAL_LEVEL_THEME := "final_level_theme"
const MUSIC_NERD_CAT_THEME := "nerdcat_theme"
const MUSIC_VICTORY_THEME := "victory_theme"

const SAMPLE_RATE := 22050.0
const PLAYER_POOL_SIZE := 5
const MUSIC_TRANSITION_SECONDS := 1.0
const MUSIC_SILENT_DB := -80.0
const MUSIC_BASELINE_DB := -14.0
const GRADE_12_LOOP_START_SECONDS := 6.933
const GRADE_12_LOOP_END_SECONDS := 54.340
const GRADE_13_LOOP_START_SECONDS := 21.043
const GRADE_13_LOOP_END_SECONDS := 78.556
const MathCatStagesScript = preload("res://scripts/character/math_cat_stages.gd")

const MUSIC_TRACKS := {
    MUSIC_MATH_KITTEN_THEME: "res://audio/music/kitten_theme.ogg",
    MUSIC_MATH_CAT_THEME: "res://audio/music/bigcat_theme.ogg",
    MUSIC_MATH_TIGER_THEME: "res://audio/music/tiger_theme.ogg",
    MUSIC_GRADE_11_THEME: "res://audio/music/satcat_theme.ogg",
    MUSIC_FINAL_LEVEL_THEME: "res://audio/music/final_level_theme.ogg",
    MUSIC_NERD_CAT_THEME: "res://audio/music/nerdcat_theme.ogg",
    MUSIC_VICTORY_THEME: "res://audio/music/victory_theme.ogg",
}

var _players: Array[AudioStreamPlayer] = []
var _next_player_index := 0
var _music_player: AudioStreamPlayer
var _music_players: Array[AudioStreamPlayer] = []
var _active_music_player_index := -1
var _current_music_name := ""
var _music_fade: Tween
var _music_volume_db := 0.0
var _sfx_volume_db := 0.0

func _ready() -> void:
    for player_index in PLAYER_POOL_SIZE:
        var player := AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        _players.append(player)

    for music_player_index in 2:
        var music_player := AudioStreamPlayer.new()
        music_player.bus = "Music"
        music_player.volume_db = MUSIC_SILENT_DB
        add_child(music_player)
        _music_players.append(music_player)
    _music_player = _music_players[0]
    ProfileManager.apply_audio_settings()
    set_music_volume(ProfileManager.music_volume())
    set_sfx_volume(ProfileManager.sfx_volume())

    GameManager.answer_registered.connect(_on_answer_registered)
    ProgressionManager.promoted.connect(_on_promoted)
    ProgressionManager.demoted.connect(_on_demoted)
    GameManager.session_started.connect(_on_session_started)
    GameManager.session_ended.connect(_on_session_ended)

func _process(_delta: float) -> void:
    if not _music_player.playing or _music_player.stream_paused:
        return
    var playback_position := _music_player.get_playback_position()
    if _current_music_name == MUSIC_FINAL_LEVEL_THEME and playback_position >= GRADE_12_LOOP_END_SECONDS:
        _music_player.seek(GRADE_12_LOOP_START_SECONDS)
    elif _current_music_name == MUSIC_NERD_CAT_THEME and playback_position >= GRADE_13_LOOP_END_SECONDS:
        _music_player.seek(GRADE_13_LOOP_START_SECONDS)

func play_music(track_name: String, transition_seconds: float = 0.0) -> void:
    if track_name == _current_music_name:
        if _music_player.playing or _music_player.stream_paused:
            return
        restart_music()
        return

    var music_path: String = MUSIC_TRACKS.get(track_name, "")
    print("[AudioManager] selected track=%s path=%s" % [track_name, music_path])
    if music_path.is_empty():
        push_error("[AudioManager] music playback failed: unknown track %s" % track_name)
        return

    var stream := ResourceLoader.load(music_path) as AudioStreamOggVorbis
    print("[AudioManager] resource loaded=%s path=%s" % [stream != null, music_path])
    if stream == null:
        push_error("[AudioManager] music playback failed: could not load %s" % music_path)
        return

    stream.loop = track_name != MUSIC_VICTORY_THEME
    if _music_fade != null and _music_fade.is_valid():
        _music_fade.kill()

    var incoming_index := 0 if _active_music_player_index == 1 else 1
    var incoming := _music_players[incoming_index]
    incoming.stop()
    incoming.stream = stream
    incoming.stream_paused = false
    incoming.volume_db = _music_volume_db
    incoming.play()

    if _active_music_player_index >= 0 and transition_seconds > 0.0:
        var outgoing := _music_players[_active_music_player_index]
        var transition := create_tween()
        _music_fade = transition
        transition.tween_property(outgoing, "volume_db", MUSIC_SILENT_DB, transition_seconds)
        transition.tween_callback(outgoing.stop)
    elif _active_music_player_index >= 0:
        _music_players[_active_music_player_index].stop()

    _music_player = incoming
    _active_music_player_index = incoming_index
    _current_music_name = track_name
    print("[AudioManager] playback started=%s track=%s" % [_music_player.playing, track_name])

func stop_music() -> void:
    if _music_fade != null and _music_fade.is_valid():
        _music_fade.kill()
    for music_player in _music_players:
        music_player.stop()
    _active_music_player_index = -1
    _current_music_name = ""

func pause_music() -> void:
    for music_player in _music_players:
        if music_player.stream != null:
            music_player.stream_paused = true

func resume_music() -> void:
    for music_player in _music_players:
        if music_player.stream != null:
            music_player.stream_paused = false

func restart_music() -> void:
    if _music_fade != null and _music_fade.is_valid():
        _music_fade.kill()
    for music_player_index in _music_players.size():
        if music_player_index != _active_music_player_index:
            _music_players[music_player_index].stop()
    if _music_player.stream != null:
        _music_player.stream_paused = false
        _music_player.volume_db = _music_volume_db
        _music_player.play(0.0)

func set_music_volume(level: int) -> void:
    _music_volume_db = MUSIC_BASELINE_DB + _volume_db_for_level(level)
    for music_player in _music_players:
        if music_player.playing:
            music_player.volume_db = _music_volume_db

func set_sfx_volume(level: int) -> void:
    _sfx_volume_db = _volume_db_for_level(level)

func play_sfx(sfx_name: String) -> void:
    var definition := _definition_for(sfx_name)
    if definition.is_empty():
        push_warning("Unknown Math Cat SFX: %s" % sfx_name)
        return

    var player := _players[_next_player_index]
    _next_player_index = posmod(_next_player_index + 1, _players.size())
    player.volume_db = _sfx_volume_db
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = SAMPLE_RATE
    stream.buffer_length = definition.duration + 0.1
    player.stream = stream
    player.play()
    _write_chip_tone(player.get_stream_playback(), definition)
    sfx_played.emit(sfx_name)

func _on_answer_registered(is_correct: bool) -> void:
    play_sfx(SFX_CORRECT_ANSWER if is_correct else SFX_INCORRECT_ANSWER)

func _on_promoted(old_grade: int, new_grade: int) -> void:
    play_sfx(SFX_LEVEL_UP)
    if GameManager.is_adventure_mode():
        return
    if GameManager.is_standard_mode() and old_grade < ProgressionManager.MAX_GRADE and new_grade == ProgressionManager.MAX_GRADE:
        play_music(MUSIC_VICTORY_THEME)
        return
    var old_stage := MathCatStagesScript.stage_for_grade(old_grade)
    var new_stage := MathCatStagesScript.stage_for_grade(new_grade)
    var transition_seconds := MUSIC_TRANSITION_SECONDS if old_stage != new_stage else 0.0
    _play_grade_music(new_grade, transition_seconds)

func _on_demoted(_old_grade: int, _new_grade: int) -> void:
    play_sfx(SFX_DEMOTION)
    if GameManager.is_adventure_mode():
        return
    _play_grade_music(_new_grade)

func _on_session_started() -> void:
    if GameManager.is_adventure_mode():
        play_music(str(GameManager.adventure_config.music))
        return
    _play_grade_music(ProgressionManager.current_grade)

func _on_session_ended(_final_score: int, _final_grade: int, _reason: String) -> void:
    if _reason != "victory":
        stop_music()

func _play_grade_music(grade: int, transition_seconds: float = 0.0) -> void:
    if grade == 11:
        play_music(MUSIC_GRADE_11_THEME, transition_seconds)
        return
    if grade == 12:
        play_music(MUSIC_FINAL_LEVEL_THEME, transition_seconds)
        return
    match MathCatStagesScript.stage_for_grade(grade):
        MathCatStagesScript.Stage.KITTEN:
            play_music(MUSIC_MATH_KITTEN_THEME, transition_seconds)
        MathCatStagesScript.Stage.BIG_CAT:
            play_music(MUSIC_MATH_CAT_THEME, transition_seconds)
        MathCatStagesScript.Stage.TIGER:
            play_music(MUSIC_MATH_TIGER_THEME, transition_seconds)
        MathCatStagesScript.Stage.NERD_CAT:
            play_music(MUSIC_NERD_CAT_THEME, transition_seconds)

func _definition_for(sfx_name: String) -> Dictionary:
    match sfx_name:
        SFX_CORRECT_ANSWER:
            return {"duration": 0.16, "start_pitch": 659.25, "end_pitch": 1046.5, "volume": 0.07, "wave": "pulse"}
        SFX_INCORRECT_ANSWER:
            return {"duration": 0.20, "start_pitch": 392.0, "end_pitch": 261.63, "volume": 0.20, "wave": "triangle"}
        SFX_LEVEL_UP:
            return {"duration": 1.15, "start_pitch": 523.25, "end_pitch": 1046.5, "volume": 0.0475, "wave": "pulse"}
        SFX_DEMOTION:
            return {"duration": 0.65, "start_pitch": 392.0, "end_pitch": 220.0, "volume": 0.24, "wave": "triangle"}
        SFX_UI_CONFIRM:
            return {"duration": 0.08, "start_pitch": 880.0, "end_pitch": 987.77, "volume": 0.18, "wave": "pulse"}
        SFX_PAUSE:
            return {"duration": 0.36, "start_pitch": 783.99, "end_pitch": 523.25, "volume": 0.075, "wave": "pulse", "step_pitch": true, "step_count": 4}
        SFX_UNPAUSE:
            return {"duration": 0.36, "start_pitch": 783.99, "end_pitch": 523.25, "volume": 0.075, "wave": "pulse", "step_pitch": true, "step_count": 4}
    return {}

func _volume_db_for_level(level: int) -> float:
    return -80.0 if level <= 0 else linear_to_db(float(clampi(level, 0, 10)) / 10.0)

func _write_chip_tone(playback: AudioStreamGeneratorPlayback, definition: Dictionary) -> void:
    var frame_count := ceili(definition.duration * SAMPLE_RATE)
    for frame_index in frame_count:
        var progress := float(frame_index) / frame_count
        var pitch := lerpf(definition.start_pitch, definition.end_pitch, progress)
        if definition.get("step_pitch", false):
            var step_count: int = definition.get("step_count", 2)
            var step_index := int(progress * step_count)
            pitch = definition.start_pitch if step_index % 2 == 0 else definition.end_pitch
        if definition.wave == "pulse" and definition.duration > 0.5:
            pitch *= 1.0 + floor(progress * 4.0) * 0.125
        var phase := TAU * pitch * float(frame_index) / SAMPLE_RATE
        var waveform := sin(phase) * 2.0 / PI if definition.wave == "triangle" else 1.0 if sin(phase) >= 0.0 else -1.0
        var envelope := minf(progress * 25.0, 1.0) * pow(1.0 - progress, 1.8)
        var sample: float = waveform * envelope * definition.volume
        playback.push_frame(Vector2(sample, sample))