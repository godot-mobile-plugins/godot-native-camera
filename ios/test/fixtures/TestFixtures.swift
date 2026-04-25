//
// © 2026-present https://github.com/cengiz-pz
//
// TestFixtures.swift
// Factories and sample data for NativeCameraPlugin unit tests.
//

import Foundation
@testable import native_camera_plugin

// MARK: - FrameSize Fixtures

enum FrameSizeFixture {
	static func make(width: Int = 1280, height: Int = 720) -> FrameSize {
		FrameSize(width: width, height: height)
	}

	static let hd     = FrameSize(width: 1280, height: 720)
	static let fullHD = FrameSize(width: 1920, height: 1080)
	static let vga    = FrameSize(width: 640, height: 480)
	static let square = FrameSize(width: 512, height: 512)

	/// Typical set returned by a real back camera
	static let backCameraOutputSizes: [FrameSize] = [vga, hd, fullHD]
}

// MARK: - FrameInfo Fixtures

enum FrameInfoFixture {
	static func make(
		width: Int = 4,
		height: Int = 4,
		rotation: Int = 0,
		isGrayscale: Bool = false
	) -> FrameInfo {
		let buffer = isGrayscale
			? PixelBufferFixture.gray(width: width, height: height)
			: PixelBufferFixture.rgba(width: width, height: height)
		return FrameInfo(
			buffer: buffer,
			width: width,
			height: height,
			rotation: rotation,
			isGrayscale: isGrayscale
		)
	}

	static let standardRGBA = make(width: 640, height: 480)
	static let standardGray = make(width: 640, height: 480, isGrayscale: true)
	static let rotated90    = make(width: 640, height: 480, rotation: 90)
	static let rotated270   = make(width: 640, height: 480, rotation: 270)
}

// MARK: - Pixel Buffer Fixtures

enum PixelBufferFixture {
	/// RGBA ramp – pixel i has (i%256, (i*2)%256, (i*3)%256, 255)
	static func rgba(width: Int, height: Int) -> Data {
		let count = width * height
		var bytes = [UInt8](repeating: 0, count: count * 4)
		for i in 0..<count {
			bytes[i * 4]     = UInt8(i % 256)
			bytes[i * 4 + 1] = UInt8((i * 2) % 256)
			bytes[i * 4 + 2] = UInt8((i * 3) % 256)
			bytes[i * 4 + 3] = 255
		}
		return Data(bytes)
	}

	/// Grayscale ramp – pixel i has value i%256
	static func gray(width: Int, height: Int) -> Data {
		Data((0..<(width * height)).map { UInt8($0 % 256) })
	}

	// MARK: Deterministic 2×2 buffers for rotation assertions

	/// 2×2 grayscale, row-major: TL=10, TR=20, BL=30, BR=40
	///
	///   [ 10 | 20 ]
	///   [ 30 | 40 ]
	static let gray2x2 = Data([10, 20, 30, 40] as [UInt8])

	/// Expected grayscale 2×2 results after CW rotation (NativeCamera.rotateData semantics)
	///
	/// 90° CW:   BL→TL, TL→TR, BR→BL, TR→BR → [ 30, 10, 40, 20 ]
	/// 180°:     BR→TL, BL→TR, TR→BL, TL→BR → [ 40, 30, 20, 10 ]
	/// 270° CW:  TR→TL, BR→TR, TL→BL, BL→BR → [ 20, 40, 10, 30 ]
	static let gray2x2After90  = Data([30, 10, 40, 20] as [UInt8])
	static let gray2x2After180 = Data([40, 30, 20, 10] as [UInt8])
	static let gray2x2After270 = Data([20, 40, 10, 30] as [UInt8])

	/// 2×2 RGBA buffer (4 bytes / pixel), row-major
	///
	///   [ Red   | Green ]
	///   [ Blue  | White ]
	static let rgba2x2: Data = {
		let bytes: [UInt8] = [
			255, 0, 0, 255,  // (0,0) Red
			0, 255, 0, 255,  // (1,0) Green
			0, 0, 255, 255,  // (0,1) Blue
			255, 255, 255, 255  // (1,1) White
		]
		return Data(bytes)
	}()

