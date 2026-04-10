<p align="center">
	<img width="128" height="128" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/demo/assets/native-camera-android.png">
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<img width="128" height="128" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/demo/assets/native-camera-ios.png">
</p>

<div align="center">
	<a href="https://github.com/godot-mobile-plugins/godot-native-camera"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-native-camera?label=Stars&style=plastic" height="40"/></a>
	<img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-native-camera?label=Latest%20Release&style=plastic" height="40"/>
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/latest/total?label=Downloads&style=plastic" height="40"/>
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/total?label=Total%20Downloads&style=plastic" height="40"/>
</div>

<br>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> Godot Native Camera Plugin

A Godot plugin that provides a **unified camera capture interface** for **Android** and **iOS** using native platform APIs. It enables real‑time camera frame streaming directly into Godot with configurable resolution, rotation, frame skipping, and optional grayscale output.

**Key Features:**

* Unified GDScript API for Android and iOS
* Enumerate available cameras and their supported output sizes
* Start and stop native camera frame streaming
* Receive raw frame buffers or ready‑to‑use `Image` objects
* Configurable resolution, rotation, frame skipping, and grayscale capture
* Designed for real‑time use cases (CV, AR preprocessing, custom rendering)

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
	camera.camera_permission_granted.connect(_on_camera_permission_granted)
	camera.camera_permission_denied.connect(_on_camera_permission_denied)
	camera.frame_available.connect(_on_frame_available)
	camera.request_camera_permission()

func _on_camera_permission_granted() -> void:
	var cameras := camera.get_all_cameras()
	if cameras.is_empty():
		return

	var cam: CameraInfo = cameras[0]
	var request := FeedRequest.new()
		.set_camera_id(cam.get_camera_id())
		.set_width(1280)
		.set_height(720)
		.set_rotation(90)
		.set_grayscale(false)

	camera.start(request)

func _on_camera_permission_denied() -> void:
	push_error("Camera permission denied")

func _on_frame_available(frame: FrameInfo) -> void:
	var img := frame.get_image()
	# Use the image or raw buffer here
