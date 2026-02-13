#
# © 2026-present https://github.com/cengiz-pz
#

extends Node

@onready var camera_node: NativeCamera = $NativeCamera
@onready var facing_label: Label = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/CameraVBC/HBoxContainer/FacingValueLabel
@onready var camera_texture_rect: TextureRect = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/CameraVBC/CameraTextureRect
@onready var cameras_option_button: OptionButton = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/ButtonsVBC/CamerasOB
@onready var rotation_slider: HSlider = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/ButtonsVBC/RotationHBC/RotationHSlider
@onready var rotation_label: Label = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/ButtonsVBC/RotationHBC/ValueLabel
@onready var grayscale_check_button: CheckButton = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/ButtonsVBC/GrayscaleCB
@onready var frame_skip_slider: HSlider = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/ButtonsVBC/FrameSkipHBC/SkipHSlider
@onready var frame_skip_label: Label = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/ButtonsVBC/FrameSkipHBC/ValueLabel
@onready var get_cameras_button: Button = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/ButtonsVBC/GetButton
@onready var start_camera_button: Button = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/ButtonsVBC/StartButton
@onready var stop_camera_button: Button = $CanvasLayer/MainContainer/VBoxContainer/CameraHBC/ButtonsVBC/StopButton
@onready var _label: RichTextLabel = $CanvasLayer/MainContainer/VBoxContainer/RichTextLabel as RichTextLabel
@onready var _android_texture_rect: TextureRect = $CanvasLayer/MainContainer/VBoxContainer/TextureHBC/AndroidTextureRect as TextureRect
@onready var _ios_texture_rect: TextureRect = $CanvasLayer/MainContainer/VBoxContainer/TextureHBC/iOSTextureRect as TextureRect

var _cameras: Dictionary[String, CameraInfo]
var _camera_texture: ImageTexture = null

var _active_texture_rect: TextureRect


func _ready() -> void:
	if OS.has_feature("ios"):
		_android_texture_rect.hide()
		_active_texture_rect = _ios_texture_rect
	else:
		_ios_texture_rect.hide()
		_active_texture_rect = _android_texture_rect

	if camera_node.has_camera_permission():
		get_cameras_button.disabled = false
	else:
		camera_node.request_camera_permission()


func _on_get_button_pressed() -> void:
	var __cameras_array = camera_node.get_all_cameras()
	for __camera_info in __cameras_array:
		_cameras[__camera_info.get_camera_id()] = __camera_info
		print("Available size:")
		for __size: FrameSize in __camera_info.get_output_sizes():
			print("[%d,%d]" % [__size.get_width(), __size.get_height()])
		cameras_option_button.add_item(__camera_info.get_camera_id())

	if not __cameras_array.is_empty():
		_update_selected_camera_info(cameras_option_button.get_item_text(0))

	if not _cameras.is_empty():
		start_camera_button.disabled = false
		stop_camera_button.disabled = false


func _on_cameras_ob_item_selected(index: int) -> void:
	_update_selected_camera_info(cameras_option_button.get_item_text(index))


func _update_selected_camera_info(camera_id: String) -> void:
	if _cameras.has(camera_id):
		var __selected_camera: CameraInfo = _cameras[camera_id]
		if __selected_camera.is_front_facing():
			facing_label.text = "FRONT"
		else:
			facing_label.text = "BACK"
	else:
		_print_to_screen("Camera %d not found" % camera_id, true)


func _on_rotation_h_slider_value_changed(value: float) -> void:
	rotation_label.text = str(int(value))


func _on_skip_h_slider_value_changed(value: float) -> void:
	frame_skip_label.text = str(int(value))


func _on_start_button_pressed() -> void:
	var __camera_id: String = cameras_option_button.get_item_text(cameras_option_button.get_selected_id())
	camera_node.start(camera_node.create_feed_request()
		.set_camera_id(__camera_id)
		.set_frames_to_skip(int(frame_skip_slider.value))
		.set_rotation(int(rotation_slider.value))
		.set_grayscale(grayscale_check_button.button_pressed))
	_print_to_screen("Camera started [id: %s, rot: %.1f, gray?:%s]" % [__camera_id, rotation_slider.value, grayscale_check_button.button_pressed])


func _on_stop_button_pressed() -> void:
	camera_node.stop()
	# Clear the texture visually so we know it stopped
	camera_texture_rect.texture = null
	_camera_texture = null
	_print_to_screen("Camera stopped")


func _on_native_camera_frame_available(a_info: FrameInfo) -> void:
	var image: Image = a_info.get_image()
	if image.is_empty():
		_print_to_screen("Received empty image!", true)
		return

	# Force execution on main thread
	call_deferred("_update_texture", image)


func _on_native_camera_camera_permission_granted() -> void:
	_print_to_screen("Camera permission granted")
	get_cameras_button.disabled = false


func _on_native_camera_camera_permission_denied() -> void:
	_print_to_screen("Camera permission denied")


func _update_texture(image: Image) -> void:
	if _camera_texture == null:
		_camera_texture = ImageTexture.create_from_image(image)
		camera_texture_rect.texture = _camera_texture
	else:
		_camera_texture.update(image)


func _print_to_screen(a_message: String, a_is_error: bool = false) -> void:
	if a_is_error:
		_label.push_color(Color.CRIMSON)

	_label.add_text("%s\n\n" % a_message)

	if a_is_error:
		_label.pop()
		printerr("Demo app:: " + a_message)
	else:
		print("Demo app:: " + a_message)

	_label.scroll_to_line(_label.get_line_count() - 1)
