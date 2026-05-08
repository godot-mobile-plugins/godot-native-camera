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

// MARK: - NativeCamera Mirror Tests

/// Tests NativeCamera.mirrorData(_:w:h:gray:horizontal:vertical:) in isolation.
///
/// The method is `internal`, so it is accessible within the test module
/// via `@testable import NativeCameraPlugin`.
final class NativeCameraMirrorTests: XCTestCase {

	private let camera = NativeCamera()

	// MARK: Identity

	func test_mirror_neitherAxis_returnsOriginalData() {
		let result = camera.mirrorData(PixelBufferFixture.gray2x2, w: 2, h: 2, gray: true,
									   horizontal: false, vertical: false)
		XCTAssertEqual([UInt8](result.data), [UInt8](PixelBufferFixture.gray2x2))
	}

	func test_mirror_neitherAxis_preservesDimensions() {
		let result = camera.mirrorData(PixelBufferFixture.gray2x2, w: 2, h: 2, gray: true,
									   horizontal: false, vertical: false)
		XCTAssertEqual(result.w, 2)
		XCTAssertEqual(result.h, 2)
	}

	// MARK: Horizontal mirror – grayscale

	func test_mirror_gray_horizontal_swapsColumns() {
		// [ 10 | 20 ]    →    [ 20 | 10 ]
		// [ 30 | 40 ]    →    [ 40 | 30 ]
		let result = camera.mirrorData(PixelBufferFixture.gray2x2, w: 2, h: 2, gray: true,
									   horizontal: true, vertical: false)
		XCTAssertEqual([UInt8](result.data), [20, 10, 40, 30])
	}

	func test_mirror_gray_horizontal_preservesDimensions() {
		let result = camera.mirrorData(PixelBufferFixture.gray2x2, w: 2, h: 2, gray: true,
									   horizontal: true, vertical: false)
		XCTAssertEqual(result.w, 2)
		XCTAssertEqual(result.h, 2)
	}

	func test_mirror_gray_horizontal_appliedTwice_recoversOriginal() {
		let once  = camera.mirrorData(PixelBufferFixture.gray2x2, w: 2, h: 2, gray: true,
									  horizontal: true, vertical: false)
		let twice = camera.mirrorData(once.data, w: 2, h: 2, gray: true,
									  horizontal: true, vertical: false)
		XCTAssertEqual([UInt8](twice.data), [UInt8](PixelBufferFixture.gray2x2))
	}

	// MARK: Vertical mirror – grayscale

	func test_mirror_gray_vertical_swapsRows() {
		// [ 10 | 20 ]    →    [ 30 | 40 ]
		// [ 30 | 40 ]    →    [ 10 | 20 ]
		let result = camera.mirrorData(PixelBufferFixture.gray2x2, w: 2, h: 2, gray: true,
									   horizontal: false, vertical: true)
		XCTAssertEqual([UInt8](result.data), [30, 40, 10, 20])
	}

	func test_mirror_gray_vertical_appliedTwice_recoversOriginal() {
		let once  = camera.mirrorData(PixelBufferFixture.gray2x2, w: 2, h: 2, gray: true,
									  horizontal: false, vertical: true)
		let twice = camera.mirrorData(once.data, w: 2, h: 2, gray: true,
									  horizontal: false, vertical: true)
		XCTAssertEqual([UInt8](twice.data), [UInt8](PixelBufferFixture.gray2x2))
	}

	// MARK: Both axes – grayscale

	func test_mirror_gray_bothAxes_equals180Rotation() {
		// Mirroring both H and V is equivalent to a 180° rotation.
		let mirrored = camera.mirrorData(PixelBufferFixture.gray2x2, w: 2, h: 2, gray: true,
										 horizontal: true, vertical: true)
		let rotated  = camera.rotateData(PixelBufferFixture.gray2x2, w: 2, h: 2, degrees: 180, gray: true)
		XCTAssertEqual([UInt8](mirrored.data), [UInt8](rotated.data))
	}

	// MARK: RGBA mirror

