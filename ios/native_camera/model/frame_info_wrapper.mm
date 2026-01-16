//
// © 2026-present https://github.com/cengiz-pz
//

#import "frame_info_wrapper.h"


@implementation FrameInfoWrapper

static String const kBufferProperty = "buffer";
static String const kWidthProperty = "width";
static String const kHeightProperty = "height";
static String const kRotationProperty = "rotation";
static String const kIsGrayscaleProperty = "is_grayscale";

- (instancetype) initWithFrameInfo:(FrameInfo *)frameInfo {
	self = [super init];
	if (self) {
		_frameInfo = frameInfo;
	}
	return self;
}

- (Dictionary) buildRawData {
	Dictionary dict = Dictionary();

	// Convert NSData to Godot's PackedByteArray
	PackedByteArray godotBuffer;
	godotBuffer.resize(self.frameInfo.buffer.length);

	// Copy the data from the NSData buffer into the Godot byte array
	memcpy(godotBuffer.ptrw(), self.frameInfo.buffer.bytes, self.frameInfo.buffer.length);

	dict[kBufferProperty] = godotBuffer;

	dict[kWidthProperty] = (int) self.frameInfo.width;
	dict[kHeightProperty] = (int) self.frameInfo.height;
	dict[kRotationProperty] = (int) self.frameInfo.rotation;
	dict[kIsGrayscaleProperty] = (bool) self.frameInfo.isGrayscale;

	return dict;
}

@end
