#
# © 2026-present https://github.com/cengiz-pz
#

class_name CameraInfo extends RefCounted


const DATA_CAMERA_ID_PROPERTY: String = "camera_id"
const DATA_IS_FRONT_FACING_PROPERTY: String = "is_front_facing"
const DATA_OUTPUT_SIZES_PROPERTY: String = "output_sizes"

var _data: Dictionary


func _init(a_data: Dictionary):
	_data = a_data


func get_camera_id() -> String:
	return _data[DATA_CAMERA_ID_PROPERTY] if _data.has(DATA_CAMERA_ID_PROPERTY) else ""


func is_front_facing() -> bool:
	return _data[DATA_IS_FRONT_FACING_PROPERTY] if _data.has(DATA_IS_FRONT_FACING_PROPERTY) else false


func get_output_sizes() -> Array[FrameSize]:
	var __sizes: Array[FrameSize] = []

	for __size_dict in _data[DATA_OUTPUT_SIZES_PROPERTY]:
		__sizes.append(FrameSize.new(__size_dict))

	return __sizes
