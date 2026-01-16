#
# © 2026-present https://github.com/cengiz-pz
#

class_name FrameInfo extends RefCounted

const DATA_BUFFER_PROPERTY: String = "buffer"
const DATA_WIDTH_PROPERTY: String = "width"
const DATA_HEIGHT_PROPERTY: String = "height"
const DATA_ROTATION_PROPERTY = "rotation"
const DATA_IS_GRAYSCALE_PROPERTY = "is_grayscale"

var _data: Dictionary


func _init(a_data: Dictionary):
	_data = a_data


func get_buffer() -> PackedByteArray:
	return _data[DATA_BUFFER_PROPERTY] if _data.has(DATA_BUFFER_PROPERTY) else []


func get_width() -> int:
	return _data[DATA_WIDTH_PROPERTY] if _data.has(DATA_WIDTH_PROPERTY) else 0


func get_height() -> int:
	return _data[DATA_HEIGHT_PROPERTY] if _data.has(DATA_HEIGHT_PROPERTY) else 0


func get_rotation() -> int:
	return _data[DATA_ROTATION_PROPERTY] if _data.has(DATA_ROTATION_PROPERTY) else 0


func is_grayscale() -> bool:
	return _data[DATA_IS_GRAYSCALE_PROPERTY] if _data.has(DATA_IS_GRAYSCALE_PROPERTY) else false


func get_image() -> Image:
	var img := Image.create_from_data(
		get_width(),
		get_height(),
		false,
		Image.FORMAT_L8 if is_grayscale() else Image.FORMAT_RGBA8,
		get_buffer()
	)

	if is_grayscale:
		# Convert to RGBA for Godot texture display
		img.convert(Image.FORMAT_RGBA8)

	return img
