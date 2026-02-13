#
# © 2026-present https://github.com/cengiz-pz
#

class_name FeedRequest extends RefCounted

const DATA_CAMERA_ID_PROPERTY = "camera_id"
const DATA_WIDTH_PROPERTY = "width"
const DATA_HEIGHT_PROPERTY = "height"
const DATA_FRAMES_TO_SKIP_PROPERTY = "frames_to_skip"
const DATA_ROTATION_PROPERTY = "rotation"
const DATA_IS_GRAYSCALE_PROPERTY = "is_grayscale"

const DEFAULT_WIDTH: int = 1280
const DEFAULT_HEIGHT: int = 720
const DEFAULT_FRAMES_TO_SKIP: int = 40
const DEFAULT_ROTATION: int = 90

const DEFAULT_DATA: Dictionary = {
	DATA_WIDTH_PROPERTY: DEFAULT_WIDTH,
	DATA_HEIGHT_PROPERTY: DEFAULT_HEIGHT,
	DATA_FRAMES_TO_SKIP_PROPERTY: DEFAULT_FRAMES_TO_SKIP,
	DATA_ROTATION_PROPERTY: DEFAULT_ROTATION,
	DATA_IS_GRAYSCALE_PROPERTY: false
}

var _data: Dictionary


func _init(a_data: Dictionary = DEFAULT_DATA.duplicate()) -> void:
	_data = a_data


func set_camera_id(a_value: String) -> FeedRequest:
	_data[DATA_CAMERA_ID_PROPERTY] = a_value
	return self


func set_width(a_value: int) -> FeedRequest:
	_data[DATA_WIDTH_PROPERTY] = a_value
	return self


func set_height(a_value: int) -> FeedRequest:
	_data[DATA_HEIGHT_PROPERTY] = a_value
	return self


func set_frames_to_skip(a_value: int) -> FeedRequest:
	_data[DATA_FRAMES_TO_SKIP_PROPERTY] = a_value
	return self


func set_rotation(a_value: int) -> FeedRequest:
	_data[DATA_ROTATION_PROPERTY] = a_value
	return self


func set_grayscale(a_value: bool) -> FeedRequest:
	_data[DATA_IS_GRAYSCALE_PROPERTY] = a_value
	return self


func get_raw_data() -> Dictionary:
	return _data
