//
// © 2026-present https://github.com/cengiz-pz
//

#import "frame_request.h"

@implementation FrameRequest

static String const kCameraIdProperty = "camera_id";
static String const kWidthProperty = "width";
static String const kHeightProperty = "height";
static String const kFramesToSkipProperty = "frames_to_skip";
static String const kRotationProperty = "rotation";
static String const kIsGrayscaleProperty = "is_grayscale";

- (instancetype) initWithDictionary:(Dictionary) data {
	if ((self = [super init])) {
		self.rawData = data;
	}
	return self;
}

- (NSString*) cameraId {
	return self.rawData.has(kCameraIdProperty) ? [NSString stringWithUTF8String:((String)self.rawData[kCameraIdProperty]).utf8().get_data()] : @"";
}

- (NSInteger) width {
	return self.rawData.has(kWidthProperty) ? (NSInteger) self.rawData[kWidthProperty].operator int64_t() : 640;
}

- (NSInteger) height {
	return self.rawData.has(kHeightProperty) ? (NSInteger) self.rawData[kHeightProperty].operator int64_t() : 480;
}

- (NSInteger) framesToSkip {
	return self.rawData.has(kFramesToSkipProperty) ? (NSInteger) self.rawData[kFramesToSkipProperty].operator int64_t() : 0;
}

- (NSInteger) rotation {
	return self.rawData.has(kRotationProperty) ? (NSInteger) self.rawData[kRotationProperty].operator int64_t() : 0;
}

- (BOOL) isGrayscale {
	return self.rawData.has(kIsGrayscaleProperty) ? (BOOL) self.rawData[kIsGrayscaleProperty] : NO;
}

@end
