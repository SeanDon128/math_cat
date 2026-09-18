class_name MathCat
extends AnimatedSprite2D

## Character animation controller with four evolution stages (Kitten/Big Cat/Tiger/Nerd Cat).
## Assign per-stage SpriteFrames in the inspector to use real art; any stage left
## unassigned falls back to procedural placeholder frames built at runtime.

const MathCatStagesScript = preload("res://scripts/character/math_cat_stages.gd")
const CatAccessory = preload("res://scripts/character/cat_accessory.gd")

signal reaction_started(animation_name: String)
signal evolved(new_stage: MathCatStagesScript.Stage)

const ANIM_IDLE := "idle"
const ANIM_HAPPY := "happy"
const ANIM_SAD := "sad"
const ANIM_LEVEL_UP := "level_up"
const ANIM_GAME_OVER := "game_over"
const ANIM_PAUSE := "pause"
const ANIM_HIGH_SCORE := "high_score"
const ANIM_EVOLUTION_POSE := "evolution_pose"

const SPRITE_SIZE := 64

# Non-looping reactions that fall back to idle once finished.
const _RETURN_TO_IDLE := [ANIM_HAPPY, ANIM_SAD, ANIM_LEVEL_UP, ANIM_EVOLUTION_POSE]

## Per-stage art overrides. Leave unset to use the procedural placeholder for that stage.
@export var kitten_frames: SpriteFrames
@export var big_cat_frames: SpriteFrames
@export var tiger_frames: SpriteFrames
@export var nerd_cat_frames: SpriteFrames

var current_stage: MathCatStagesScript.Stage = MathCatStagesScript.Stage.KITTEN
var _placeholder_frames_cache: Dictionary = {}
var _level_up_plays_remaining := 0
var _evolution_pose_plays_remaining := 0
var equipped_accessories: Dictionary = {}
var _accessory: CatAccessory

func _ready() -> void:
	if not animation_finished.is_connected(_on_animation_finished):
		animation_finished.connect(_on_animation_finished)
	_apply_stage_frames(current_stage)
	play_idle()

func set_accessories(items: Dictionary) -> void:
	if equipped_accessories == items:
		return
	equipped_accessories = items.duplicate()
	if _accessory == null:
		_accessory = CatAccessory.new()
		add_child(_accessory)
		frame_changed.connect(_accessory.queue_redraw)
		animation_changed.connect(_accessory.queue_redraw)
	_accessory.items = equipped_accessories
	_accessory.queue_redraw()

## Silently switches the character's evolution stage (e.g. resetting a new session).
func set_stage(stage: MathCatStagesScript.Stage) -> void:
	current_stage = stage
	_apply_stage_frames(stage)
	play_idle()

## Switches stage and plays a celebratory reaction; use this when a grade promotion
## crosses into a new evolution tier.
func evolve_to(stage: MathCatStagesScript.Stage) -> void:
	current_stage = stage
	_apply_stage_frames(stage)
	evolved.emit(stage)
	play_evolution_pose()

func play_idle() -> void:
	_play_state(ANIM_IDLE)

func play_happy() -> void:
	_play_state(ANIM_HAPPY)

func play_victory_pose() -> void:
	_play_state(ANIM_HAPPY)
	pause()

func play_evolution_victory_pose() -> void:
	_play_state(ANIM_EVOLUTION_POSE)
	pause()

func play_sad() -> void:
	_play_state(ANIM_SAD)

func play_level_up() -> void:
	_level_up_plays_remaining = 2
	_play_state(ANIM_LEVEL_UP)

func play_game_over() -> void:
	_play_state(ANIM_GAME_OVER)

## Loops while the pause menu is open; call play_idle() when resuming.
func play_pause() -> void:
	_play_state(ANIM_PAUSE)

## Loops while a new-high-score celebration is shown; call play_idle() when it closes.
func play_high_score() -> void:
	_play_state(ANIM_HIGH_SCORE)

func play_evolution_pose() -> void:
	_evolution_pose_plays_remaining = 2
	_play_state(ANIM_EVOLUTION_POSE)

func _play_state(animation_name: String) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation_name):
		return
	play(animation_name)
	reaction_started.emit(animation_name)

func _on_animation_finished() -> void:
	# game_over intentionally holds its final animation instead of returning to idle.
	if String(animation) == ANIM_LEVEL_UP and _level_up_plays_remaining > 1:
		_level_up_plays_remaining -= 1
		_play_state(ANIM_LEVEL_UP)
		return
	if String(animation) == ANIM_EVOLUTION_POSE and _evolution_pose_plays_remaining > 1:
		_evolution_pose_plays_remaining -= 1
		_play_state(ANIM_EVOLUTION_POSE)
		return
	if String(animation) in _RETURN_TO_IDLE:
		_level_up_plays_remaining = 0
		_evolution_pose_plays_remaining = 0
		play_idle()

func _apply_stage_frames(stage: MathCatStagesScript.Stage) -> void:
	sprite_frames = _resolve_frames_for_stage(stage)

func _resolve_frames_for_stage(stage: MathCatStagesScript.Stage) -> SpriteFrames:
	var assigned := _exported_frames_for_stage(stage)
	if assigned != null:
		return assigned
	if not _placeholder_frames_cache.has(stage):
		_placeholder_frames_cache[stage] = _build_placeholder_frames(stage)
	return _placeholder_frames_cache[stage]

