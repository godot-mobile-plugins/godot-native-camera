//
// © 2026-present https://github.com/cengiz-pz
//

#import "native_camera_plugin.h"

#import "native_camera_plugin-Swift.h"
#import "frame_request.h"
#import "camera_info_wrapper.h"
#import "frame_info_wrapper.h"
#import "native_camera_logger.h"

const String CAMERA_PERMISSION_GRANTED_SIGNAL = "camera_permission_granted";
const String CAMERA_PERMISSION_DENIED_SIGNAL = "camera_permission_denied";
const String FRAME_AVAILABLE_SIGNAL = "frame_available";

NativeCameraPlugin* NativeCameraPlugin::instance = NULL;
static NativeCamera* swiftCamera = nil;

void NativeCameraPlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("has_camera_permission"), &NativeCameraPlugin::has_camera_permission);
	ClassDB::bind_method(D_METHOD("request_camera_permission"), &NativeCameraPlugin::request_camera_permission);
	ClassDB::bind_method(D_METHOD("get_all_cameras"), &NativeCameraPlugin::get_all_cameras);
	ClassDB::bind_method(D_METHOD("start", "request"), &NativeCameraPlugin::start);
	ClassDB::bind_method(D_METHOD("stop"), &NativeCameraPlugin::stop);

	ADD_SIGNAL(MethodInfo(CAMERA_PERMISSION_GRANTED_SIGNAL));
	ADD_SIGNAL(MethodInfo(CAMERA_PERMISSION_DENIED_SIGNAL));
	ADD_SIGNAL(MethodInfo(FRAME_AVAILABLE_SIGNAL, PropertyInfo(Variant::DICTIONARY, "frame_info")));
}

bool NativeCameraPlugin::has_camera_permission() {
	return [NativeCamera hasPermission];
}

void NativeCameraPlugin::request_camera_permission() {
	[swiftCamera requestPermission];
}

Array NativeCameraPlugin::get_all_cameras() {
	NSArray<CameraInfo*> *cameras = [swiftCamera getCameras];
	Array godotArray;

	for (CameraInfo *cam in cameras) {
		CameraInfoWrapper* wrapper = [[CameraInfoWrapper alloc] initWithCameraInfo:cam];
		godotArray.append([wrapper buildRawData]);
	}
	return godotArray;
}

void NativeCameraPlugin::start(Dictionary requestDict) {
	FrameRequest *req = [[FrameRequest alloc] initWithDictionary:requestDict];
	[swiftCamera startWithCameraId:req.cameraId 
							width:req.width 
							height:req.height 
							skip:req.framesToSkip 
							rot:req.rotation 
							gray:req.isGrayscale];
}

void NativeCameraPlugin::stop() {
	[swiftCamera stop];
}

NativeCameraPlugin::NativeCameraPlugin() {
	ERR_FAIL_COND(instance != NULL);
	instance = this;

	if (swiftCamera == nil) {
		swiftCamera = [[NativeCamera alloc] init];

		// Setup Swift callbacks
		swiftCamera.onFrameAvailable = ^(FrameInfo *info) {
			FrameInfoWrapper* wrapper = [[FrameInfoWrapper alloc] initWithFrameInfo:info];
			instance->emit_signal(FRAME_AVAILABLE_SIGNAL, [wrapper buildRawData]);
		};

		swiftCamera.onPermissionResult = ^(BOOL granted) {
			instance->emit_signal(granted ? CAMERA_PERMISSION_GRANTED_SIGNAL : CAMERA_PERMISSION_DENIED_SIGNAL);
		};
	}
}

NativeCameraPlugin::~NativeCameraPlugin() {
	if (instance == this) {
		[swiftCamera stop];
		instance = nullptr;
	}
}