```

<a name="signals"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Signals

Register listeners on the `NativeCamera` node:

* `camera_permission_granted()`

  * Emitted when camera permission is granted by the user

* `camera_permission_denied()`

  * Emitted when camera permission is denied by the user

* `frame_available(frame: FrameInfo)`

  * Emitted when a new camera frame is available

<a name="methods"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Methods

* `has_camera_permission() -> bool`

  * Returns whether camera permission has already been granted

* `request_camera_permission()`

  * Requests camera permission from the OS

* `get_all_cameras() -> Array[CameraInfo]`

  * Returns a list of available cameras

* `create_feed_request() -> FeedRequest`

  * Creates a `FeedRequest` pre-populated with the node's exported property values (`frame_width`, `frame_height`, `frames_to_skip`, `frame_rotation`, `is_grayscale`)

* `start(request: FeedRequest)`

  * Starts the camera feed with the given configuration

* `stop()`

  * Stops the active camera feed

<a name="classes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Classes

This section documents the GDScript interface classes implemented and exposed by the plugin.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="16"> CameraInfo

Encapsulates camera metadata provided by the mobile OS.

**Properties / Methods:**

* `get_camera_id() -> String`
* `is_front_facing() -> bool`
* `get_output_sizes() -> Array[FrameSize]`

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="16"> FeedRequest

Defines configuration parameters for starting a camera feed.

**Configurable options:**

* Camera ID
* Output width and height
* Frames to skip (performance tuning)
* Rotation (degrees)
* Grayscale capture

Supports fluent chaining via setter methods.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="16"> FrameInfo

Represents a single captured frame.

**Accessors:**

* `get_buffer() -> PackedByteArray`
* `get_width() -> int`
* `get_height() -> int`
* `get_rotation() -> int`
* `is_grayscale() -> bool`
* `get_image() -> Image`

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="16"> FrameSize

Represents a supported camera output resolution.

**Accessors:**

* `get_width() -> int`
* `get_height() -> int`
* `get_raw_data() -> Dictionary`

<a name="platform-specific-notes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> Platform-Specific Notes

### Android

* Ensure Android export templates are installed
* Enable Gradle build in export settings
* Camera permission is required at runtime
* The **"Two-Strike" Rule**: Starting in Android 11, if a user taps "Deny" for a specific permission more than once during the app's lifetime on the device, the system will no longer show the dialog for future requests. Once this two-strike threshold is reached, any subsequent calls to request the permission will immediately be denied without showing any dialogs.

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

<br>

<a name="links"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> Links

* [AssetLib Entry Android](https://godotengine.org/asset-library/asset/4675)
* [AssetLib Entry iOS](https://godotengine.org/asset-library/asset/4676)

<br>

<a name="all-plugins"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> All Plugins

| ✦ | Plugin | Android | iOS | Latest Release | Downloads | Stars |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/godot-sdk-integrations/godot-admob/main/addon/src/icon.png" width="20"> | [Admob](https://github.com/godot-sdk-integrations/godot-admob) | ✅ | ✅ | <a href="https://github.com/godot-sdk-integrations/godot-admob/releases"><img src="https://img.shields.io/github/release-date/godot-sdk-integrations/godot-admob?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-sdk-integrations/godot-admob?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-sdk-integrations/godot-admob?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-connection-state/main/addon/src/icon.png" width="20"> | [Connection State](https://github.com/godot-mobile-plugins/godot-connection-state) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-connection-state/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-connection-state?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-connection-state?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-connection-state?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-deeplink/main/addon/src/icon.png" width="20"> | [Deeplink](https://github.com/godot-mobile-plugins/godot-deeplink) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-deeplink/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-deeplink?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-deeplink?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-deeplink?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/icon.png" width="20"> | [Firebase](https://github.com/godot-mobile-plugins/godot-firebase) | ✅ | ✅ | - <!-- <a href="https://github.com/godot-mobile-plugins/godot-firebase/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-firebase?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-firebase?label=%20" /></a> --> | - <!-- <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/total?label=%20" /> --> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-firebase?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-inapp-review/main/addon/src/icon.png" width="20"> | [In-App Review](https://github.com/godot-mobile-plugins/godot-inapp-review) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-inapp-review/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-inapp-review?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-inapp-review?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-inapp-review?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> | [Native Camera](https://github.com/godot-mobile-plugins/godot-native-camera) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-native-camera/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-native-camera?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-native-camera?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-native-camera?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> | [Notification Scheduler](https://github.com/godot-mobile-plugins/godot-notification-scheduler) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-notification-scheduler/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-notification-scheduler?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-notification-scheduler?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-notification-scheduler?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> | [OAuth 2.0](https://github.com/godot-mobile-plugins/godot-oauth2) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-oauth2/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-oauth2?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-oauth2?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-oauth2?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-qr/main/addon/src/icon.png" width="20"> | [QR](https://github.com/godot-mobile-plugins/godot-qr) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-qr/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-qr?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-qr?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-qr?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-share/main/addon/src/icon.png" width="20"> | [Share](https://github.com/godot-mobile-plugins/godot-share) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-share/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-share?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-share?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-share?style=plastic&label=%20" /> |

<br>

<a name="credits"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> Credits

Developed by [Cengiz](https://github.com/cengiz-pz)

Based on [Godot Mobile Plugin Template v5](https://github.com/godot-mobile-plugins/godot-plugin-template/tree/v5)

Original repository: [Godot Native Camera Plugin](https://github.com/godot-mobile-plugins/godot-native-camera)

<br>

<a name="contributing"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="24"> Contributing

Contributions are welcome. Please see the [contributing guide](https://github.com/godot-mobile-plugins/godot-native-camera?tab=contributing-ov-file) in the repository for details.

<br>

# 💖 Support the Project

If this plugin has helped you, consider supporting its development! Every bit of support helps keep the plugin updated and bug-free.

| ✦ | Ways to Help | How to do it |
| :--- | :--- | :--- |
|✨⭐| **Spread the Word** | [Star this repo](https://github.com/godot-mobile-plugins/godot-native-camera/stargazers) to help others find it. |
|💡✨| **Give Feedback** | [Open an issue](https://github.com/godot-mobile-plugins/godot-native-camera/issues) or [suggest a feature](https://github.com/godot-mobile-plugins/godot-native-camera/issues/new). |
|🧩| **Contribute** | [Submit a PR](https://github.com/godot-mobile-plugins/godot-native-camera?tab=contributing-ov-file) to help improve the codebase. |
|❤️| **Buy a Coffee** | Support the maintainers on GitHub Sponsors or other platforms. |

<br>

## ⭐ Star History
[![Star History Chart](https://api.star-history.com/svg?repos=godot-mobile-plugins/godot-native-camera&type=Date)](https://star-history.com/#godot-mobile-plugins/godot-native-camera&Date)
