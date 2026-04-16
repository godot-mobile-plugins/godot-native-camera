//
// © 2026-present https://github.com/cengiz-pz
//
// FrameRequestTests.mm
// Unit tests for FrameRequest: verifies that it correctly reads values from a
// Godot Dictionary and falls back to safe defaults when keys are missing.
//
// Build requirement: Godot core headers on CPPPATH (see native_camera_test_helpers.h).
//

#import <XCTest/XCTest.h>

#include "core/variant/dictionary.h"
#include "core/variant/variant.h"
#include "core/string/ustring.h"

#import "frame_request.h"
#import "native_camera_test_helpers.h"

// ---------------------------------------------------------------------------
// Helpers – build typed Godot Dictionaries from plain C values
// ---------------------------------------------------------------------------

static Dictionary make_full_request_dict() {
    Dictionary d;
    d[String("camera_id")]     = String("test-camera-id-42");
    d[String("width")]         = (int64_t)1280;
    d[String("height")]        = (int64_t)720;
    d[String("frames_to_skip")] = (int64_t)3;
    d[String("rotation")]      = (int64_t)270;
    d[String("is_grayscale")]  = true;
    return d;
}

static Dictionary make_empty_dict() {
    return Dictionary();
}

static Dictionary make_partial_dict_camera_only() {
    Dictionary d;
    d[String("camera_id")] = String("only-camera");
    return d;
}

// ---------------------------------------------------------------------------
// Test Suite
// ---------------------------------------------------------------------------

@interface FrameRequestTests : XCTestCase
@end

@implementation FrameRequestTests

// MARK: - Full dictionary

- (void)test_cameraId_fullDict_returnsCorrectString {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_full_request_dict()];
    XCTAssertEqualObjects(req.cameraId, @"test-camera-id-42");
}

- (void)test_width_fullDict_returnsCorrectValue {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_full_request_dict()];
    XCTAssertEqual(req.width, 1280);
}

- (void)test_height_fullDict_returnsCorrectValue {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_full_request_dict()];
    XCTAssertEqual(req.height, 720);
}

- (void)test_framesToSkip_fullDict_returnsCorrectValue {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_full_request_dict()];
    XCTAssertEqual(req.framesToSkip, 3);
}

- (void)test_rotation_fullDict_returnsCorrectValue {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_full_request_dict()];
    XCTAssertEqual(req.rotation, 270);
}

- (void)test_isGrayscale_fullDict_returnsTrue {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_full_request_dict()];
    XCTAssertTrue(req.isGrayscale);
}

// MARK: - Empty dictionary → defaults

- (void)test_cameraId_emptyDict_returnsEmptyString {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_empty_dict()];
    XCTAssertEqualObjects(req.cameraId, @"");
}

- (void)test_width_emptyDict_returns640 {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_empty_dict()];
    XCTAssertEqual(req.width, 640);
}

- (void)test_height_emptyDict_returns480 {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_empty_dict()];
    XCTAssertEqual(req.height, 480);
}

- (void)test_framesToSkip_emptyDict_returnsZero {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_empty_dict()];
    XCTAssertEqual(req.framesToSkip, 0);
}

- (void)test_rotation_emptyDict_returnsZero {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_empty_dict()];
    XCTAssertEqual(req.rotation, 0);
}

- (void)test_isGrayscale_emptyDict_returnsFalse {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_empty_dict()];
    XCTAssertFalse(req.isGrayscale);
}

// MARK: - Partial dictionary

- (void)test_cameraId_partialDict_returnsValue {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_partial_dict_camera_only()];
    XCTAssertEqualObjects(req.cameraId, @"only-camera");
}

- (void)test_missingNumericKeys_fallBackToDefaults {
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:make_partial_dict_camera_only()];
    XCTAssertEqual(req.width,        640);
    XCTAssertEqual(req.height,       480);
    XCTAssertEqual(req.framesToSkip, 0);
    XCTAssertEqual(req.rotation,     0);
    XCTAssertFalse(req.isGrayscale);
}

// MARK: - Boolean variants

- (void)test_isGrayscale_falseExplicit_returnsFalse {
    Dictionary d;
    d[String("is_grayscale")] = false;
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:d];
    XCTAssertFalse(req.isGrayscale);
}

- (void)test_isGrayscale_trueExplicit_returnsTrue {
    Dictionary d;
    d[String("is_grayscale")] = true;
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:d];
    XCTAssertTrue(req.isGrayscale);
}

// MARK: - Boundary / edge values

- (void)test_width_zeroValue_isPreserved {
    Dictionary d;
    d[String("width")] = (int64_t)0;
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:d];
    XCTAssertEqual(req.width, 0);
}

- (void)test_framesToSkip_largeValue_isPreserved {
    Dictionary d;
    d[String("frames_to_skip")] = (int64_t)120;
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:d];
    XCTAssertEqual(req.framesToSkip, 120);
}

- (void)test_rotation_allCardinalAngles_arePreserved {
    for (int angle : {0, 90, 180, 270}) {
        Dictionary d;
        d[String("rotation")] = (int64_t)angle;
        FrameRequest *req = [[FrameRequest alloc] initWithDictionary:d];
        XCTAssertEqual(req.rotation, angle,
                       @"Rotation angle %d not preserved", angle);
    }
}

// MARK: - Unicode camera ID

- (void)test_cameraId_unicodeCharacters_roundTrip {
    Dictionary d;
    // Use String::utf8() to explicitly parse the C-string literal as UTF-8
    d[String("camera_id")] = String::utf8("カメラ:0");
    FrameRequest *req = [[FrameRequest alloc] initWithDictionary:d];
    XCTAssertEqualObjects(req.cameraId, @"カメラ:0");
}

@end