	func test_mirror_rgba_horizontal_preservesAlpha() {
		let result = camera.mirrorData(PixelBufferFixture.rgba2x2, w: 2, h: 2, gray: false,
									   horizontal: true, vertical: false)
		let bytes  = [UInt8](result.data)
		for i in stride(from: 3, to: bytes.count, by: 4) {
			XCTAssertEqual(bytes[i], 255, "Alpha corrupted at pixel \(i/4)")
		}
	}

	func test_mirror_rgba_horizontal_appliedTwice_recoversOriginal() {
		let src   = PixelBufferFixture.rgba2x2
		let once  = camera.mirrorData(src, w: 2, h: 2, gray: false, horizontal: true, vertical: false)
		let twice = camera.mirrorData(once.data, w: 2, h: 2, gray: false, horizontal: true, vertical: false)
		XCTAssertEqual([UInt8](twice.data), [UInt8](src))
	}
}

// MARK: - NativeCamera Scale Tests

/// Tests NativeCamera.scaleData(_:srcW:srcH:dstW:dstH:gray:) in isolation.
///
/// The method is `internal`, accessible via `@testable import NativeCameraPlugin`.
final class NativeCameraScaleTests: XCTestCase {

	private let camera = NativeCamera()

	// MARK: Guard – disabled when either dimension is zero

	func test_scale_guard_bothZero_noScaling() {
		// guard is checked by the caller; here we just verify the helper is callable
		// with equal src/dst (identity) when both are non-zero.
		let src = PixelBufferFixture.gray2x2
		let result = camera.scaleData(src, srcW: 2, srcH: 2, dstW: 2, dstH: 2, gray: true)
		XCTAssertEqual([UInt8](result.data), [UInt8](src))
	}

	// MARK: Buffer length

	func test_scale_gray_downscale_outputLengthCorrect() {
		let src = PixelBufferFixture.gray(width: 4, height: 4)
		let result = camera.scaleData(src, srcW: 4, srcH: 4, dstW: 2, dstH: 2, gray: true)
		XCTAssertEqual(result.data.count, 2 * 2)
	}

	func test_scale_gray_upscale_outputLengthCorrect() {
		let src = PixelBufferFixture.gray2x2
		let result = camera.scaleData(src, srcW: 2, srcH: 2, dstW: 4, dstH: 4, gray: true)
		XCTAssertEqual(result.data.count, 4 * 4)
	}

	func test_scale_rgba_downscale_outputLengthCorrect() {
		let src = PixelBufferFixture.rgba(width: 4, height: 4)
		let result = camera.scaleData(src, srcW: 4, srcH: 4, dstW: 2, dstH: 2, gray: false)
		XCTAssertEqual(result.data.count, 2 * 2 * 4)
	}

	func test_scale_rgba_upscale_outputLengthCorrect() {
		let src = PixelBufferFixture.rgba2x2
		let result = camera.scaleData(src, srcW: 2, srcH: 2, dstW: 4, dstH: 4, gray: false)
		XCTAssertEqual(result.data.count, 4 * 4 * 4)
	}

	// MARK: Reported dimensions

	func test_scale_gray_reportedDimensions_matchDst() {
		let src = PixelBufferFixture.gray(width: 4, height: 4)
		let result = camera.scaleData(src, srcW: 4, srcH: 4, dstW: 2, dstH: 3, gray: true)
		XCTAssertEqual(result.w, 2)
		XCTAssertEqual(result.h, 3)
	}

	func test_scale_rgba_reportedDimensions_matchDst() {
		let src = PixelBufferFixture.rgba(width: 4, height: 4)
		let result = camera.scaleData(src, srcW: 4, srcH: 4, dstW: 3, dstH: 2, gray: false)
		XCTAssertEqual(result.w, 3)
		XCTAssertEqual(result.h, 2)
	}

	// MARK: Identity scale

	func test_scale_gray_identityDimensions_preservesPixels() {
		let src = PixelBufferFixture.gray2x2
		let result = camera.scaleData(src, srcW: 2, srcH: 2, dstW: 2, dstH: 2, gray: true)
		XCTAssertEqual([UInt8](result.data), [UInt8](src))
	}

	func test_scale_rgba_identityDimensions_preservesPixels() {
		let src = PixelBufferFixture.rgba2x2
		let result = camera.scaleData(src, srcW: 2, srcH: 2, dstW: 2, dstH: 2, gray: false)
		XCTAssertEqual([UInt8](result.data), [UInt8](src))
	}

