//
// © 2026-present https://github.com/cengiz-pz
//

import AVFoundation
@testable import native_camera_plugin
import XCTest

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
