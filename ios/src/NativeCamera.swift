//
// © 2026-present https://github.com/cengiz-pz
//

import AVFoundation
import Foundation
import UIKit

@objc public class NativeCamera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

	@objc public var onFrameAvailable: ((FrameInfo) -> Void)?
	@objc public var onPermissionResult: ((Bool) -> Void)?

	@objc static let bufferKey = "buffer"
	@objc static let widthKey = "width"
	@objc static let heightKey = "height"
	@objc static let rotationKey = "rotation"
	@objc static let isGrayscaleKey = "is_grayscale"

	@objc static let cameraIdKey = "camera_id"
	@objc static let isFrontFacingKey = "is_front_facing"
	@objc static let outputSizesKey = "output_sizes"

	private var captureSession: AVCaptureSession?
	private var videoOutput: AVCaptureVideoDataOutput?
	private let sessionQueue = DispatchQueue(label: "camera_session_queue")

	private var frameRequest: FrameRequest?
	private var frameCounter: Int = 0

	/// True when the active capture device is the front-facing camera.
	/// Written on sessionQueue (inside start's async block, before capture begins),
	/// read on sessionQueue (from captureOutput) — same queue, no data race.
	///
	/// `internal` rather than `private` so that unit tests can inject values
	/// directly and exercise `computeUprightRotation()` without requiring real
	/// hardware or a running capture session.
	var isFrontFacingCamera: Bool = false

	/// Most recently observed device orientation, kept in sync by a UIDevice
	/// orientation-change notification observer running on the main thread.
	/// captureOutput reads this from sessionQueue; the worst case is a single
	/// frame using a slightly stale value when the device is mid-rotation —
	/// imperceptible in practice and preferable to an expensive cross-queue sync.
	/// Initialised to .portrait so the first frame is always valid even if
	/// beginGeneratingDeviceOrientationNotifications has not yet fired.
	///
	/// `internal` rather than `private` so that unit tests can inject specific
	/// orientations and exercise `computeUprightRotation()` in isolation.
	var deviceOrientation: UIDeviceOrientation = .portrait

	@objc public static func hasPermission() -> Bool {
		return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
	}

	@objc public func requestPermission() {
		AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
			DispatchQueue.main.async {
				self?.onPermissionResult?(granted)
			}
		}
	}

	@objc public func getCameras() -> [CameraInfo] {
		let discoverySession = AVCaptureDevice.DiscoverySession(
			deviceTypes: [.builtInWideAngleCamera],
			mediaType: .video,
			position: .unspecified
		)

		return discoverySession.devices.map { device in
			let sizes = device.formats.map { format in
				let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
				return FrameSize(width: Int(dims.width), height: Int(dims.height))
			}
			return CameraInfo(id: device.uniqueID, device: device, outputSizes: sizes)
		}
	}

	@objc public func start(request: FrameRequest) {
		// UIDevice orientation tracking must be started on the main thread.
		// The notification fires on the main thread too, keeping deviceOrientation
		// updated independently of the capture pipeline.
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			UIDevice.current.beginGeneratingDeviceOrientationNotifications()
			// Seed the cached value immediately so the first frame is correct.
			self.deviceOrientation = UIDevice.current.orientation
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(self.orientationDidChange),
				name: UIDevice.orientationDidChangeNotification,
				object: nil
			)
		}

		// Dispatch everything onto sessionQueue so stop() fully completes
		// before we reconfigure, AND so variable writes are on the same
		// queue that captureOutput reads them from — no data race.
		sessionQueue.async {
			self.captureSession?.stopRunning()
			self.captureSession = nil
			self.videoOutput = nil

			// Store the request and reset counter
			self.frameRequest = request
			self.frameCounter = 0

			let session = AVCaptureSession()
			session.beginConfiguration()

			guard let device = AVCaptureDevice(uniqueID: request.cameraId()),
				let input = try? AVCaptureDeviceInput(device: device) else { return }

			// Cache the lens position so computeUprightRotation() can apply the
			// correct formula without touching the device object on every frame.
			self.isFrontFacingCamera = (device.position == .front)

			if session.canAddInput(input) { session.addInput(input) }

			let output = AVCaptureVideoDataOutput()
			output.videoSettings = [
				kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
			]
			output.setSampleBufferDelegate(self, queue: self.sessionQueue)

			if session.canAddOutput(output) {
				session.addOutput(output)
			}

			session.commitConfiguration()
			session.startRunning()
			self.captureSession = session
			self.videoOutput = output
		}
	}

	@objc public func stop() {
		sessionQueue.async {
			self.captureSession?.stopRunning()
			self.captureSession = nil
			self.videoOutput = nil
		}

		// Mirror the main-thread setup from start().
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			NotificationCenter.default.removeObserver(
				self,
				name: UIDevice.orientationDidChangeNotification,
				object: nil
			)
			UIDevice.current.endGeneratingDeviceOrientationNotifications()
		}
	}

	/// Called on the main thread whenever the device physical orientation changes.
	/// Updates the cached ``deviceOrientation`` used by ``computeUprightRotation()``.
	@objc private func orientationDidChange() {
		deviceOrientation = UIDevice.current.orientation
	}

	/// Computes the clockwise rotation in degrees needed to produce an upright
	/// frame for the current camera and the cached device orientation.
	///
	/// ## iOS orientation → rotation mapping
	///
	/// The raw BGRA buffer from `AVCaptureVideoDataOutput` is always in sensor
	/// (landscape) space.  The table below shows the rotation that brings it
	/// upright for each `UIDeviceOrientation`:
	///
	/// | Device orientation    | Back camera | Front camera |
	/// |-----------------------|-------------|--------------|
	/// | portrait              | 90°         | 90°          |
	/// | portraitUpsideDown    | 270°        | 270°         |
	/// | landscapeLeft¹        | 0°          | 180°         |
	/// | landscapeRight²       | 180°        | 0°           |
	/// | faceUp / faceDown / unknown | 90° (portrait fallback) |
	///
	/// ¹ `landscapeLeft` — device top points left, home button on the right.
	/// ² `landscapeRight` — device top points right, home button on the left.
	///
	/// Front and back cameras mirror each other in the landscape cases because
	/// the front sensor image is horizontally flipped relative to the back sensor.
	///
	/// - Note: Must only be called from `sessionQueue` to guarantee consistent
	///   access to `isFrontFacingCamera`.  `deviceOrientation` is read without a
	///   lock; see its declaration for the rationale.
	internal func computeUprightRotation() -> Int {
		switch deviceOrientation {
		case .portrait:
			return 90
		case .portraitUpsideDown:
			return 270
		case .landscapeLeft:
			// Device top points left (home button right) — sensor is already
			// aligned for the back camera; mirrored for the front camera.
			return isFrontFacingCamera ? 180 : 0
		case .landscapeRight:
			// Device top points right (home button left) — sensor is inverted
			// for the back camera; already aligned for the front camera.
			return isFrontFacingCamera ? 0 : 180
		default:
			// .faceUp, .faceDown, .unknown — fall back to portrait assumption.
			return 90
		}
	}

	public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
			from connection: AVCaptureConnection) {
		guard let req = frameRequest else { return }

		frameCounter += 1
		if frameCounter % (req.framesToSkip() + 1) != 0 { return }

		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

		CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
		defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }

		let width = CVPixelBufferGetWidth(imageBuffer)
		let height = CVPixelBufferGetHeight(imageBuffer)
		let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)!

		let totalPixels = width * height
		var outputData: Data

		if req.isGrayscale() {
			// Extract Luminance from BGRA (Approximation: Blue channel or average)
			// For true YUV-Y extraction, we'd change videoSettings to 420v
			var grayBytes = [UInt8](repeating: 0, count: totalPixels)
			let bgraPtr = baseAddress.assumingMemoryBound(to: UInt8.self)
			for i in 0..<totalPixels {
				// Simplified: take the Green channel as gray or use proper weights
				grayBytes[i] = bgraPtr[i * 4 + 1]
			}
			outputData = Data(grayBytes)
		} else {
			// Android uses RGBA. iOS uses BGRA. We swap B and R to match Android's RGBA expectation
			var rgbaBytes = [UInt8](repeating: 0, count: totalPixels * 4)
			let bgraPtr = baseAddress.assumingMemoryBound(to: UInt8.self)
			for i in 0..<totalPixels {
				rgbaBytes[i * 4] = bgraPtr[i * 4 + 2] // R
				rgbaBytes[i * 4 + 1] = bgraPtr[i * 4 + 1] // G
				rgbaBytes[i * 4 + 2] = bgraPtr[i * 4] // B
				rgbaBytes[i * 4 + 3] = 255 // A
			}
			outputData = Data(rgbaBytes)
		}

		// When auto_upright is enabled, derive the required rotation from the
		// camera sensor orientation and the live device orientation instead of
		// using the fixed value set by the caller.
		let effectiveRotation: Int = req.isAutoUpright() ? computeUprightRotation() : req.rotation()

		// Handle Rotation
		let rotated = rotateData(outputData, w: width, h: height, degrees: effectiveRotation, gray: req.isGrayscale())

		// Handle Mirror (applied after rotation, same as Android)
		let mirrored = mirrorData(rotated.data, w: rotated.w, h: rotated.h,
				gray: req.isGrayscale(), horizontal: req.isMirrorHorizontal(), vertical: req.isMirrorVertical())

		// Handle Scaling (applied last — after rotation and mirroring)
		let final: (data: Data, w: Int, h: Int)
		if req.scaleWidth() > 0 && req.scaleHeight() > 0 {
			final = scaleData(mirrored.data, srcW: mirrored.w, srcH: mirrored.h,
					dstW: req.scaleWidth(), dstH: req.scaleHeight(), gray: req.isGrayscale())
		} else {
			final = mirrored
		}

		DispatchQueue.main.async {
			let info = FrameInfo(
				buffer: final.data,
				width: final.w,
				height: final.h,
				rotation: effectiveRotation,
				isGrayscale: req.isGrayscale()
			)
			self.onFrameAvailable?(info)
		}
	}

	internal func rotateData(_ src: Data, w: Int, h: Int, degrees: Int, gray: Bool) -> (data: Data, w: Int, h: Int) {
		let normalizedDegrees = ((degrees % 360) + 360) % 360
		if normalizedDegrees == 0 { return (src, w, h) }

		let newW = (normalizedDegrees == 90 || normalizedDegrees == 270) ? h : w
		let newH = (normalizedDegrees == 90 || normalizedDegrees == 270) ? w : h
		let bytesPerPixel = gray ? 1 : 4
		var dst = [UInt8](repeating: 0, count: src.count)
		let srcArray = [UInt8](src)

		for y in 0..<h {
			for x in 0..<w {
				var dx = 0, dy = 0
				switch normalizedDegrees {
				case 90:
					dx = h - 1 - y
					dy = x
				case 180:
					dx = w - 1 - x
					dy = h - 1 - y
				case 270:
					dx = y
					dy = w - 1 - x
				default: break
				}

				let srcIdx = (y * w + x) * bytesPerPixel
				let dstIdx = (dy * newW + dx) * bytesPerPixel

				for i in 0..<bytesPerPixel {
					dst[dstIdx + i] = srcArray[srcIdx + i]
				}
			}
		}
		return (Data(dst), newW, newH)
	}

	/// Flips a pixel buffer horizontally, vertically, or both.
	/// Dimensions are preserved — only pixel positions are rearranged.
	/// Applied after rotation, matching Android post-processing order.
	internal func mirrorData(_ src: Data, w: Int, h: Int, gray: Bool,
			horizontal: Bool, vertical: Bool) -> (data: Data, w: Int, h: Int) {
		guard horizontal || vertical else { return (src, w, h) }
		let bytesPerPixel = gray ? 1 : 4
		var dst = [UInt8](repeating: 0, count: src.count)
		let srcArray = [UInt8](src)

		for y in 0..<h {
			let dy = vertical ? (h - 1 - y) : y
			for x in 0..<w {
				let dx = horizontal ? (w - 1 - x) : x
				let srcIdx = (y * w + x) * bytesPerPixel
				let dstIdx = (dy * w + dx) * bytesPerPixel
				for i in 0..<bytesPerPixel {
					dst[dstIdx + i] = srcArray[srcIdx + i]
				}
			}
		}
		return (Data(dst), w, h)
	}

	/// Scales a pixel buffer to `dstW × dstH` using nearest-neighbour interpolation.
	/// Applied after rotation and mirroring — the last post-processing step before emit.
	/// Supports both RGBA (4 bytes/pixel) and grayscale (1 byte/pixel) buffers.
	internal func scaleData(_ src: Data, srcW: Int, srcH: Int,
			dstW: Int, dstH: Int, gray: Bool) -> (data: Data, w: Int, h: Int) {
		let bytesPerPixel = gray ? 1 : 4
		var dst = [UInt8](repeating: 0, count: dstW * dstH * bytesPerPixel)
		let srcArray = [UInt8](src)

		for dy in 0..<dstH {
			let sy = dy * srcH / dstH
			for dx in 0..<dstW {
				let sx = dx * srcW / dstW
				let srcIdx = (sy * srcW + sx) * bytesPerPixel
				let dstIdx = (dy * dstW + dx) * bytesPerPixel
				for i in 0..<bytesPerPixel {
					dst[dstIdx + i] = srcArray[srcIdx + i]
				}
			}
		}
		return (Data(dst), dstW, dstH)
	}
}