	/// Expected RGBA 2×2 results after CW rotation
	///
	/// 90°  CW:  [ Blue, Red, White, Green ]
	/// 180°:     [ White, Blue, Green, Red ]
	/// 270° CW:  [ Green, White, Red, Blue ]
	static let rgba2x2After90: Data = {
		let bytes: [UInt8] = [
			0, 0, 255, 255,  // (0,0) Blue
			255, 0, 0, 255,  // (1,0) Red
			255, 255, 255, 255,  // (0,1) White
			0, 255, 0, 255  // (1,1) Green
		]
		return Data(bytes)
	}()

	static let rgba2x2After180: Data = {
		let bytes: [UInt8] = [
			255, 255, 255, 255,  // (0,0) White
			0, 0, 255, 255,  // (1,0) Blue
			0, 255, 0, 255,  // (0,1) Green
			255, 0, 0, 255  // (1,1) Red
		]
		return Data(bytes)
	}()

	static let rgba2x2After270: Data = {
		let bytes: [UInt8] = [
			0, 255, 0, 255,  // (0,0) Green
			255, 255, 255, 255,  // (1,0) White
			255, 0, 0, 255,  // (0,1) Red
			0, 0, 255, 255  // (1,1) Blue
		]
		return Data(bytes)
	}()

	// MARK: 4×4 source for downscale / upscale tests (nearest-neighbour)

	/// 4×4 grayscale ramp: pixel(x,y) = y*4 + x  (values 0…15)
	static let gray4x4: Data = Data((0..<16).map { UInt8($0) })

	/// 4×4 RGBA: R channel = pixel index (0…15), G=B=0, A=255
	static let rgba4x4: Data = {
		var bytes = [UInt8](repeating: 0, count: 16 * 4)
		for i in 0..<16 {
			bytes[i * 4]     = UInt8(i)   // R
			bytes[i * 4 + 1] = 0          // G
			bytes[i * 4 + 2] = 0          // B
			bytes[i * 4 + 3] = 255        // A
		}
		return Data(bytes)
	}()
}

// MARK: - FrameRequest Dictionary Fixtures (mirrors ObjC frame_request keys)

enum FrameRequestFixture {
	static let cameraIdKey     = "camera_id"
	static let widthKey        = "width"
	static let heightKey       = "height"
	static let framesToSkipKey = "frames_to_skip"
	static let rotationKey     = "rotation"
	static let isGrayscaleKey  = "is_grayscale"
	static let scaleWidthKey   = "scale_width"
	static let scaleHeightKey  = "scale_height"

	static let sampleCameraId = "com.apple.avfoundation.avcapturedevice.built-in_video:0"

	/// Fully-populated request parameters (scaling disabled)
	static let fullParams: [String: Any] = [
		cameraIdKey: sampleCameraId,
		widthKey: 1280,
		heightKey: 720,
		framesToSkipKey: 2,
		rotationKey: 90,
		isGrayscaleKey: false,
		scaleWidthKey: 0,
		scaleHeightKey: 0
	]

	/// Minimal request – only camera_id; all other fields should fall back to defaults
	static let minimalParams: [String: Any] = [
		cameraIdKey: sampleCameraId
	]

	/// Request with scaling to half the capture resolution (640×360 from 1280×720)
	static let scaledParams: [String: Any] = [
		cameraIdKey: sampleCameraId,
		widthKey: 1280,
		heightKey: 720,
		framesToSkipKey: 0,
		rotationKey: 0,
		isGrayscaleKey: false,
		scaleWidthKey: 640,
		scaleHeightKey: 360
	]

	/// scale_width set, scale_height absent — scaling must not be applied.
	static let scaleWidthOnlyParams: [String: Any] = [
		cameraIdKey: sampleCameraId,
		scaleWidthKey: 640
	]

	/// scale_height set, scale_width absent — scaling must not be applied.
	static let scaleHeightOnlyParams: [String: Any] = [
		cameraIdKey: sampleCameraId,
		scaleHeightKey: 360
	]

	/// Default values expected when keys are absent
	enum Defaults {
		static let width        = 640
		static let height       = 480
		static let framesToSkip = 0
		static let rotation     = 0
		static let isGrayscale  = false
		static let scaleWidth   = 0
		static let scaleHeight  = 0
	}
}
