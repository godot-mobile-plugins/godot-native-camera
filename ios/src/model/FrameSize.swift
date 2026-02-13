//
// © 2026-present https://github.com/cengiz-pz
//

import Foundation

@objc public final class FrameSize: NSObject {
	@objc let width: Int
	@objc let height: Int

	init(width: Int, height: Int) {
		self.width = width
		self.height = height
		super.init()
	}
}
