//
// © 2026-present https://github.com/cengiz-pz
//

import Foundation
import AVFoundation

@objc public final class CameraInfo: NSObject {
	@objc let id: String
	@objc let device: AVCaptureDevice
	@objc let outputSizes: [FrameSize] // Added to facilitate passing data

	init(id cameraId: String, device: AVCaptureDevice, outputSizes: [FrameSize]) {
		self.id = cameraId
		self.device = device
		self.outputSizes = outputSizes
		super.init()
	}
}
