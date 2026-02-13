#
# © 2026-present https://github.com/cengiz-pz
#

class_name FrameSize extends RefCounted

const DATA_WIDTH_PROPERTY = "width"
const DATA_HEIGHT_PROPERTY = "height"


var _data: Dictionary


func _init(a_data: Dictionary) -> void:
	_data = a_data


func get_width() -> int:
	return _data[DATA_WIDTH_PROPERTY] if _data.has(DATA_WIDTH_PROPERTY) else 0


func set_width(a_value: int) -> FrameSize:
	_data[DATA_WIDTH_PROPERTY] = a_value
	return self


func get_height() -> int:
	return _data[DATA_HEIGHT_PROPERTY] if _data.has(DATA_HEIGHT_PROPERTY) else 0


func set_height(a_value: int) -> FrameSize:
	_data[DATA_HEIGHT_PROPERTY] = a_value
	return self


func get_raw_data() -> Dictionary:
	return _data
