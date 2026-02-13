//
// © 2026-present https://github.com/cengiz-pz
//

#ifndef frame_info_wrapper_h
#define frame_info_wrapper_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#include "core/object/class_db.h"

#import "native_camera_plugin-Swift.h"


@interface FrameInfoWrapper : NSObject

@property (nonatomic, strong) FrameInfo *frameInfo;

- (instancetype) initWithFrameInfo:(FrameInfo *)frameInfo;

/**
 * Builds a Godot-compatible Dictionary containing the frame info
 * @return A Dictionary object with the frame info
 */
- (Dictionary)buildRawData;

@end

#endif /* frame_info_wrapper_h */
