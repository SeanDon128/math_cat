class_name PixelMeterIcon
extends Control

enum Kind { HEART, PIP, COIN }

static var _coin_texture: ImageTexture

static func coin_texture() -> ImageTexture:
	if _coin_texture == null:
		var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		image.fill_rect(Rect2i(3, 0, 6, 12), Color("c39128"))
		image.fill_rect(Rect2i(0, 3, 12, 6), Color("c39128"))
		image.fill_rect(Rect2i(2, 2, 8, 8), Color("ffe477"))
		image.fill_rect(Rect2i(5, 3, 2, 6), Color("c39128"))
		_coin_texture = ImageTexture.create_from_image(image)
	return _coin_texture

@export var kind: Kind = Kind.PIP:
	set(value):
		kind = value
		queue_redraw()
@export var filled := false:
	set(value):
		filled = value
		queue_redraw()
@export var active_color := Color("79d26a"):
	set(value):
		active_color = value
		queue_redraw()
@export var empty_color := Color("39465c"):
	set(value):
		empty_color = value
		queue_redraw()

const HEART_PIXELS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(2, 0), Vector2i(4, 0), Vector2i(5, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2),
	Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3),
	Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(3, 5),
]
const PIP_PIXELS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3),
	Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4),
]

func _draw() -> void:
	if kind == Kind.COIN:
		var extent := floorf(minf(size.x, size.y) / 12.0) * 12.0
		if extent >= 12.0:
			draw_texture_rect(coin_texture(), Rect2((size - Vector2.ONE * extent) * 0.5, Vector2.ONE * extent), false)
		return
	var pixels: Array[Vector2i] = HEART_PIXELS if kind == Kind.HEART else PIP_PIXELS
	var grid_size: Vector2 = Vector2(7, 6) if kind == Kind.HEART else Vector2(5, 5)
	var pixel_size: float = floorf(minf(size.x / grid_size.x, size.y / grid_size.y))
	if pixel_size < 1.0:
		return

	var draw_size: Vector2 = grid_size * pixel_size
	var origin: Vector2 = (size - draw_size) * 0.5
	var color := active_color if filled else empty_color
	for pixel_position: Vector2i in pixels:
		var position: Vector2 = origin + Vector2(pixel_position) * pixel_size
		draw_rect(Rect2(position, Vector2.ONE * maxf(pixel_size - 1.0, 1.0)), color)