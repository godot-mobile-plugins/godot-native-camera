//
// © 2026-present https://github.com/cengiz-pz
//

import Foundation
import AVFoundation
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

	private var framesToSkip: Int = 0
	private var frameCounter: Int = 0
	private var rotation: Int = 0
	private var isGrayscale: Bool = false
	private var targetWidth: Int = 0
	private var targetHeight: Int = 0

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

	@objc public func getCameras() -> [CameraInfo] { // Changed return type
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

	@objc public func start(cameraId: String, width: Int, height: Int, skip: Int, rot: Int, gray: Bool) {
		stop() // Ensure clean start

		self.targetWidth = width
		self.targetHeight = height
		self.framesToSkip = skip
		self.rotation = rot
		self.isGrayscale = gray
		self.frameCounter = 0

		sessionQueue.async {
			let session = AVCaptureSession()
			session.beginConfiguration()

			guard let device = AVCaptureDevice(uniqueID: cameraId),
				let input = try? AVCaptureDeviceInput(device: device) else { return }

			if session.canAddInput(input) { session.addInput(input) }

			let output = AVCaptureVideoDataOutput()
			// We request BGRA for color or Y (Luma) for grayscale via the delegate
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
	}

	public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		frameCounter += 1
		if frameCounter % (framesToSkip + 1) != 0 { return }

		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

		CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
		defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }

		let width = CVPixelBufferGetWidth(imageBuffer)
		let height = CVPixelBufferGetHeight(imageBuffer)
		let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)!

		let totalPixels = width * height
		var outputData: Data

		if isGrayscale {
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

		// Handle Rotation
		let rotated = rotateData(outputData, w: width, h: height, degrees: rotation, gray: isGrayscale)

		DispatchQueue.main.async {
			let info = FrameInfo(
				buffer: rotated.data,
				width: rotated.w,
				height: rotated.h,
				rotation: self.rotation,
				isGrayscale: self.isGrayscale
			)
			self.onFrameAvailable?(info)
		}
	}

	private func rotateData(_ src: Data, w: Int, h: Int, degrees: Int, gray: Bool) -> (data: Data, w: Int, h: Int) {
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
}
