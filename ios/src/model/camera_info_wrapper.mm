//
// © 2026-present https://github.com/cengiz-pz
//

#import "camera_info_wrapper.h"

#import "frame_size_wrapper.h"

@implementation CameraInfoWrapper

static String const kCameraIdProperty = "camera_id";
static String const kIsFrontFacingProperty = "is_front_facing";
static String const kOutputSizesProperty = "output_sizes";
static String const kSensorOrientationProperty = "sensor_orientation";

- (instancetype)initWithCameraInfo:(CameraInfo *)cameraInfo {
	self = [super init];
	if (self) {
		_cameraInfo = cameraInfo;
	}
	return self;
}

- (Dictionary)buildRawData {
	Dictionary dict = Dictionary();

	dict[kCameraIdProperty] = [self.cameraInfo.id UTF8String];

	bool is_front_facing = (self.cameraInfo.device.position == AVCaptureDevicePositionFront);
	dict[kIsFrontFacingProperty] = is_front_facing;

	Array dictArray = Array();

	for (FrameSize *frameSize in self.cameraInfo.outputSizes) {
		FrameSizeWrapper *wrapper = [[FrameSizeWrapper alloc] initWithFrameSize:frameSize];
		dictArray.append([wrapper buildRawData]);
	}

	dict[kOutputSizesProperty] = dictArray;

	// SENSOR_ORIENTATION is the clockwise angle (0, 90, 180, or 270 degrees) that
	// the camera image must be rotated to be upright when the device is in its
	// natural (portrait) orientation.  On iPhone this is always 90°; on some iPad
	// models it may be 0°.  Mirrors the Android Camera2 SENSOR_ORIENTATION field.
	dict[kSensorOrientationProperty] = (int)self.cameraInfo.sensorOrientation;

	return dict;
}

@end