	// MARK: Top-left pixel preserved (nearest-neighbour property)

	func test_scale_gray_topLeftPixelPreserved_onDownscale() {
		let src = PixelBufferFixture.gray(width: 4, height: 4)
		// Manually set TL pixel to a distinct value
		var bytes = [UInt8](src)
		bytes[0] = 42
		let result = camera.scaleData(Data(bytes), srcW: 4, srcH: 4, dstW: 2, dstH: 2, gray: true)
		XCTAssertEqual([UInt8](result.data)[0], 42, "Top-left pixel not preserved after downscale")
	}

	func test_scale_rgba_topLeftPixelPreserved_onDownscale() {
		var bytes = [UInt8](PixelBufferFixture.rgba(width: 4, height: 4))
		bytes[0] = 10; bytes[1] = 20; bytes[2] = 30; bytes[3] = 255
		let result = camera.scaleData(Data(bytes), srcW: 4, srcH: 4, dstW: 2, dstH: 2, gray: false)
		let out = [UInt8](result.data)
		XCTAssertEqual(out[0], 10, "R of TL pixel not preserved")
		XCTAssertEqual(out[1], 20, "G of TL pixel not preserved")
		XCTAssertEqual(out[2], 30, "B of TL pixel not preserved")
		XCTAssertEqual(out[3], 255, "A of TL pixel not preserved")
	}

	// MARK: 1×1 source → all destination pixels equal source pixel

	func test_scale_gray_1x1Source_allOutputPixelsMatchSource() {
		let src = Data([UInt8(77)])
		let result = camera.scaleData(src, srcW: 1, srcH: 1, dstW: 3, dstH: 3, gray: true)
		XCTAssertEqual(result.data.count, 9)
		for byte in result.data { XCTAssertEqual(byte, 77) }
	}

	func test_scale_rgba_1x1Source_allOutputPixelsMatchSource() {
		let src = Data([UInt8(11), UInt8(22), UInt8(33), UInt8(255)])
		let result = camera.scaleData(src, srcW: 1, srcH: 1, dstW: 2, dstH: 2, gray: false)
		XCTAssertEqual(result.data.count, 2 * 2 * 4)
		let out = [UInt8](result.data)
		for i in stride(from: 0, to: out.count, by: 4) {
			XCTAssertEqual(out[i], 11, "R mismatch at pixel \(i/4)")
			XCTAssertEqual(out[i + 1], 22, "G mismatch at pixel \(i/4)")
			XCTAssertEqual(out[i + 2], 33, "B mismatch at pixel \(i/4)")
			XCTAssertEqual(out[i + 3], 255, "A mismatch at pixel \(i/4)")
		}
	}

	// MARK: Alpha channel preserved through scaling

	func test_scale_rgba_alphaPreserved_afterDownscale() {
		let src = PixelBufferFixture.rgba(width: 4, height: 4) // alpha = 255 for all
		let result = camera.scaleData(src, srcW: 4, srcH: 4, dstW: 2, dstH: 2, gray: false)
		let out = [UInt8](result.data)
		for i in stride(from: 3, to: out.count, by: 4) {
			XCTAssertEqual(out[i], 255, "Alpha corrupted at pixel \(i/4)")
		}
	}

	// MARK: Half-size buffer relationship (gray vs RGBA)

	func test_scale_scaledGrayBuffer_isFourTimesSmaller_thanScaledRgba() {
		let grayResult = camera.scaleData(
			PixelBufferFixture.gray(width: 8, height: 8),
			srcW: 8, srcH: 8, dstW: 4, dstH: 4, gray: true
		)
		let rgbaResult = camera.scaleData(
			PixelBufferFixture.rgba(width: 8, height: 8),
			srcW: 8, srcH: 8, dstW: 4, dstH: 4, gray: false
		)
		XCTAssertEqual(rgbaResult.data.count, grayResult.data.count * 4)
	}

	// MARK: Rectangular (non-square) scale

