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

	func test_mirror_neitherAxis_returnsUnchangedData() {
		let result = camera.mirrorData(PixelBufferFixture.gray2x2, w: 2, h: 2,
				gray: true, horizontal: false, vertical: false)
		XCTAssertEqual(result.data, PixelBufferFixture.gray2x2)
		XCTAssertEqual(result.w, 2)
		XCTAssertEqual(result.h, 2)
	}

	// MARK: Grayscale – horizontal

	func test_mirror_gray_horizontal_pixelOrder() {
		// 2×2 layout row-major: [A B / C D] → horizontal → [B A / D C]
		let src  = Data([1, 2, 3, 4])
		let want = Data([2, 1, 4, 3])
		let result = camera.mirrorData(src, w: 2, h: 2, gray: true, horizontal: true, vertical: false)
		XCTAssertEqual([UInt8](result.data), [UInt8](want))
	}

	func test_mirror_gray_horizontal_nonSquare_pixelOrder() {
		// 3×2: [1 2 3 / 4 5 6] → horizontal → [3 2 1 / 6 5 4]
		let src  = Data([1, 2, 3, 4, 5, 6])
		let want = Data([3, 2, 1, 6, 5, 4])
		let result = camera.mirrorData(src, w: 3, h: 2, gray: true, horizontal: true, vertical: false)
		XCTAssertEqual([UInt8](result.data), [UInt8](want))
	}

	// MARK: Grayscale – vertical

	func test_mirror_gray_vertical_pixelOrder() {
		// 2×2: [A B / C D] → vertical → [C D / A B]
		let src  = Data([1, 2, 3, 4])
		let want = Data([3, 4, 1, 2])
		let result = camera.mirrorData(src, w: 2, h: 2, gray: true, horizontal: false, vertical: true)
		XCTAssertEqual([UInt8](result.data), [UInt8](want))
	}

	func test_mirror_gray_vertical_nonSquare_pixelOrder() {
		// 3×2: [1 2 3 / 4 5 6] → vertical → [4 5 6 / 1 2 3]
		let src  = Data([1, 2, 3, 4, 5, 6])
		let want = Data([4, 5, 6, 1, 2, 3])
		let result = camera.mirrorData(src, w: 3, h: 2, gray: true, horizontal: false, vertical: true)
		XCTAssertEqual([UInt8](result.data), [UInt8](want))
	}

	// MARK: Grayscale – both axes == 180° rotation

	func test_mirror_gray_both_equalsRotate180() {
		let src      = PixelBufferFixture.gray2x2
		let mirrored = camera.mirrorData(src, w: 2, h: 2, gray: true, horizontal: true, vertical: true)
		let rotated  = camera.rotateData(src, w: 2, h: 2, degrees: 180, gray: true)
		XCTAssertEqual([UInt8](mirrored.data), [UInt8](rotated.data),
				"mirror both axes should equal 180° rotation")
	}

	// MARK: Dimensions unchanged

	func test_mirror_gray_preservesDimensions_allAxes() {
		let buf = PixelBufferFixture.gray(width: 4, height: 3)
		for (h, v) in [(true, false), (false, true), (true, true)] {
			let r = camera.mirrorData(buf, w: 4, h: 3, gray: true, horizontal: h, vertical: v)
			XCTAssertEqual(r.w, 4, "width changed for h:\(h) v:\(v)")
			XCTAssertEqual(r.h, 3, "height changed for h:\(h) v:\(v)")
		}
	}

	// MARK: Round-trip

	func test_mirror_gray_horizontal_twice_equalsIdentity() {
		let src   = PixelBufferFixture.gray2x2
		let once  = camera.mirrorData(src, w: 2, h: 2, gray: true, horizontal: true, vertical: false)
		let twice = camera.mirrorData(once.data, w: 2, h: 2, gray: true, horizontal: true, vertical: false)
		XCTAssertEqual([UInt8](twice.data), [UInt8](src))
	}

	func test_mirror_gray_vertical_twice_equalsIdentity() {
		let src   = PixelBufferFixture.gray2x2
		let once  = camera.mirrorData(src, w: 2, h: 2, gray: true, horizontal: false, vertical: true)
		let twice = camera.mirrorData(once.data, w: 2, h: 2, gray: true, horizontal: false, vertical: true)
		XCTAssertEqual([UInt8](twice.data), [UInt8](src))
	}

	// MARK: RGBA – horizontal

	func test_mirror_rgba_horizontal_pixelOrder() {
		// 2×2 RGBA: pixels [P0 P1 / P2 P3], horizontal → [P1 P0 / P3 P2]
		// Build a simple source with distinct per-pixel R values (G=B=0, A=255).
		let src = Data([
			10, 0, 0, 255, 20, 0, 0, 255,   // row 0: P0, P1
			30, 0, 0, 255, 40, 0, 0, 255   // row 1: P2, P3
		])
		let want = Data([
			20, 0, 0, 255, 10, 0, 0, 255,   // row 0: P1, P0
			40, 0, 0, 255, 30, 0, 0, 255   // row 1: P3, P2
		])
		let result = camera.mirrorData(src, w: 2, h: 2, gray: false, horizontal: true, vertical: false)
		XCTAssertEqual([UInt8](result.data), [UInt8](want))
	}

	func test_mirror_rgba_vertical_pixelOrder() {
		// 2×2 RGBA: pixels [P0 P1 / P2 P3], vertical → [P2 P3 / P0 P1]
		let src = Data([
			10, 0, 0, 255, 20, 0, 0, 255,   // row 0: P0, P1
			30, 0, 0, 255, 40, 0, 0, 255   // row 1: P2, P3
		])
		let want = Data([
			30, 0, 0, 255, 40, 0, 0, 255,   // row 0: P2, P3
			10, 0, 0, 255, 20, 0, 0, 255   // row 1: P0, P1
		])
		let result = camera.mirrorData(src, w: 2, h: 2, gray: false, horizontal: false, vertical: true)
		XCTAssertEqual([UInt8](result.data), [UInt8](want))
	}

	func test_mirror_rgba_horizontal_preservesAlpha() {
		let result = camera.mirrorData(PixelBufferFixture.rgba2x2, w: 2, h: 2,
				gray: false, horizontal: true, vertical: false)
		let bytes = [UInt8](result.data)
		for i in stride(from: 3, to: bytes.count, by: 4) {
			XCTAssertEqual(bytes[i], 255, "Alpha channel corrupted at pixel \(i/4)")
		}
	}

	func test_mirror_rgba_bufferLength_unchanged() {
		let src = PixelBufferFixture.rgba(width: 6, height: 4)
		for (h, v) in [(true, false), (false, true), (true, true)] {
			let r = camera.mirrorData(src, w: 6, h: 4, gray: false, horizontal: h, vertical: v)
			XCTAssertEqual(r.data.count, src.count,
					"Buffer length changed for h:\(h) v:\(v)")
		}
	}

	// MARK: Round-trip RGBA

	func test_mirror_rgba_horizontal_twice_equalsIdentity() {
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
