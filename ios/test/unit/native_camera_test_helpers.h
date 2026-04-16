//
// © 2026-present https://github.com/cengiz-pz
//
// native_camera_test_helpers.h
// Shared helpers for ObjC++ unit tests.
//
// These tests compile as part of a Godot engine build; Godot's core headers
// (Dictionary, Array, String, PackedByteArray, Variant) must be reachable on
// the include path (e.g. via SCons or CMake with godot-cpp).
//
// Build note:
//   Add this directory to CPPPATH alongside the plugin sources.
//   Ensure `godot-cpp/include` and `godot-cpp/gen/include` are on the path.
//

#ifndef native_camera_test_helpers_h
#define native_camera_test_helpers_h

#import <Foundation/Foundation.h>
#include <XCTest/XCTest.h>

#include "core/variant/dictionary.h"
#include "core/variant/array.h"
#include "core/string/ustring.h"

// ---------------------------------------------------------------------------
// Dictionary helpers
// ---------------------------------------------------------------------------

/// Returns the String value for @p key, or an empty String if absent/wrong type.
static inline String dict_get_string(const Dictionary &d, const String &key) {
    if (!d.has(key)) return String();
    Variant v = d[key];
    if (v.get_type() != Variant::STRING) return String();
    return v;
}

/// Returns the int value for @p key, or @p fallback if absent/wrong type.
static inline int dict_get_int(const Dictionary &d, const String &key, int fallback = 0) {
    if (!d.has(key)) return fallback;
    Variant v = d[key];
    if (v.get_type() != Variant::INT) return fallback;
    return (int)(int64_t)v;
}

/// Returns the bool value for @p key, or @p fallback if absent/wrong type.
static inline bool dict_get_bool(const Dictionary &d, const String &key, bool fallback = false) {
    if (!d.has(key)) return fallback;
    Variant v = d[key];
    if (v.get_type() != Variant::BOOL) return fallback;
    return (bool)v;
}

// ---------------------------------------------------------------------------
// XCTAssert wrappers for Godot types
// ---------------------------------------------------------------------------

#define XCTAssertGodotStringEqual(actual, expected, ...) \
    XCTAssertEqualObjects( \
        [NSString stringWithUTF8String:(actual).utf8().get_data()], \
        [NSString stringWithUTF8String:(expected).utf8().get_data()], \
        ##__VA_ARGS__)

#define XCTAssertDictHasKey(dict, key, ...) \
    XCTAssertTrue((dict).has(key), ##__VA_ARGS__)

#define XCTAssertDictKeyAbsent(dict, key, ...) \
    XCTAssertFalse((dict).has(key), ##__VA_ARGS__)

#endif /* native_camera_test_helpers_h */