	func test_scale_gray_rectangularDownscale_bufferLengthCorrect() {
		// 6×4 → 3×2: 6 pixels
		let src = PixelBufferFixture.gray(width: 6, height: 4)
		let result = camera.scaleData(src, srcW: 6, srcH: 4, dstW: 3, dstH: 2, gray: true)
		XCTAssertEqual(result.data.count, 3 * 2)
		XCTAssertEqual(result.w, 3)
		XCTAssertEqual(result.h, 2)
	}
}

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

// MARK: - NativeCamera Auto-Upright Tests

/// Tests for `computeUprightRotation()` and the supporting state fields.
///
/// ## Strategy
///
/// `computeUprightRotation()` is `internal` and therefore accessible via
/// `@testable import`.  Its two inputs — `isFrontFacingCamera` and
/// `deviceOrientation` — are `internal` (promoted from `private` specifically
/// to enable this test class) so they can be injected directly.  This lets
/// every orientation × camera-type combination be exercised without requiring
/// real hardware or a live capture session.
///
/// ## Rotation table under test
///
/// | `UIDeviceOrientation` | Back camera | Front camera |
/// |-----------------------|-------------|--------------|
/// | `.portrait`           | 90°         | 90°          |
/// | `.portraitUpsideDown` | 270°        | 270°         |
/// | `.landscapeLeft`      | 0°          | 180°         |
/// | `.landscapeRight`     | 180°        | 0°           |
/// | `.faceUp`             | 90° (fallback) | 90° (fallback) |
/// | `.faceDown`           | 90° (fallback) | 90° (fallback) |
/// | `.unknown`            | 90° (fallback) | 90° (fallback) |
final class NativeCameraAutoUprightTests: XCTestCase {

	private var camera: NativeCamera!

	override func setUp() {
		super.setUp()
		camera = NativeCamera()
	}

	override func tearDown() {
		camera = nil
		super.tearDown()
	}

	// MARK: - State defaults

	func test_isFrontFacingCamera_defaultsFalse() {
		XCTAssertFalse(camera.isFrontFacingCamera,
					   "isFrontFacingCamera must default to false (back camera assumption)")
	}

	func test_deviceOrientation_defaultsPortrait() {
		XCTAssertEqual(camera.deviceOrientation, .portrait,
					   "deviceOrientation must default to .portrait so the first frame is always valid")
	}

	// MARK: - Back camera — all four primary orientations

	/// Back, portrait: sensor is landscape; device is upright → rotate 90° CW.
	func test_computeUprightRotation_backCamera_portrait_returns90() {
		camera.isFrontFacingCamera = false
		camera.deviceOrientation   = .portrait
		XCTAssertEqual(camera.computeUprightRotation(), 90)
	}

	/// Back, portrait upside-down: sensor landscape, device inverted → rotate 270° CW.
	func test_computeUprightRotation_backCamera_portraitUpsideDown_returns270() {
		camera.isFrontFacingCamera = false
		camera.deviceOrientation   = .portraitUpsideDown
		XCTAssertEqual(camera.computeUprightRotation(), 270)
	}

	/// Back, landscapeLeft (top points left, home button right):
	/// sensor already aligned with the display → 0° needed.
	func test_computeUprightRotation_backCamera_landscapeLeft_returns0() {
		camera.isFrontFacingCamera = false
		camera.deviceOrientation   = .landscapeLeft
		XCTAssertEqual(camera.computeUprightRotation(), 0)
	}

	/// Back, landscapeRight (top points right, home button left):
	/// sensor inverted relative to the display → rotate 180°.
	func test_computeUprightRotation_backCamera_landscapeRight_returns180() {
		camera.isFrontFacingCamera = false
		camera.deviceOrientation   = .landscapeRight
		XCTAssertEqual(camera.computeUprightRotation(), 180)
	}

	// MARK: - Front camera — all four primary orientations

	/// Front, portrait: front sensor is horizontally mirrored but still needs
	/// 90° CW to be upright — same as back camera for portrait.
	func test_computeUprightRotation_frontCamera_portrait_returns90() {
		camera.isFrontFacingCamera = true
		camera.deviceOrientation   = .portrait
		XCTAssertEqual(camera.computeUprightRotation(), 90)
	}

