//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.fixtures;


/**
 * Pre-built pixel buffers used across frame-processing tests.
 *
 * <p>Layout conventions used everywhere in the plugin:
 * <ul>
 *   <li>RGBA – 4 bytes per pixel, row-major.</li>
 *   <li>Gray – 1 byte per pixel, row-major.</li>
 * </ul>
 */
public final class FrameBufferFixtures {

	private FrameBufferFixtures() {
	}

	// ── tiny 2 × 2 RGBA frames ────────────────────────────────────────────

	/**
	* 2 × 2 solid-red RGBA frame.
	*
	* <pre>
	*  [R G B A] for every pixel = [255 0 0 255]
	* </pre>
	*/
	public static byte[] redRGBA2x2() {
		byte[] b = new byte[2 * 2 * 4];
		for (int i = 0; i < 4; i++) {
			b[i * 4] = (byte) 255; // R
			b[i * 4 + 1] = 0;          // G
			b[i * 4 + 2] = 0;          // B
			b[i * 4 + 3] = (byte) 255; // A
		}
		return b;
	}

	/**
	* 2 × 3 RGBA frame where every pixel encodes its (row, col) as R and G.
	*
	* <pre>
	*  pixel(row, col) = [row, col, 0, 255]
	* </pre>
	*/
	public static byte[] indexedRGBA2x3() {
		int w = 2;
		int h = 3;
		byte[] b = new byte[w * h * 4];
		int i = 0;
		for (int row = 0; row < h; row++) {
			for (int col = 0; col < w; col++) {
				b[i++] = (byte) row;   // R = row index
				b[i++] = (byte) col;   // G = col index
				b[i++] = 0;            // B
				b[i++] = (byte) 255;   // A
			}
		}
		return b;
	}

	// ── tiny 2 × 2 grayscale frames ──────────────────────────────────────

	/**
	* 2 × 2 grayscale frame, all pixels = 128 (mid-grey).
	*/
	public static byte[] midGray2x2() {
		byte[] b = new byte[4];
		for (int i = 0; i < 4; i++) {
			b[i] = (byte) 128;
		}
		return b;
	}

	/**
	* 2 × 3 grayscale frame where pixel(row, col) value = row * 10 + col.
	*
	* <pre>
	*  0   1
	* 10  11
	* 20  21
	* </pre>
	*/
	public static byte[] indexedGray2x3() {
		int w = 2;
		int h = 3;
		byte[] b = new byte[w * h];
		for (int row = 0; row < h; row++) {
			for (int col = 0; col < w; col++) {
				b[row * w + col] = (byte) (row * 10 + col);
			}
		}
		return b;
	}

	// ── YUV plane simulation helpers ──────────────────────────────────────

	/**
	* Returns a flat Y-plane for a {@code width × height} image where every
	* pixel luminance equals {@code yValue}.
	*/
	public static byte[] uniformYPlane(int width, int height, int yValue) {
		byte[] b = new byte[width * height];
		for (int i = 0; i < b.length; i++) {
			b[i] = (byte) yValue;
		}
		return b;
	}

	/**
	* Returns a flat UV-plane (half resolution) for a {@code width × height}
	* image where every sample equals {@code uvValue}.
	*/
	public static byte[] uniformUVPlane(int width, int height, int uvValue) {
		byte[] b = new byte[(width / 2) * (height / 2)];
		for (int i = 0; i < b.length; i++) {
			b[i] = (byte) uvValue;
		}
		return b;
	}
}
