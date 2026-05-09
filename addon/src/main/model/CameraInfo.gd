#
# © 2026-present https://github.com/cengiz-pz
#

class_name CameraInfo extends RefCounted

const DATA_CAMERA_ID_PROPERTY := &"camera_id"
const DATA_IS_FRONT_FACING_PROPERTY := &"is_front_facing"
const DATA_OUTPUT_SIZES_PROPERTY := &"output_sizes"
const DATA_SENSOR_ORIENTATION_PROPERTY := &"sensor_orientation"

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


## Returns the clockwise angle in degrees (0, 90, 180, or 270) that the camera
## sensor image must be rotated to be upright when the device is held in its
## natural (portrait) orientation.  Defaults to [code]0[/code] when the value
## is unavailable.
func get_sensor_orientation() -> int:
	return _data[DATA_SENSOR_ORIENTATION_PROPERTY] if _data.has(DATA_SENSOR_ORIENTATION_PROPERTY) else 0
