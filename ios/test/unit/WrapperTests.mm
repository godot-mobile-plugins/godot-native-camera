//
// © 2026-present https://github.com/cengiz-pz
//
// WrapperTests.mm
// Unit tests for CameraInfoWrapper, FrameInfoWrapper, and FrameSizeWrapper.
// Each test exercises buildRawData and verifies Godot Dictionary/Array contents.
//
// Build requirement: Godot core headers on CPPPATH (see native_camera_test_helpers.h).
//

#import <XCTest/XCTest.h>

#include "core/variant/dictionary.h"
#include "core/variant/array.h"
#include "core/variant/variant.h"
#include "core/string/ustring.h"
#include "core/templates/vector.h"

#import "camera_info_wrapper.h"
#import "frame_info_wrapper.h"
#import "frame_size_wrapper.h"
#import "native_camera_test_helpers.h"
#import "native_camera_plugin-Swift.h"

// ---------------------------------------------------------------------------
// Fixture Factories
// ---------------------------------------------------------------------------

static FrameSize *make_frame_size(int w, int h) {
    return [[FrameSize alloc] initWithWidth:w height:h];
}

static FrameInfo *make_frame_info(int w, int h, int rotation, BOOL grayscale) {
    int count        = grayscale ? w * h : w * h * 4;
    NSMutableData *buf = [NSMutableData dataWithLength:count];
    uint8_t *bytes   = (uint8_t *)buf.mutableBytes;
    for (int i = 0; i < count; ++i) bytes[i] = (uint8_t)(i % 256);
    return [[FrameInfo alloc] initWithBuffer:buf width:w height:h rotation:rotation isGrayscale:grayscale];
}

/// Build a minimal CameraInfo with one output size – does NOT need a real AVCaptureDevice
/// because CameraInfo stores the device reference but the wrapper only reads `id` and `outputSizes`.
/// We pass nil for device; accessing device.position will crash, so CameraInfoWrapper tests
/// using isFrontFacing must provide a real device or be skipped on Simulator.
static CameraInfo *make_camera_info_without_device(NSString *cameraId, NSArray<FrameSize *> *sizes) {
    // Construct with nil device – only safe when the test doesn't call buildRawData
    // (which reads device.position). Use make_camera_info_with_back_position for full tests.
    return [[CameraInfo alloc] initWithId:cameraId device:nil outputSizes:sizes];
}

// ---------------------------------------------------------------------------
// FrameSizeWrapper Tests
// ---------------------------------------------------------------------------

@interface FrameSizeWrapperTests : XCTestCase
@end

@implementation FrameSizeWrapperTests

- (void)test_buildRawData_containsWidthKey {
    FrameSizeWrapper *w = [[FrameSizeWrapper alloc] initWithFrameSize:make_frame_size(1280, 720)];
    Dictionary d = [w buildRawData];
    XCTAssertDictHasKey(d, String("width"));
}

- (void)test_buildRawData_containsHeightKey {
    FrameSizeWrapper *w = [[FrameSizeWrapper alloc] initWithFrameSize:make_frame_size(1280, 720)];
    Dictionary d = [w buildRawData];
    XCTAssertDictHasKey(d, String("height"));
}

- (void)test_buildRawData_widthValue_isCorrect {
    FrameSizeWrapper *w = [[FrameSizeWrapper alloc] initWithFrameSize:make_frame_size(1920, 1080)];
    Dictionary d = [w buildRawData];
    XCTAssertEqual(dict_get_int(d, String("width")), 1920);
}

- (void)test_buildRawData_heightValue_isCorrect {
    FrameSizeWrapper *w = [[FrameSizeWrapper alloc] initWithFrameSize:make_frame_size(1920, 1080)];
    Dictionary d = [w buildRawData];
    XCTAssertEqual(dict_get_int(d, String("height")), 1080);
}

- (void)test_buildRawData_zeroSize_isPreserved {
    FrameSizeWrapper *w = [[FrameSizeWrapper alloc] initWithFrameSize:make_frame_size(0, 0)];
    Dictionary d = [w buildRawData];
    XCTAssertEqual(dict_get_int(d, String("width")),  0);
    XCTAssertEqual(dict_get_int(d, String("height")), 0);
}

- (void)test_buildRawData_exactlyTwoKeys {
    FrameSizeWrapper *w = [[FrameSizeWrapper alloc] initWithFrameSize:make_frame_size(640, 480)];
    Dictionary d = [w buildRawData];
    XCTAssertEqual(d.size(), 2);
}

- (void)test_buildRawData_calledTwice_returnsSameValues {
    FrameSizeWrapper *w = [[FrameSizeWrapper alloc] initWithFrameSize:make_frame_size(800, 600)];
    Dictionary d1 = [w buildRawData];
    Dictionary d2 = [w buildRawData];
    XCTAssertEqual(dict_get_int(d1, String("width")),  dict_get_int(d2, String("width")));
    XCTAssertEqual(dict_get_int(d1, String("height")), dict_get_int(d2, String("height")));
}

