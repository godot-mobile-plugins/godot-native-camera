//
// © 2026-present https://github.com/cengiz-pz
//

#ifndef frame_request_h
#define frame_request_h

#import <Foundation/Foundation.h>

@interface FrameRequest : NSObject

- (instancetype)initWithRawData:(void *)data;

- (NSString *)cameraId;

- (NSInteger)width;

- (NSInteger)height;

- (NSInteger)framesToSkip;

- (NSInteger)rotation;

- (BOOL)isGrayscale;

- (BOOL)isMirrorHorizontal;

- (BOOL)isMirrorVertical;

/**
 * Target width (pixels) to scale the post-processed frame to.
 * Returns 0 when the key is absent, meaning scaling is disabled on this axis.
 * Scaling is only performed when both scaleWidth and scaleHeight are non-zero.
 */
- (NSInteger)scaleWidth;

/**
 * Target height (pixels) to scale the post-processed frame to.
 * Returns 0 when the key is absent, meaning scaling is disabled on this axis.
 * Scaling is only performed when both scaleWidth and scaleHeight are non-zero.
 */
- (NSInteger)scaleHeight;

@end

#endif /* frame_request_h */
