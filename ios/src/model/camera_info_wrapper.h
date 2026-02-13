//
// © 2026-present https://github.com/cengiz-pz
//

#ifndef camera_info_wrapper_h
#define camera_info_wrapper_h

#import <Foundation/Foundation.h>

#include "core/object/class_db.h"

#import "native_camera_plugin-Swift.h"


@interface CameraInfoWrapper : NSObject

@property (nonatomic, strong) CameraInfo *cameraInfo;

- (instancetype) initWithCameraInfo:(CameraInfo *)cameraInfo;

/**
 * Builds a Godot-compatible Dictionary containing the camera info
 * @return A Dictionary object with the camera info
 */
- (Dictionary) buildRawData;

@end

#endif /* camera_info_wrapper_h */