	/// Front, portrait upside-down: 270° — same as back camera for this axis.
	func test_computeUprightRotation_frontCamera_portraitUpsideDown_returns270() {
		camera.isFrontFacingCamera = true
		camera.deviceOrientation   = .portraitUpsideDown
		XCTAssertEqual(camera.computeUprightRotation(), 270)
	}

	/// Front, landscapeLeft: because the front sensor is horizontally mirrored,
	/// the landscape cases are swapped compared to the back camera → 180°.
	func test_computeUprightRotation_frontCamera_landscapeLeft_returns180() {
		camera.isFrontFacingCamera = true
		camera.deviceOrientation   = .landscapeLeft
		XCTAssertEqual(camera.computeUprightRotation(), 180)
	}

	/// Front, landscapeRight: mirrored from back → 0°.
	func test_computeUprightRotation_frontCamera_landscapeRight_returns0() {
		camera.isFrontFacingCamera = true
		camera.deviceOrientation   = .landscapeRight
		XCTAssertEqual(camera.computeUprightRotation(), 0)
	}

	// MARK: - Fallback orientations → portrait default (90°)

	func test_computeUprightRotation_backCamera_faceUp_returns90() {
		camera.isFrontFacingCamera = false
		camera.deviceOrientation   = .faceUp
		XCTAssertEqual(camera.computeUprightRotation(), 90,
					   ".faceUp must fall through to the portrait default of 90°")
	}

	func test_computeUprightRotation_backCamera_faceDown_returns90() {
		camera.isFrontFacingCamera = false
		camera.deviceOrientation   = .faceDown
		XCTAssertEqual(camera.computeUprightRotation(), 90,
					   ".faceDown must fall through to the portrait default of 90°")
	}

	func test_computeUprightRotation_backCamera_unknown_returns90() {
		camera.isFrontFacingCamera = false
		camera.deviceOrientation   = .unknown
		XCTAssertEqual(camera.computeUprightRotation(), 90,
					   ".unknown must fall through to the portrait default of 90°")
	}

	func test_computeUprightRotation_frontCamera_faceUp_returns90() {
		camera.isFrontFacingCamera = true
		camera.deviceOrientation   = .faceUp
		XCTAssertEqual(camera.computeUprightRotation(), 90)
	}

	func test_computeUprightRotation_frontCamera_faceDown_returns90() {
		camera.isFrontFacingCamera = true
		camera.deviceOrientation   = .faceDown
		XCTAssertEqual(camera.computeUprightRotation(), 90)
	}

	func test_computeUprightRotation_frontCamera_unknown_returns90() {
		camera.isFrontFacingCamera = true
		camera.deviceOrientation   = .unknown
		XCTAssertEqual(camera.computeUprightRotation(), 90)
	}

	// MARK: - Portrait orientations are the same for both camera types

	/// Portrait cases do not involve the horizontal-mirror difference between
	/// front and back sensors, so both cameras must return the same value.
	func test_computeUprightRotation_portrait_sameForBothCameraTypes() {
		camera.deviceOrientation = .portrait
		camera.isFrontFacingCamera = false
		let back = camera.computeUprightRotation()
		camera.isFrontFacingCamera = true
		let front = camera.computeUprightRotation()
		XCTAssertEqual(back, front, "Both cameras must agree on portrait rotation")
	}

	func test_computeUprightRotation_portraitUpsideDown_sameForBothCameraTypes() {
		camera.deviceOrientation = .portraitUpsideDown
		camera.isFrontFacingCamera = false
		let back = camera.computeUprightRotation()
		camera.isFrontFacingCamera = true
		let front = camera.computeUprightRotation()
		XCTAssertEqual(back, front, "Both cameras must agree on portrait-upside-down rotation")
	}

	// MARK: - Landscape orientations differ between front and back cameras

	func test_computeUprightRotation_landscapeLeft_frontAndBackDiffer() {
		camera.deviceOrientation = .landscapeLeft
		camera.isFrontFacingCamera = false
		let back = camera.computeUprightRotation()   // 0
		camera.isFrontFacingCamera = true
		let front = camera.computeUprightRotation()  // 180
		XCTAssertNotEqual(back, front,
						  "landscapeLeft rotation must differ between front and back cameras")
	}

