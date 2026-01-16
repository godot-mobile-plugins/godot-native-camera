#
# © 2026-present https://github.com/cengiz-pz
#

@tool
@icon("icon.png")
class_name NativeCamera extends Node

signal camera_permission_granted()
signal camera_permission_denied()
signal frame_available(a_info: FrameInfo)

const PLUGIN_SINGLETON_NAME: String = "@pluginName@"

## Width of the requested camera frame in pixels.
@export var frame_width: int = FeedRequest.DEFAULT_WIDTH

## Height of the requested camera frame in pixels.
@export var frame_height: int = FeedRequest.DEFAULT_HEIGHT

## The number of frames to skip before emitting next frame. If conducting heaving processing of each frame, then increase this value to improve perfomance.
@export var frames_to_skip: int = FeedRequest.DEFAULT_FRAMES_TO_SKIP

## The rotation to be applied to the frame in degrees. Valid values are 0, 90, 180, and 270.
@export var frame_rotation: int = FeedRequest.DEFAULT_ROTATION

## Whether the emitted frames should be grayscale or colored.
@export var is_grayscale: bool = false

var _plugin_singleton: Object


func _ready() -> void:
	_update_plugin()


func _notification(a_what: int) -> void:
	if a_what == NOTIFICATION_APPLICATION_RESUMED:
		_update_plugin()


func _update_plugin() -> void:
	if _plugin_singleton == null:
		if Engine.has_singleton(PLUGIN_SINGLETON_NAME):
			_plugin_singleton = Engine.get_singleton(PLUGIN_SINGLETON_NAME)
			_connect_signals()
		elif not Engine.is_editor_hint():
			NativeCamera.log_error("%s singleton not found on this platform!" % PLUGIN_SINGLETON_NAME)


func _connect_signals() -> void:
	_plugin_singleton.connect("camera_permission_granted", _on_camera_permission_granted)
	_plugin_singleton.connect("camera_permission_denied", _on_camera_permission_denied)
	_plugin_singleton.connect("frame_available", _on_frame_available)


func has_camera_permission() -> bool:
	var __result: bool = false

	if _plugin_singleton:
		__result = _plugin_singleton.has_camera_permission()
	else:
		NativeCamera.log_error("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)

	return __result


func request_camera_permission() -> void:
	if _plugin_singleton:
		_plugin_singleton.request_camera_permission()
	else:
		NativeCamera.log_error("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)


func get_all_cameras() -> Array[CameraInfo]:
	var __result: Array[CameraInfo] = []

	if _plugin_singleton:
		var __cameras = _plugin_singleton.get_all_cameras()

		for __camera_dict in __cameras:
			__result.append(CameraInfo.new(__camera_dict))
	else:
		NativeCamera.log_error("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)

	return __result


func create_feed_request() -> FeedRequest:
	return (FeedRequest.new()
				.set_width(frame_width)
				.set_height(frame_height)
				.set_frames_to_skip(frames_to_skip)
				.set_rotation(frame_rotation)
				.set_grayscale(is_grayscale))


func start(a_request: FeedRequest) -> void:
	if _plugin_singleton:
		_plugin_singleton.start(a_request.get_raw_data())
	else:
		NativeCamera.log_error("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)


func stop() -> void:
	if _plugin_singleton:
		_plugin_singleton.stop()
	else:
		NativeCamera.log_error("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)


func _on_camera_permission_granted() -> void:
	camera_permission_granted.emit()


func _on_camera_permission_denied() -> void:
	camera_permission_denied.emit()


func _on_frame_available(a_dict: Dictionary) -> void:
	frame_available.emit(FrameInfo.new(a_dict))


static func log_error(a_description: String) -> void:
	push_error("%s: %s" % [PLUGIN_SINGLETON_NAME, a_description])


static func log_warn(a_description: String) -> void:
	push_warning("%s: %s" % [PLUGIN_SINGLETON_NAME, a_description])


static func log_info(a_description: String) -> void:
	print_rich("[color=lime]%s: INFO: %s[/color]" % [PLUGIN_SINGLETON_NAME, a_description])
