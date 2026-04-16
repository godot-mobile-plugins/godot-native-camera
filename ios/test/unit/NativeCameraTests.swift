//
// © 2026-present https://github.com/cengiz-pz
//
// NativeCameraTests.swift
// XCTest suite for the Swift layer of NativeCameraPlugin.
//
// Build target: NativeCameraPluginTests (iOS unit test target)
// Required: Add NativeCameraPlugin module to the test target's Host Application.
//

import AVFoundation
@testable import native_camera_plugin
import XCTest

// MARK: - FrameSize Tests

final class FrameSizeTests: XCTestCase {

	func test_init_storesWidthAndHeight() {
		let size = FrameSize(width: 1920, height: 1080)
		XCTAssertEqual(size.width, 1920)
		XCTAssertEqual(size.height, 1080)
	}

	func test_init_zeroValues_areAllowed() {
		let size = FrameSize(width: 0, height: 0)
		XCTAssertEqual(size.width, 0)
		XCTAssertEqual(size.height, 0)
	}

	func test_init_largeValues_arePreserved() {
		let size = FrameSize(width: 7680, height: 4320) // 8K
		XCTAssertEqual(size.width, 7680)
		XCTAssertEqual(size.height, 4320)
	}

	func test_fixture_hd_hasCorrectedDimensions() {
		XCTAssertEqual(FrameSizeFixture.hd.width, 1280)
		XCTAssertEqual(FrameSizeFixture.hd.height, 720)
	}

	func test_fixture_square_hasEqualDimensions() {
		let s = FrameSizeFixture.square
		XCTAssertEqual(s.width, s.height)
	}
}

// MARK: - FrameInfo Tests

final class FrameInfoTests: XCTestCase {

	func test_init_storesAllProperties() {
		let buffer   = Data([0x01, 0x02, 0x03, 0x04])
		let info     = FrameInfo(buffer: buffer, width: 2, height: 2, rotation: 90, isGrayscale: true)

		XCTAssertEqual(info.buffer, buffer)
		XCTAssertEqual(info.width, 2)
		XCTAssertEqual(info.height, 2)
		XCTAssertEqual(info.rotation, 90)
		XCTAssertTrue(info.isGrayscale)
	}

	func test_init_isGrayscaleFalse_byDefault() {
		let info = FrameInfoFixture.make()
		XCTAssertFalse(info.isGrayscale)
	}

	func test_init_rgbaBuffer_hasFourBytesPerPixel() {
		let w = 8, h = 6
		let info = FrameInfoFixture.make(width: w, height: h, isGrayscale: false)
		XCTAssertEqual(info.buffer.count, w * h * 4)
	}

	func test_init_grayscaleBuffer_hasOneBytesPerPixel() {
		let w = 8, h = 6
		let info = FrameInfoFixture.make(width: w, height: h, isGrayscale: true)
		XCTAssertEqual(info.buffer.count, w * h)
	}

	func test_buffer_isNotMutated_afterInit() {
		var source = Data([10, 20, 30, 40])
		let info   = FrameInfo(buffer: source, width: 2, height: 2, rotation: 0, isGrayscale: true)
		source[0]  = 99 // mutate original
		XCTAssertEqual(info.buffer[0], 10, "FrameInfo should own its buffer copy")
	}

	func test_rotation_acceptsAllCardinalAngles() {
		for angle in [0, 90, 180, 270] {
			let info = FrameInfoFixture.make(rotation: angle)
			XCTAssertEqual(info.rotation, angle)
		}
	}
}

// MARK: - NativeCamera Rotation Tests

/// Tests NativeCamera.rotateData(_:w:h:degrees:gray:) in isolation.
///
/// The method is `internal`, so it is accessible within the test module
/// via `@testable import NativeCameraPlugin`.
final class NativeCameraRotationTests: XCTestCase {

	private let camera = NativeCamera()

	// MARK: Identity

