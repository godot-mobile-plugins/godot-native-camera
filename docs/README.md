<p align="center">
	<img width="256" height="256" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/demo/assets/native-camera-android.png">
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<img width="256" height="256" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/demo/assets/native-camera-ios.png">
</p>

---

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> Godot Native Camera Plugin

A Godot plugin that provides a **unified camera capture interface** for **Android** and **iOS** using native platform APIs. It enables real‑time camera frame streaming directly into Godot with configurable resolution, rotation, frame skipping, and optional grayscale output.

**Key Features:**

* Unified GDScript API for Android and iOS
* Enumerate available cameras and their supported output sizes
* Start and stop native camera frame streaming
* Receive raw frame buffers or ready‑to‑use `Image` objects
* Configurable resolution, rotation, frame skipping, and grayscale capture
* Designed for real‑time use cases (CV, AR preprocessing, custom rendering)

---

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Table of Contents

* [Installation](#installation)
* [Usage](#usage)
* [Signals](#signals)
* [Methods](#methods)
* [Classes](#classes)
* [Platform-Specific Notes](#platform-specific-notes)
* [Links](#links)
* [All Plugins](#all-plugins)
* [Credits](#credits)
* [Contributing](#contributing)

---

<a name="installation"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Installation

*Before installing this plugin, make sure to uninstall any previous versions of the same plugin.*

*If installing both Android and iOS versions of the plugin in the same project, ensure that both versions use the same addon interface version.*

There are two ways to install the `NativeCamera` plugin into your project:

* Through the Godot Editor AssetLib
* Manually by downloading archives from GitHub

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="18"> Installing via AssetLib

Steps:

* Search for **NativeCamera** in the Godot Editor AssetLib
* Click **Download**
* In the installation dialog:

  * Keep **Change Install Folder** set to your project root
  * Keep **Ignore asset root** checked
  * Click **Install**
* Enable the plugin from **Project → Project Settings → Plugins**

#### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="16"> Installing both Android and iOS versions

When installing both platforms via AssetLib, Godot may warn that some files conflict and will not be installed. This is expected and safe to ignore, as both platforms share the same addon interface code.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="18"> Installing manually

Steps:

* Download the release archive from GitHub
* Unzip the archive
* Copy the contents into your Godot project root
* Enable the plugin via **Project → Project Settings → Plugins**

---

<a name="usage"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Usage

Add a `NativeCamera` node to your main scene or register it as an autoload (singleton).

Typical workflow:

1. Query available cameras using `get_cameras()`
2. Choose a camera and desired output size
3. Create a `FeedRequest` to configure the stream
4. Start the camera feed
5. Receive frames via signals

### Example

```gdscript
@onready var camera := $NativeCamera

func _ready():
	camera.permission_result.connect(_on_permission_result)
	camera.frame_available.connect(_on_frame_available)
	camera.request_permission()

func _on_permission_result(granted: bool) -> void:
	if not granted:
		push_error("Camera permission denied")
		return

	var cameras := camera.get_cameras()
	if cameras.is_empty():
		return

	var cam: CameraInfo = cameras[0]
	var request := FeedRequest.new()
		.set_camera_id(cam.get_camera_id())
		.set_width(1280)
		.set_height(720)
		.set_rotation(90)
		.set_grayscale(false)

	camera.start_feed(request)

func _on_frame_available(frame: FrameInfo) -> void:
	var img := frame.get_image()
	# Use the image or raw buffer here
```

---

<a name="signals"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Signals

Register listeners on the `NativeCamera` node:

* `permission_result(granted: bool)`

  * Emitted after a camera permission request completes

* `frame_available(frame: FrameInfo)`

  * Emitted when a new camera frame is available

---

<a name="methods"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Methods

* `request_permission()`

  * Requests camera permission from the OS

* `get_cameras() -> Array[CameraInfo]`

  * Returns a list of available cameras

* `start(request: FeedRequest)`

  * Starts the camera feed with the given configuration

* `stop()`

  * Stops the active camera feed

---

<a name="classes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Classes

This section documents the GDScript interface classes implemented and exposed by the plugin.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="16"> CameraInfo

Encapsulates camera metadata provided by the mobile OS.

**Properties / Methods:**

* `get_camera_id() -> String`
* `is_front_facing() -> bool`
* `get_output_sizes() -> Array[FrameSize]`

---

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="16"> FeedRequest

Defines configuration parameters for starting a camera feed.

**Configurable options:**

* Camera ID
* Output width and height
* Frames to skip (performance tuning)
* Rotation (degrees)
* Grayscale capture

Supports fluent chaining via setter methods.

---

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="16"> FrameInfo

Represents a single captured frame.

**Accessors:**

* `get_buffer() -> PackedByteArray`
* `get_width() -> int`
* `get_height() -> int`
* `get_rotation() -> int`
* `is_grayscale() -> bool`
* `get_image() -> Image`

---

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="16"> FrameSize

Represents a supported camera output resolution.

**Accessors:**

* `get_width() -> int`
* `get_height() -> int`
* `get_raw_data() -> Dictionary`

---

<a name="platform-specific-notes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Platform-Specific Notes

### Android

* Ensure Android export templates are installed
* Enable Gradle build in export settings
* Camera permission is required at runtime

**Troubleshooting:**

* Logs (Linux/macOS): `adb logcat | grep godot`
* Logs (Windows): `adb.exe logcat | select-string "godot"`

Helpful resources:

* Godot Android export documentation
* Android Studio & ADB documentation

### iOS

* Follow Godot’s iOS export instructions
* Camera permission must be declared in the generated Xcode project
* Use Xcode console logs for debugging

---

<a name="links"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> Links

* [AssetLib Entry Android](https://godotengine.org/asset-library/asset/4675)
* [AssetLib Entry iOS](https://godotengine.org/asset-library/asset/4676)

---

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> All Plugins

| Plugin | Android | iOS | Free | Open Source | License |
| :--- | :---: | :---: | :---: | :---: | :---: |
| [Admob](https://github.com/godot-sdk-integrations/godot-admob) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Notification Scheduler](https://github.com/godot-mobile-plugins/godot-notification-scheduler) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Deeplink](https://github.com/godot-mobile-plugins/godot-deeplink) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Share](https://github.com/godot-mobile-plugins/godot-share) | ✅ | ✅ | ✅ | ✅ | MIT |
| [In-App Review](https://github.com/godot-mobile-plugins/godot-inapp-review) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Native Camera](https://github.com/godot-mobile-plugins/godot-native-camera) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Connection State](https://github.com/godot-mobile-plugins/godot-connection-state) | ✅ | ✅ | ✅ | ✅ | MIT |
| [OAuth 2.0](https://github.com/godot-mobile-plugins/godot-oauth2) | ✅ | ✅ | ✅ | ✅ | MIT |
| [QR](https://github.com/godot-mobile-plugins/godot-qr) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Firebase](https://github.com/godot-mobile-plugins/godot-firebase) | ✅ | ✅ | ✅ | ✅ | MIT |

---

<a name="credits"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> Credits

Developed by [Cengiz](https://github.com/cengiz-pz)

Based on [Godot Mobile Plugin Template](https://github.com/godot-mobile-plugins/godot-plugin-template)

Original repository: [Godot Native Camera Plugin](https://github.com/godot-mobile-plugins/godot-native-camera)

---

<a name="contributing"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> Contributing

Contributions are welcome. Please see the [contributing guide](https://github.com/godot-mobile-plugins/godot-native-camera?tab=contributing-ov-file) in the repository for details.
