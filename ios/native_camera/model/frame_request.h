//
// © 2026-present https://github.com/cengiz-pz
//

#ifndef frame_request_h
#define frame_request_h

#import <Foundation/Foundation.h>

#include "core/object/class_db.h"


@interface FrameRequest : NSObject

@property (nonatomic, assign) Dictionary rawData;

- (instancetype) initWithDictionary:(Dictionary) data;

- (NSString*) cameraId;

- (NSInteger) width;

- (NSInteger) height;

- (NSInteger) framesToSkip;

- (NSInteger) rotation;

- (BOOL) isGrayscale;

@end

#endif /* frame_request_h */