	func test_rotate_zeroDegrees_returnsUnchangedData() {
		let result = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: 0, gray: true)
		XCTAssertEqual(result.data, PixelBufferFixture.gray2x2)
		XCTAssertEqual(result.w, 2)
		XCTAssertEqual(result.h, 2)
	}

	func test_rotate_360Degrees_equalsIdentity() {
		let result = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: 360, gray: true)
		XCTAssertEqual(result.data, PixelBufferFixture.gray2x2)
	}

	func test_rotate_negativeAngle_normalises_correctly() {
		// -90° ≡ 270°
		let result270 = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: 270, gray: true)
		let resultNeg = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: -90, gray: true)
		XCTAssertEqual(result270.data, resultNeg.data)
	}

	// MARK: Grayscale – 2×2

	func test_rotate_gray_90CW_pixelOrder() {
		let result = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: 90, gray: true)
		XCTAssertEqual([UInt8](result.data), [UInt8](PixelBufferFixture.gray2x2After90))
	}

	func test_rotate_gray_180_pixelOrder() {
		let result = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: 180, gray: true)
		XCTAssertEqual([UInt8](result.data), [UInt8](PixelBufferFixture.gray2x2After180))
	}

	func test_rotate_gray_270CW_pixelOrder() {
		let result = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: 270, gray: true)
		XCTAssertEqual([UInt8](result.data), [UInt8](PixelBufferFixture.gray2x2After270))
	}

	func test_rotate_gray_90_swapsDimensions() {
		let result = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: 90, gray: true)
		XCTAssertEqual(result.w, 2)  // square stays square; test with non-square below
		XCTAssertEqual(result.h, 2)
	}

	func test_rotate_gray_90_nonSquare_swapsDimensions() {
		// 3×2 → 2×3 after 90°
		let buf = PixelBufferFixture.gray(width: 3, height: 2)
		let result = camera.rotateData(buf, w: 3, h: 2, degrees: 90, gray: true)
		XCTAssertEqual(result.w, 2)
		XCTAssertEqual(result.h, 3)
	}

	func test_rotate_gray_180_preservesDimensions() {
		let result = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: 180, gray: true)
		XCTAssertEqual(result.w, 2)
		XCTAssertEqual(result.h, 2)
	}

	// MARK: RGBA – 2×2

	func test_rotate_rgba_90CW_pixelOrder() {
		let result = camera.rotateData(PixelBufferFixture.rgba2x2, w: 2, h: 2, degrees: 90, gray: false)
		XCTAssertEqual([UInt8](result.data), [UInt8](PixelBufferFixture.rgba2x2After90))
	}

	func test_rotate_rgba_180_pixelOrder() {
		let result = camera.rotateData(PixelBufferFixture.rgba2x2, w: 2, h: 2, degrees: 180, gray: false)
		XCTAssertEqual([UInt8](result.data), [UInt8](PixelBufferFixture.rgba2x2After180))
	}

	func test_rotate_rgba_270CW_pixelOrder() {
		let result = camera.rotateData(PixelBufferFixture.rgba2x2, w: 2, h: 2, degrees: 270, gray: false)
		XCTAssertEqual([UInt8](result.data), [UInt8](PixelBufferFixture.rgba2x2After270))
	}

	func test_rotate_rgba_90_preservesAlpha() {
		let result  = camera.rotateData(PixelBufferFixture.rgba2x2, w: 2, h: 2, degrees: 90, gray: false)
		let bytes   = [UInt8](result.data)
		// Every 4th byte (alpha channel) must be 255
		for i in stride(from: 3, to: bytes.count, by: 4) {
			XCTAssertEqual(bytes[i], 255, "Alpha channel corrupted at pixel \(i/4)")
		}
	}

	func test_rotate_rgba_bufferLength_unchanged() {
		let src = PixelBufferFixture.rgba(width: 6, height: 4)
		for deg in [90, 180, 270] {
			let result = camera.rotateData(src, w: 6, h: 4, degrees: deg, gray: false)
			XCTAssertEqual(result.data.count, src.count, "Buffer length changed after \(deg)° rotation")
		}
	}

	// MARK: Round-trip

	func test_rotate_gray_4x90_equalsIdentity() {
		var data = PixelBufferFixture.gray2x2
		var w = 2, h = 2
		for _ in 0..<4 {
			let r = camera.rotateData(data, w: w, h: h, degrees: 90, gray: true)
			data = r.data; w = r.w; h = r.h
		}
		XCTAssertEqual([UInt8](data), [UInt8](PixelBufferFixture.gray2x2))
		XCTAssertEqual(w, 2); XCTAssertEqual(h, 2)
	}

	func test_rotate_rgba_180_twice_equalsIdentity() {
		let first  = camera.rotateData(PixelBufferFixture.rgba2x2, w: 2, h: 2, degrees: 180, gray: false)
		let second = camera.rotateData(first.data, w: first.w, h: first.h, degrees: 180, gray: false)
		XCTAssertEqual([UInt8](second.data), [UInt8](PixelBufferFixture.rgba2x2))
	}
}

// MARK: - NativeCamera Permission Tests

final class NativeCameraPermissionTests: XCTestCase {

	/// Verifies `hasPermission()` returns a Bool without crashing.
	/// The actual value depends on the Simulator/device authorisation state.
	func test_hasPermission_returnsBoolWithoutCrashing() {
		let result = NativeCamera.hasPermission()
		XCTAssertNotNil(result) // Bool is non-optional; this just ensures no crash
		_ = result as Bool
	}

	/// `requestPermission()` should not crash when called (permission UI won't show in unit test host).
	func test_requestPermission_doesNotCrash() {
		let camera = NativeCamera()
		camera.onPermissionResult = { _ in } // swallow callback
		XCTAssertNoThrow(camera.requestPermission())
	}
}

// MARK: - NativeCamera Lifecycle Tests

final class NativeCameraLifecycleTests: XCTestCase {

	func test_stop_beforeStart_doesNotCrash() {
		let camera = NativeCamera()
		XCTAssertNoThrow(camera.stop())
	}

	func test_stop_calledTwice_doesNotCrash() {
		let camera = NativeCamera()
		camera.stop()
		XCTAssertNoThrow(camera.stop())
	}

	func test_getCameras_returnsArray() {
		let camera = NativeCamera()
		let cameras = camera.getCameras()
		// May be empty in Simulator; should at minimum not crash and return an Array
		XCTAssertNotNil(cameras)
		XCTAssertTrue(cameras is [CameraInfo])
	}

	func test_getCameras_eachEntry_hasNonEmptyId() {
		let cameras = NativeCamera().getCameras()
		for cam in cameras {
			XCTAssertFalse(cam.id.isEmpty, "Camera ID must not be empty")
		}
	}

	func test_getCameras_eachEntry_hasAtLeastOneOutputSize() {
		let cameras = NativeCamera().getCameras()
		for cam in cameras {
			XCTAssertFalse(cam.outputSizes.isEmpty,
						"Camera '\(cam.id)' has no advertised output sizes")
		}
	}

	func test_onFrameAvailable_callbackIsOptional_atInit() {
		let camera = NativeCamera()
		XCTAssertNil(camera.onFrameAvailable)
	}

	func test_onPermissionResult_callbackIsOptional_atInit() {
		let camera = NativeCamera()
		XCTAssertNil(camera.onPermissionResult)
	}
}