@end

// ---------------------------------------------------------------------------
// FrameInfoWrapper Tests
// ---------------------------------------------------------------------------

@interface FrameInfoWrapperTests : XCTestCase
@end

@implementation FrameInfoWrapperTests

// MARK: Key presence

- (void)test_buildRawData_containsBufferKey {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, NO)];
    XCTAssertDictHasKey([w buildRawData], String("buffer"));
}

- (void)test_buildRawData_containsWidthKey {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, NO)];
    XCTAssertDictHasKey([w buildRawData], String("width"));
}

- (void)test_buildRawData_containsHeightKey {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, NO)];
    XCTAssertDictHasKey([w buildRawData], String("height"));
}

- (void)test_buildRawData_containsRotationKey {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, NO)];
    XCTAssertDictHasKey([w buildRawData], String("rotation"));
}

- (void)test_buildRawData_containsIsGrayscaleKey {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, NO)];
    XCTAssertDictHasKey([w buildRawData], String("is_grayscale"));
}

// MARK: Dimension values

- (void)test_buildRawData_width_matchesFrameInfo {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(640, 480, 0, NO)];
    XCTAssertEqual(dict_get_int([w buildRawData], String("width")), 640);
}

- (void)test_buildRawData_height_matchesFrameInfo {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(640, 480, 0, NO)];
    XCTAssertEqual(dict_get_int([w buildRawData], String("height")), 480);
}

// MARK: Rotation

- (void)test_buildRawData_rotation90_isPreserved {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 90, NO)];
    XCTAssertEqual(dict_get_int([w buildRawData], String("rotation")), 90);
}

- (void)test_buildRawData_rotation270_isPreserved {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 270, NO)];
    XCTAssertEqual(dict_get_int([w buildRawData], String("rotation")), 270);
}

// MARK: isGrayscale

- (void)test_buildRawData_isGrayscaleFalse_isPreserved {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, NO)];
    XCTAssertFalse(dict_get_bool([w buildRawData], String("is_grayscale")));
}

- (void)test_buildRawData_isGrayscaleTrue_isPreserved {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, YES)];
    XCTAssertTrue(dict_get_bool([w buildRawData], String("is_grayscale")));
}

// MARK: Buffer contents

- (void)test_buildRawData_buffer_isPackedByteArray {
    FrameInfoWrapper *w  = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, NO)];
    Dictionary d         = [w buildRawData];
    Variant bufVariant   = d[String("buffer")];
    XCTAssertEqual(bufVariant.get_type(), Variant::PACKED_BYTE_ARRAY);
}

- (void)test_buildRawData_rgbaBuffer_sizeMatchesWidthTimesHeightTimesFour {
    int w = 8, h = 6;
    FrameInfoWrapper *wrapper = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(w, h, 0, NO)];
    Dictionary d              = [wrapper buildRawData];
    PackedByteArray buf       = d[String("buffer")];
    XCTAssertEqual((int)buf.size(), w * h * 4);
}

- (void)test_buildRawData_grayscaleBuffer_sizeMatchesWidthTimesHeight {
    int w = 8, h = 6;
    FrameInfoWrapper *wrapper = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(w, h, 0, YES)];
    Dictionary d              = [wrapper buildRawData];
    PackedByteArray buf       = d[String("buffer")];
    XCTAssertEqual((int)buf.size(), w * h);
}

- (void)test_buildRawData_buffer_firstByteMatchesSource {
    // Source ramp: byte i = i%256. First byte = 0.
    FrameInfoWrapper *w  = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, YES)];
    PackedByteArray buf  = [w buildRawData][String("buffer")];
    XCTAssertEqual(buf[0], 0);
}

- (void)test_buildRawData_exactlyFiveKeys {
    FrameInfoWrapper *w = [[FrameInfoWrapper alloc] initWithFrameInfo:make_frame_info(4, 4, 0, NO)];
    XCTAssertEqual([w buildRawData].size(), 5);
}

@end

// ---------------------------------------------------------------------------
// CameraInfoWrapper Tests
// ---------------------------------------------------------------------------

@interface CameraInfoWrapperTests : XCTestCase
@end

@implementation CameraInfoWrapperTests

// MARK: Key presence (device = nil, is_front_facing derivation is skipped)

- (void)test_buildRawData_containsCameraIdKey {
    NSArray *sizes = @[make_frame_size(1280, 720)];
    // Use a real device from AVCaptureDevice when available; otherwise skip isFrontFacing sub-test.
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!dev) { XCTSkip(@"No camera available on this host"); }

    CameraInfo *info     = [[CameraInfo alloc] initWithId:@"test-id" device:dev outputSizes:sizes];
    CameraInfoWrapper *w = [[CameraInfoWrapper alloc] initWithCameraInfo:info];
    XCTAssertDictHasKey([w buildRawData], String("camera_id"));
}

