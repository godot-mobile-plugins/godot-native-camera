//
// © 2026-present https://github.com/cengiz-pz
//

import Foundation

@objc public final class FrameInfo: NSObject {
	@objc let buffer: Data
	@objc let width: Int
	@objc let height: Int
	@objc let rotation: Int
	@objc let isGrayscale: Bool

	init(buffer: Data, width: Int, height: Int, rotation: Int, isGrayscale: Bool) {
		self.buffer = buffer
		self.width = width
		self.height = height
		self.rotation = rotation
		self.isGrayscale = isGrayscale
		super.init()
	}
}
