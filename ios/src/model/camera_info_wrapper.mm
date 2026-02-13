//
// © 2026-present https://github.com/cengiz-pz
//

#import "camera_info_wrapper.h"

#import "frame_size_wrapper.h"


@implementation CameraInfoWrapper

static String const kCameraIdProperty = "camera_id";
static String const kIsFrontFacingProperty = "is_front_facing";
static String const kOutputSizesProperty = "output_sizes";

- (instancetype) initWithCameraInfo:(CameraInfo *)cameraInfo {
	self = [super init];
	if (self) {
		_cameraInfo = cameraInfo;
	}
	return self;
}

- (Dictionary) buildRawData {
	Dictionary dict = Dictionary();

	dict[kCameraIdProperty] = [self.cameraInfo.id UTF8String];

	bool is_front_facing = (self.cameraInfo.device.position == AVCaptureDevicePositionFront);
	dict[kIsFrontFacingProperty] = is_front_facing;

	Array dictArray = Array();

	for (FrameSize *frameSize in self.cameraInfo.outputSizes) {
		FrameSizeWrapper* wrapper = [[FrameSizeWrapper alloc] initWithFrameSize:frameSize];
		dictArray.append([wrapper buildRawData]);
	}

	dict[kOutputSizesProperty] = dictArray;

	return dict;
}

@end