	func test_computeUprightRotation_landscapeRight_frontAndBackDiffer() {
		camera.deviceOrientation = .landscapeRight
		camera.isFrontFacingCamera = false
		let back = camera.computeUprightRotation()   // 180
		camera.isFrontFacingCamera = true
		let front = camera.computeUprightRotation()  // 0
		XCTAssertNotEqual(back, front,
						  "landscapeRight rotation must differ between front and back cameras")
	}

	/// landscapeLeft back == landscapeRight front, and vice-versa,
	/// confirming the front/back landscape values are exactly swapped.
	func test_computeUprightRotation_landscapeValues_areExactlySwapped() {
		camera.deviceOrientation   = .landscapeLeft
		camera.isFrontFacingCamera = false
		let backLeft = camera.computeUprightRotation()

		camera.deviceOrientation   = .landscapeRight
		camera.isFrontFacingCamera = true
		let frontRight = camera.computeUprightRotation()

		XCTAssertEqual(backLeft, frontRight,
					   "Back landscapeLeft and front landscapeRight must be equal (both 0°)")

		camera.deviceOrientation   = .landscapeRight
		camera.isFrontFacingCamera = false
		let backRight = camera.computeUprightRotation()

		camera.deviceOrientation   = .landscapeLeft
		camera.isFrontFacingCamera = true
		let frontLeft = camera.computeUprightRotation()

		XCTAssertEqual(backRight, frontLeft,
					   "Back landscapeRight and front landscapeLeft must be equal (both 180°)")
	}

	// MARK: - Result is always a canonical rotation angle

	/// For every orientation × camera-type combination the result must be
	/// one of the four canonical values {0, 90, 180, 270}.
	func test_computeUprightRotation_allCombinations_resultIsCanonical() {
		let orientations: [UIDeviceOrientation] = [
			.portrait, .portraitUpsideDown,
			.landscapeLeft, .landscapeRight,
			.faceUp, .faceDown, .unknown
		]
		let validAngles: Set<Int> = [0, 90, 180, 270]

		for isFront in [false, true] {
			camera.isFrontFacingCamera = isFront
			for orientation in orientations {
				camera.deviceOrientation = orientation
				let result = camera.computeUprightRotation()
				XCTAssertTrue(validAngles.contains(result),
							  "Non-canonical rotation \(result)° for orientation \(orientation.rawValue), "
							  + "isFront=\(isFront)")
			}
		}
	}

	// MARK: - Idempotency and liveness

	/// Calling the method twice with the same state must return the same value,
	/// confirming that computeUprightRotation() is read-only and side-effect-free.
	func test_computeUprightRotation_consecutiveCalls_returnSameValue() {
		camera.isFrontFacingCamera = false
		camera.deviceOrientation   = .portrait
		let first  = camera.computeUprightRotation()
		let second = camera.computeUprightRotation()
		XCTAssertEqual(first, second,
					   "Consecutive calls with identical state must return the same value")
	}

	/// When deviceOrientation changes, the very next call must reflect the new value,
	/// confirming the live orientation is read on every invocation.
	func test_computeUprightRotation_updatesWhenOrientationChanges() {
		camera.isFrontFacingCamera = false

		camera.deviceOrientation = .portrait
		let portrait = camera.computeUprightRotation()   // 90

		camera.deviceOrientation = .landscapeLeft
		let landscape = camera.computeUprightRotation()  // 0

		XCTAssertNotEqual(portrait, landscape,
						  "Result must update immediately when deviceOrientation changes")
		XCTAssertEqual(portrait,  90)
		XCTAssertEqual(landscape,  0)
	}

	/// Swapping camera type must immediately change the result for landscape
	/// orientations, confirming isFrontFacingCamera is read on every invocation.
	func test_computeUprightRotation_updatesWhenCameraTypeChanges() {
		camera.deviceOrientation = .landscapeLeft

		camera.isFrontFacingCamera = false
		let back = camera.computeUprightRotation()   // 0

		camera.isFrontFacingCamera = true
		let front = camera.computeUprightRotation()  // 180

		XCTAssertNotEqual(back, front,
						  "Result must update immediately when isFrontFacingCamera changes")
	}
}
