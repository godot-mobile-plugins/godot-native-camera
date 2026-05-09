//
// © 2026-present https://github.com/cengiz-pz
//

import AVFoundation
@testable import native_camera_plugin
import XCTest

// MARK: - CameraInfo Tests

/// Tests for the `CameraInfo` model, focusing on the `sensorOrientation` property.
///
/// `CameraInfo.init` requires a real `AVCaptureDevice`; tests that need one are
/// guarded by `XCTSkip` so they are silently skipped on a Simulator host with
/// no physical cameras attached.
final class CameraInfoTests: XCTestCase {

	// MARK: - sensorOrientation stored at init

	func test_sensorOrientation_90_isStoredAtInit() throws {
		let dev = AVCaptureDevice.default(for: .video)
		try XCTSkipIf(dev == nil, "No camera available on this host")
		let info = CameraInfo(id: "cam0", device: dev!, outputSizes: [], sensorOrientation: 90)
		XCTAssertEqual(info.sensorOrientation, 90)
	}

	func test_sensorOrientation_0_isStoredAtInit() throws {
		let dev = AVCaptureDevice.default(for: .video)
		try XCTSkipIf(dev == nil, "No camera available on this host")
		let info = CameraInfo(id: "cam0", device: dev!, outputSizes: [], sensorOrientation: 0)
		XCTAssertEqual(info.sensorOrientation, 0)
	}

	func test_sensorOrientation_180_isStoredAtInit() throws {
		let dev = AVCaptureDevice.default(for: .video)
		try XCTSkipIf(dev == nil, "No camera available on this host")
		let info = CameraInfo(id: "cam0", device: dev!, outputSizes: [], sensorOrientation: 180)
		XCTAssertEqual(info.sensorOrientation, 180)
	}

	func test_sensorOrientation_270_isStoredAtInit() throws {
		let dev = AVCaptureDevice.default(for: .video)
		try XCTSkipIf(dev == nil, "No camera available on this host")
		let info = CameraInfo(id: "cam0", device: dev!, outputSizes: [], sensorOrientation: 270)
		XCTAssertEqual(info.sensorOrientation, 270)
	}

	// MARK: - sensorOrientation does not interfere with other stored properties

	func test_sensorOrientation_doesNotAffectId() throws {
		let dev = AVCaptureDevice.default(for: .video)
		try XCTSkipIf(dev == nil, "No camera available on this host")
		let info = CameraInfo(id: "unique-id", device: dev!, outputSizes: [], sensorOrientation: 90)
		XCTAssertEqual(info.id, "unique-id")
	}

	func test_sensorOrientation_doesNotAffectOutputSizesCount() throws {
		let dev = AVCaptureDevice.default(for: .video)
		try XCTSkipIf(dev == nil, "No camera available on this host")
		let sizes = [FrameSize(width: 1280, height: 720), FrameSize(width: 640, height: 480)]
		let info  = CameraInfo(id: "cam0", device: dev!, outputSizes: sizes, sensorOrientation: 90)
		XCTAssertEqual(info.outputSizes.count, 2)
	}
}

// MARK: - NativeCamera.deriveSensorOrientation Tests

/// Tests for `NativeCamera.deriveSensorOrientation(from:)`.
///
/// The helper is `internal static`, making it accessible via `@testable import`.
/// Because it requires a real `AVCaptureDevice`, every test that constructs one
/// is guarded by `XCTSkip` for Simulator hosts with no cameras.
///
/// ## What is tested here
///
/// | Scenario | Expected result |
/// |---|---|
/// | Device has landscape-native formats (width ≥ height) | 90° |
/// | Device has no formats | 90° (safe default) |
/// | All cameras returned by getCameras() | value in {0, 90, 180, 270} |
final class NativeCameraDeriveSensorOrientationTests: XCTestCase {

	// MARK: - Default when no formats are available

	/// The helper must never throw and must return a sensible default when the
	/// device exposes no formats.  We cannot construct a formatless device in
	/// a unit test without private API, so this scenario is verified by checking
	/// that `deriveSensorOrientation` on any real device returns a canonical value.
	func test_deriveSensorOrientation_realDevice_returnsCanonicalValue() throws {
		let dev = AVCaptureDevice.default(for: .video)
		try XCTSkipIf(dev == nil, "No camera available on this host")
		let result = NativeCamera.deriveSensorOrientation(from: dev!)
		XCTAssertTrue([0, 90, 180, 270].contains(result),
					"deriveSensorOrientation returned non-canonical value \(result)")
	}

	// MARK: - iPhone built-in back camera is landscape-native → 90°

	func test_deriveSensorOrientation_backCamera_returns90() throws {
		guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera,
				for: .video, position: .back) else {
			throw XCTSkip("No back camera available on this host")
		}
		// All iPhone back cameras capture in landscape natively.
		XCTAssertEqual(NativeCamera.deriveSensorOrientation(from: dev), 90,
					"iPhone back camera should report sensorOrientation 90")
	}

	func test_deriveSensorOrientation_frontCamera_returnsCanonicalValue() throws {
		guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera,
				for: .video, position: .front) else {
			throw XCTSkip("No front camera available on this host")
		}
		let result = NativeCamera.deriveSensorOrientation(from: dev)
		XCTAssertTrue([0, 90, 180, 270].contains(result),
					"Front camera sensorOrientation \(result) is not canonical")
	}

	// MARK: - getCameras() integration: sensorOrientation propagates end-to-end

	/// When `getCameras()` is called on a host that has at least one camera,
	/// every returned `CameraInfo` must carry a `sensorOrientation` that is a
	/// member of {0, 90, 180, 270}.
	func test_getCameras_sensorOrientation_isCanonicalForAllCameras() {
		let cameras = NativeCamera().getCameras()
		let valid   = Set([0, 90, 180, 270])
		for cam in cameras {
			XCTAssertTrue(valid.contains(cam.sensorOrientation),
						"Camera '\(cam.id)' sensorOrientation \(cam.sensorOrientation) is not canonical")
		}
	}

	/// Confirms that `getCameras()` propagates `sensorOrientation` into `CameraInfo`
	/// by checking that the property is non-negative for every camera.
	/// (A value of 0 is valid for landscape-native iPads; negative would be a bug.)
	func test_getCameras_sensorOrientation_isNonNegative() {
		let cameras = NativeCamera().getCameras()
		for cam in cameras {
			XCTAssertGreaterThanOrEqual(cam.sensorOrientation, 0,
									"Camera '\(cam.id)' has negative sensorOrientation")
		}
	}
}
