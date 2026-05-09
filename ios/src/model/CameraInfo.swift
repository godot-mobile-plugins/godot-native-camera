//
// © 2026-present https://github.com/cengiz-pz
//

import AVFoundation
import Foundation

@objc public final class CameraInfo: NSObject {
	@objc let id: String
	@objc let device: AVCaptureDevice
	@objc let outputSizes: [FrameSize]

	/// The clockwise angle in degrees (0, 90, 180, or 270) that the camera
	/// sensor image must be rotated to be upright when the device is held in
	/// its natural (portrait) orientation.
	///
	/// On iPhone, all built-in cameras capture natively in landscape, so this
	/// value is 90°.  On some iPad models the camera may be mounted differently
	/// and return 0°.  The value is a fixed hardware property and does not
	/// change with device rotation.  It is used alongside `isFrontFacing` to
	/// implement custom frame-processing pipelines that must account for sensor
	/// mounting angle independently of live device orientation.
	@objc let sensorOrientation: Int

	@objc(initWithId:device:outputSizes:sensorOrientation:)
	init(id cameraId: String, device: AVCaptureDevice, outputSizes: [FrameSize], sensorOrientation: Int) {
		self.id = cameraId
		self.device = device
		self.outputSizes = outputSizes
		self.sensorOrientation = sensorOrientation
		super.init()
	}
}
