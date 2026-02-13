//
// © 2026-present https://github.com/cengiz-pz
//

#ifndef frame_size_wrapper_h
#define frame_size_wrapper_h

#import <Foundation/Foundation.h>

#include "core/object/class_db.h"

#import "native_camera_plugin-Swift.h"


@interface FrameSizeWrapper : NSObject

@property (nonatomic, strong) FrameSize *frameSize;

- (instancetype) initWithFrameSize:(FrameSize *)frameSize;

/**
 * Builds a Godot-compatible Dictionary containing the frame size data
 * @return A Dictionary object with the frame size
 */
- (Dictionary) buildRawData;

@end

#endif /* frame_size_wrapper_h */
