//
// © 2026-present https://github.com/cengiz-pz
//

#import "frame_size_wrapper.h"


static String const kWidthProperty = "width";
static String const kHeightProperty = "height";


@implementation FrameSizeWrapper

- (instancetype) initWithFrameSize:(FrameSize *)frameSize {
	self = [super init];
	if (self) {
		_frameSize = frameSize;
	}
	return self;
}

- (Dictionary) buildRawData {
	Dictionary dict = Dictionary();

	dict[kWidthProperty] = (int) self.frameSize.width;
	dict[kHeightProperty] = (int) self.frameSize.height;

	return dict;
}

@end
