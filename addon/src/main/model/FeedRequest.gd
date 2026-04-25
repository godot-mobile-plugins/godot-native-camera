#
# © 2026-present https://github.com/cengiz-pz
#

class_name FeedRequest extends RefCounted

const DATA_CAMERA_ID_PROPERTY := &"camera_id"
const DATA_WIDTH_PROPERTY := &"width"
const DATA_HEIGHT_PROPERTY := &"height"
const DATA_FRAMES_TO_SKIP_PROPERTY := &"frames_to_skip"
const DATA_ROTATION_PROPERTY := &"rotation"
const DATA_IS_GRAYSCALE_PROPERTY := &"is_grayscale"
const DATA_MIRROR_HORIZONTAL_PROPERTY := &"mirror_horizontal"
const DATA_MIRROR_VERTICAL_PROPERTY := &"mirror_vertical"
const DATA_SCALE_WIDTH_PROPERTY := &"scale_width"
const DATA_SCALE_HEIGHT_PROPERTY := &"scale_height"

const DEFAULT_WIDTH: int = 1280
const DEFAULT_HEIGHT: int = 720
const DEFAULT_FRAMES_TO_SKIP: int = 40
const DEFAULT_ROTATION: int = 90
## A value of 0 disables post-capture scaling on that axis.
## Both scale_width and scale_height must be non-zero for scaling to take effect.
const DEFAULT_SCALE_WIDTH: int = 0
const DEFAULT_SCALE_HEIGHT: int = 0

const DEFAULT_DATA: Dictionary = {
	DATA_WIDTH_PROPERTY: DEFAULT_WIDTH,
	DATA_HEIGHT_PROPERTY: DEFAULT_HEIGHT,
	DATA_FRAMES_TO_SKIP_PROPERTY: DEFAULT_FRAMES_TO_SKIP,
	DATA_ROTATION_PROPERTY: DEFAULT_ROTATION,
	DATA_IS_GRAYSCALE_PROPERTY: false,
	DATA_MIRROR_HORIZONTAL_PROPERTY: false,
	DATA_MIRROR_VERTICAL_PROPERTY: false,
	DATA_SCALE_WIDTH_PROPERTY: DEFAULT_SCALE_WIDTH,
	DATA_SCALE_HEIGHT_PROPERTY: DEFAULT_SCALE_HEIGHT
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


func set_mirror_horizontal(a_value: bool) -> FeedRequest:
	_data[DATA_MIRROR_HORIZONTAL_PROPERTY] = a_value
	return self


func set_mirror_vertical(a_value: bool) -> FeedRequest:
	_data[DATA_MIRROR_VERTICAL_PROPERTY] = a_value
	return self


## Sets the target width (in pixels) to which the frame buffer is scaled after
## rotation and mirroring. Set to 0 (default) to disable scaling.
## Both scale_width and scale_height must be non-zero for scaling to take effect.
func set_scale_width(a_value: int) -> FeedRequest:
	_data[DATA_SCALE_WIDTH_PROPERTY] = a_value
	return self


## Sets the target height (in pixels) to which the frame buffer is scaled after
## rotation and mirroring. Set to 0 (default) to disable scaling.
## Both scale_width and scale_height must be non-zero for scaling to take effect.
func set_scale_height(a_value: int) -> FeedRequest:
	_data[DATA_SCALE_HEIGHT_PROPERTY] = a_value
	return self


func get_raw_data() -> Dictionary:
	return _data