- (void)test_buildRawData_containsIsFrontFacingKey {
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!dev) { XCTSkip(@"No camera available on this host"); }
    NSArray *sizes   = @[make_frame_size(640, 480)];
    CameraInfo *info = [[CameraInfo alloc] initWithId:@"id" device:dev outputSizes:sizes];
    XCTAssertDictHasKey([[CameraInfoWrapper alloc] initWithCameraInfo:info].buildRawData,
                        String("is_front_facing"));
}

- (void)test_buildRawData_containsOutputSizesKey {
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!dev) { XCTSkip(@"No camera available on this host"); }
    NSArray *sizes   = @[make_frame_size(640, 480)];
    CameraInfo *info = [[CameraInfo alloc] initWithId:@"id" device:dev outputSizes:sizes];
    XCTAssertDictHasKey([[CameraInfoWrapper alloc] initWithCameraInfo:info].buildRawData,
                        String("output_sizes"));
}

// MARK: camera_id value

- (void)test_buildRawData_cameraId_matchesInput {
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!dev) { XCTSkip(@"No camera available on this host"); }
    NSArray *sizes   = @[make_frame_size(1280, 720)];
    CameraInfo *info = [[CameraInfo alloc] initWithId:@"my-unique-camera-id" device:dev outputSizes:sizes];
    Dictionary d     = [[CameraInfoWrapper alloc] initWithCameraInfo:info].buildRawData;
    XCTAssertGodotStringEqual(dict_get_string(d, String("camera_id")), String("my-unique-camera-id"));
}

// MARK: output_sizes array

- (void)test_buildRawData_outputSizes_isArray {
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!dev) { XCTSkip(@"No camera available on this host"); }
    NSArray *sizes   = @[make_frame_size(640, 480), make_frame_size(1280, 720)];
    CameraInfo *info = [[CameraInfo alloc] initWithId:@"id" device:dev outputSizes:sizes];
    Dictionary d     = [[CameraInfoWrapper alloc] initWithCameraInfo:info].buildRawData;
    Variant sizesVar = d[String("output_sizes")];
    XCTAssertEqual(sizesVar.get_type(), Variant::ARRAY);
}

- (void)test_buildRawData_outputSizes_countMatchesInput {
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!dev) { XCTSkip(@"No camera available on this host"); }
    NSArray *sizes   = @[make_frame_size(640, 480), make_frame_size(1280, 720), make_frame_size(1920, 1080)];
    CameraInfo *info = [[CameraInfo alloc] initWithId:@"id" device:dev outputSizes:sizes];
    Dictionary d     = [[CameraInfoWrapper alloc] initWithCameraInfo:info].buildRawData;
    Array godotSizes = (Array)d[String("output_sizes")];
    XCTAssertEqual((int)godotSizes.size(), 3);
}

- (void)test_buildRawData_outputSizes_emptyArray_yieldsEmptyGodotArray {
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!dev) { XCTSkip(@"No camera available on this host"); }
    CameraInfo *info = [[CameraInfo alloc] initWithId:@"id" device:dev outputSizes:@[]];
    Dictionary d     = [[CameraInfoWrapper alloc] initWithCameraInfo:info].buildRawData;
    Array godotSizes = (Array)d[String("output_sizes")];
    XCTAssertEqual((int)godotSizes.size(), 0);
}

- (void)test_buildRawData_outputSizes_firstEntry_hasWidthAndHeight {
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!dev) { XCTSkip(@"No camera available on this host"); }
    NSArray *sizes   = @[make_frame_size(320, 240)];
    CameraInfo *info = [[CameraInfo alloc] initWithId:@"id" device:dev outputSizes:sizes];
    Dictionary d     = [[CameraInfoWrapper alloc] initWithCameraInfo:info].buildRawData;
    Array godotSizes = (Array)d[String("output_sizes")];
    Dictionary first = (Dictionary)godotSizes[0];
    XCTAssertDictHasKey(first, String("width"));
    XCTAssertDictHasKey(first, String("height"));
    XCTAssertEqual(dict_get_int(first, String("width")),  320);
    XCTAssertEqual(dict_get_int(first, String("height")), 240);
}

- (void)test_buildRawData_exactlyThreeKeys {
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!dev) { XCTSkip(@"No camera available on this host"); }
    CameraInfo *info = [[CameraInfo alloc] initWithId:@"id" device:dev outputSizes:@[]];
    XCTAssertEqual([[CameraInfoWrapper alloc] initWithCameraInfo:info].buildRawData.size(), 3);
}

@end