func _exported_frames_for_stage(stage: MathCatStagesScript.Stage) -> SpriteFrames:
	match stage:
		MathCatStagesScript.Stage.KITTEN:
			return kitten_frames
		MathCatStagesScript.Stage.BIG_CAT:
			return big_cat_frames
		MathCatStagesScript.Stage.TIGER:
			return tiger_frames
		MathCatStagesScript.Stage.NERD_CAT:
			return nerd_cat_frames
	return null

func _build_placeholder_frames(stage: MathCatStagesScript.Stage) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	# Nerd Cat gets an extra idle frame so it visibly pushes its glasses up.
	var idle_frame_count := 3 if stage == MathCatStagesScript.Stage.NERD_CAT else 2
	_add_placeholder_animation(frames, stage, ANIM_IDLE, Color("e67e22"), 4.0, true, idle_frame_count)
	_add_placeholder_animation(frames, stage, ANIM_HAPPY, Color("7ac74f"), 8.0, false, 2)
	_add_placeholder_animation(frames, stage, ANIM_SAD, Color("5a7d9a"), 6.0, false, 2)
	_add_placeholder_animation(frames, stage, ANIM_LEVEL_UP, Color("f4c430"), 10.0, false, 3)
	_add_placeholder_animation(frames, stage, ANIM_GAME_OVER, Color("8a2b2b"), 3.0, false, 2)
	_add_placeholder_animation(frames, stage, ANIM_PAUSE, Color("e67e22"), 2.0, true, 2)
	_add_placeholder_animation(frames, stage, ANIM_HIGH_SCORE, Color("f4c430"), 10.0, true, 4)
	_add_placeholder_animation(frames, stage, ANIM_EVOLUTION_POSE, Color("68b7ff"), 8.0, false, 4)
	return frames

func _add_placeholder_animation(frames: SpriteFrames, stage: MathCatStagesScript.Stage, animation_name: String, body_color: Color, fps: float, loops: bool, frame_count: int) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loops)
	for frame_index in frame_count:
		frames.add_frame(animation_name, _make_placeholder_texture(stage, body_color, animation_name, frame_index))

func _make_placeholder_texture(stage: MathCatStagesScript.Stage, body_color: Color, animation_name: String, frame_index: int) -> ImageTexture:
	var image := Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var outline := Color("2b2b3c")
	var bob := frame_index % 2  # 1px vertical bob so frames visibly differ
	# Big Cat/Tiger/Nerd Cat read as bigger and more grown-up than the Kitten stage.
	var is_grown := stage != MathCatStagesScript.Stage.KITTEN
	var ear_size := 12 if is_grown else 10
	var body_width := 44 if is_grown else 40

	image.fill_rect(Rect2i(14, 2 + bob, ear_size, ear_size), body_color)
	image.fill_rect(Rect2i(SPRITE_SIZE - 14 - ear_size, 2 + bob, ear_size, ear_size), body_color)
	image.fill_rect(Rect2i((SPRITE_SIZE - body_width) / 2, 12 + bob, body_width, 44), body_color)

	if stage == MathCatStagesScript.Stage.TIGER:
		var stripe_color := Color("2b2b3c")
		for stripe_index in range(3):
			image.fill_rect(Rect2i(20 + stripe_index * 8, 16 + bob, 4, 30), stripe_color)

	if frame_index % 2 == 0:
		image.fill_rect(Rect2i(22, 26 + bob, 6, 8), outline)
		image.fill_rect(Rect2i(36, 26 + bob, 6, 8), outline)
	else:
		image.fill_rect(Rect2i(22, 30 + bob, 6, 2), outline)
		image.fill_rect(Rect2i(36, 30 + bob, 6, 2), outline)

	if stage == MathCatStagesScript.Stage.NERD_CAT:
		_draw_nerd_cat_details(image, animation_name, frame_index, bob)

	return ImageTexture.create_from_image(image)

## Nerd Cat always wears glasses and a cap; specific frames animate them
## (glasses push-up during idle, cap toss during level_up, a diploma/star during
## happy or the high-score celebration).
func _draw_nerd_cat_details(image: Image, animation_name: String, frame_index: int, bob: int) -> void:
	var glasses_color := Color("1c1c28")
	var glasses_y := 27 + bob
	if animation_name == ANIM_IDLE and frame_index == 1:
		glasses_y -= 2
	image.fill_rect(Rect2i(20, glasses_y, 10, 4), glasses_color)
	image.fill_rect(Rect2i(34, glasses_y, 10, 4), glasses_color)
	image.fill_rect(Rect2i(30, glasses_y + 1, 4, 2), glasses_color)

	var cap_thrown := animation_name == ANIM_LEVEL_UP and frame_index == 2
	if not cap_thrown:
		image.fill_rect(Rect2i(18, 4 + bob, 28, 6), Color("14141c"))
		image.fill_rect(Rect2i(30, 0 + bob, 4, 6), Color("f4c430"))

	var shows_diploma := (animation_name == ANIM_HAPPY and frame_index == 1) or (animation_name == ANIM_HIGH_SCORE and frame_index % 2 == 1)
	if shows_diploma:
		image.fill_rect(Rect2i(44, 40, 12, 10), Color("f4c430"))
