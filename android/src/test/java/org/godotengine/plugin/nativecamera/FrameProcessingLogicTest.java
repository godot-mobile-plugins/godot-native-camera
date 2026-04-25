//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertSame;


/**
 * Tests for the frame-skip, buffer-sizing, and scaling logic embedded in
 * {@code NativeCameraPlugin.onImageAvailable()}.
 *
 * <p>These rules come directly from the plugin source:
 * <ul>
 *   <li>{@code framesToSkipDivisor = feedRequest.getFramesToSkip() + 1}</li>
 *   <li>A frame is processed when {@code ++frameCounter % divisor == 0}</li>
 *   <li>RGBA buffer size  = {@code width * height * 4}</li>
 *   <li>Gray buffer size  = {@code width * height}</li>
 *   <li>Scaling uses nearest-neighbour and is applied only when both
 *       {@code scaleWidth > 0} and {@code scaleHeight > 0}</li>
 * </ul>
 *
 * The logic is pure arithmetic so no Android environment is required.
 */
public class FrameProcessingLogicTest {

	// ─────────────────────────────────────────────────────────────────────
	//  Frame-skip divisor calculation
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void divisor_framesToSkip0_divisorIs1() {
		// skip=0 → process every frame → divisor 1 (every frame passes % 1 == 0)
		assertEquals(1, framesToSkipDivisor(0));
	}

	@Test
	public void divisor_framesToSkip1_divisorIs2() {
		assertEquals(2, framesToSkipDivisor(1));
	}

	@Test
	public void divisor_framesToSkip2_divisorIs3() {
		assertEquals(3, framesToSkipDivisor(2));
	}

	@Test
	public void divisor_framesToSkip4_divisorIs5() {
		assertEquals(5, framesToSkipDivisor(4));
	}

	// ─────────────────────────────────────────────────────────────────────
	//  Frame-skip counting (which frames are actually processed)
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void frameSkip_divisor1_everyFrameIsProcessed() {
		int divisor = framesToSkipDivisor(0);
		int processed = countProcessedFrames(divisor, 6);
		assertEquals(6, processed);
	}

	@Test
	public void frameSkip_divisor2_everyOtherFrameIsProcessed() {
		// frames 2, 4, 6 are processed from a stream of 6
		int divisor = framesToSkipDivisor(1);
		int processed = countProcessedFrames(divisor, 6);
		assertEquals(3, processed);
	}

	@Test
	public void frameSkip_divisor3_everyThirdFrameIsProcessed() {
		// frames 3, 6, 9 from a stream of 9
		int divisor = framesToSkipDivisor(2);
		int processed = countProcessedFrames(divisor, 9);
		assertEquals(3, processed);
	}

	@Test
	public void frameSkip_divisor5_exactCount() {
		// frames 5, 10, 15, 20 from a stream of 20
		int divisor = framesToSkipDivisor(4);
		int processed = countProcessedFrames(divisor, 20);
		assertEquals(4, processed);
	}

	/** First processed frame is at index == divisor (counter starts at 0, pre-incremented). */
	@Test
	public void frameSkip_divisor3_firstProcessedFrameIsThird() {
		int divisor = framesToSkipDivisor(2);
		int firstProcessed = firstProcessedFrameIndex(divisor);
		assertEquals(3, firstProcessed);
	}

	@Test
	public void frameSkip_divisor1_firstProcessedFrameIsFirst() {
		int divisor = framesToSkipDivisor(0);
		assertEquals(1, firstProcessedFrameIndex(divisor));
	}

	// ─────────────────────────────────────────────────────────────────────
	//  Buffer size calculation
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void bufferSize_rgba_1x1() {
		assertEquals(4, rgbaBufferSize(1, 1));
	}

	@Test
	public void bufferSize_rgba_640x480() {
		assertEquals(640 * 480 * 4, rgbaBufferSize(640, 480));
	}

	@Test
	public void bufferSize_rgba_1920x1080() {
		assertEquals(1920 * 1080 * 4, rgbaBufferSize(1920, 1080));
	}

	@Test
	public void bufferSize_gray_1x1() {
		assertEquals(1, grayBufferSize(1, 1));
	}

	@Test
	public void bufferSize_gray_640x480() {
		assertEquals(640 * 480, grayBufferSize(640, 480));
	}

	@Test
	public void bufferSize_gray_isFourTimesSmaller_thanRgba() {
		int w = 320;
		int h = 240;
		assertEquals(rgbaBufferSize(w, h), grayBufferSize(w, h) * 4);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  Buffer reuse: a new allocation is only needed when the required size
	//  changes (mirrors the null-check / size-check in onImageAvailable)
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void bufferReuse_sameSize_noReallocation() {
		byte[] existing = new byte[640 * 480 * 4];
		byte[] result = getOrAllocBuffer(existing, 640, 480, false);
		assertSame(existing, result);
	}

	@Test
	public void bufferReuse_differentSize_newAllocation() {
		byte[] existing = new byte[640 * 480 * 4];
		byte[] result = getOrAllocBuffer(existing, 1280, 720, false);
		assertNotSame(existing, result);
		assertEquals(1280 * 720 * 4, result.length);
	}

	@Test
	public void bufferReuse_null_allocatesNewBuffer() {
		byte[] result = getOrAllocBuffer(null, 320, 240, true);
		assertNotNull(result);
		assertEquals(320 * 240, result.length);
	}

	@Test
	public void bufferReuse_switchFromColorToGray_reallocates() {
		// Colour buffer: 2×2×4 = 16 bytes; gray: 2×2 = 4 bytes
		byte[] colorBuf = new byte[2 * 2 * 4];
		byte[] result = getOrAllocBuffer(colorBuf, 2, 2, true);
		assertNotSame(colorBuf, result);
		assertEquals(4, result.length);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  Scale guard: enabled only when both dimensions are > 0
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void scaleGuard_bothZero_scalingDisabled() {
		// scaleWidth=0, scaleHeight=0 → no scaling
		assertScalingEnabled(0, 0, 640, 480, false);
	}

	@Test
	public void scaleGuard_widthZeroHeightNonZero_scalingDisabled() {
		assertScalingEnabled(0, 360, 640, 480, false);
	}

	@Test
	public void scaleGuard_widthNonZeroHeightZero_scalingDisabled() {
		assertScalingEnabled(320, 0, 640, 480, false);
	}

	@Test
	public void scaleGuard_bothNonZero_scalingEnabled() {
		assertScalingEnabled(320, 240, 640, 480, true);
	}

	@Test
	public void scaleGuard_dimensionsEqualSource_scalingStillApplied() {
		// Even when target == source the guard passes; the caller decides whether to no-op.
		assertScalingEnabled(640, 480, 640, 480, true);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  scaleRGBA – buffer length and pixel-position correctness
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void scaleRGBA_outputLengthIsCorrect() {
		byte[] src = new byte[4 * 4 * 4]; // 4×4 RGBA
		byte[] dst = NativeCameraPlugin.scaleRGBA(src, 4, 4, 2, 2);
		assertEquals(2 * 2 * 4, dst.length);
	}

	@Test
	public void scaleRGBA_upscale_outputLengthIsCorrect() {
		byte[] src = new byte[2 * 2 * 4]; // 2×2 RGBA
		byte[] dst = NativeCameraPlugin.scaleRGBA(src, 2, 2, 4, 4);
		assertEquals(4 * 4 * 4, dst.length);
	}

	@Test
	public void scaleRGBA_topLeftPixelIsPreserved() {
		// Nearest-neighbour: dst(0,0) must map to src(0,0).
		byte[] src = new byte[4 * 4 * 4];
		src[0] = 10;
		src[1] = 20;
		src[2] = 30;
		src[3] = (byte) 255; // TL pixel
		byte[] dst = NativeCameraPlugin.scaleRGBA(src, 4, 4, 2, 2);
		assertEquals(10, dst[0]);
		assertEquals(20, dst[1]);
		assertEquals(30, dst[2]);
		assertEquals((byte) 255, dst[3]);
	}

	@Test
	public void scaleRGBA_identityScale_preservesAllPixels() {
		byte[] src = new byte[2 * 2 * 4];
		for (int i = 0; i < src.length; i++) {
			src[i] = (byte) (i % 256);
		}
		byte[] dst = NativeCameraPlugin.scaleRGBA(src, 2, 2, 2, 2);
		for (int i = 0; i < src.length; i++) {
			assertEquals(src[i], dst[i], "Mismatch at byte " + i);
		}
	}

	@Test
	public void scaleRGBA_halveResolution_bufferSizeIsQuarterOfSource() {
		// 8×8 → 4×4: pixels = 1/4, bytes = 1/4.
		byte[] src = new byte[8 * 8 * 4];
		byte[] dst = NativeCameraPlugin.scaleRGBA(src, 8, 8, 4, 4);
		assertEquals(src.length / 4, dst.length);
	}

	@Test
	public void scaleRGBA_1x1Source_outputHasCorrectSize() {
		byte[] src = new byte[]{10, 20, 30, (byte) 255};
		byte[] dst = NativeCameraPlugin.scaleRGBA(src, 1, 1, 3, 3);
		assertEquals(3 * 3 * 4, dst.length);
		// Every pixel must be the single source pixel
		for (int i = 0; i < dst.length; i += 4) {
			assertEquals(10, dst[i], "R at pixel " + i / 4);
			assertEquals(20, dst[i + 1], "G at pixel " + i / 4);
			assertEquals(30, dst[i + 2], "B at pixel " + i / 4);
			assertEquals((byte) 255, dst[i + 3], "A at pixel " + i / 4);
		}
	}

	// ─────────────────────────────────────────────────────────────────────
	//  scaleGray – buffer length and pixel-position correctness
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void scaleGray_outputLengthIsCorrect() {
		byte[] src = new byte[4 * 4]; // 4×4 grayscale
		byte[] dst = NativeCameraPlugin.scaleGray(src, 4, 4, 2, 2);
		assertEquals(2 * 2, dst.length);
	}

	@Test
	public void scaleGray_upscale_outputLengthIsCorrect() {
		byte[] src = new byte[2 * 2];
		byte[] dst = NativeCameraPlugin.scaleGray(src, 2, 2, 4, 4);
		assertEquals(4 * 4, dst.length);
	}

	@Test
	public void scaleGray_topLeftPixelIsPreserved() {
		byte[] src = new byte[4 * 4];
		src[0] = 42;
		byte[] dst = NativeCameraPlugin.scaleGray(src, 4, 4, 2, 2);
		assertEquals(42, dst[0]);
	}

	@Test
	public void scaleGray_identityScale_preservesAllPixels() {
		byte[] src = new byte[]{10, 20, 30, 40};
		byte[] dst = NativeCameraPlugin.scaleGray(src, 2, 2, 2, 2);
		for (int i = 0; i < src.length; i++) {
			assertEquals(src[i], dst[i], "Mismatch at byte " + i);
		}
	}

	@Test
	public void scaleGray_halveResolution_bufferSizeIsQuarterOfSource() {
		byte[] src = new byte[8 * 8];
		byte[] dst = NativeCameraPlugin.scaleGray(src, 8, 8, 4, 4);
		assertEquals(src.length / 4, dst.length);
	}

	@Test
	public void scaleGray_1x1Source_allOutputPixelsMatchSource() {
		byte[] src = new byte[]{(byte) 99};
		byte[] dst = NativeCameraPlugin.scaleGray(src, 1, 1, 3, 3);
		assertEquals(9, dst.length);
		for (byte b : dst) {
			assertEquals((byte) 99, b);
		}
	}

	// ─────────────────────────────────────────────────────────────────────
	//  Scale + grayscale buffer size relationship
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void scaledGrayBuffer_isFourTimesSmaller_thanScaledRgbaBuffer() {
		int w = 320;
		int h = 240;
		byte[] srcRgba = new byte[w * h * 4];
		byte[] srcGray = new byte[w * h];

		byte[] dstRgba = NativeCameraPlugin.scaleRGBA(srcRgba, w, h, 160, 120);
		byte[] dstGray = NativeCameraPlugin.scaleGray(srcGray, w, h, 160, 120);

		assertEquals(dstRgba.length, dstGray.length * 4);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  Pure-Java helpers that mirror the plugin's inline formulas
	// ─────────────────────────────────────────────────────────────────────

	private static int framesToSkipDivisor(int framesToSkip) {
		return framesToSkip + 1;
	}

	private static int countProcessedFrames(int divisor, int totalFrames) {
		int counter = 0;
		int processed = 0;
		for (int i = 0; i < totalFrames; i++) {
			counter++;
			if (counter % divisor == 0) {
				processed++;
			}
		}
		return processed;
	}

	private static int firstProcessedFrameIndex(int divisor) {
		int counter = 0;
		while (true) {
			counter++;
			if (counter % divisor == 0) {
				return counter;
			}
		}
	}

	private static int rgbaBufferSize(int width, int height) {
		return width * height * 4;
	}

	private static int grayBufferSize(int width, int height) {
		return width * height;
	}

	/** Mirrors the null-or-wrong-size guard in {@code onImageAvailable}. */
	private static byte[] getOrAllocBuffer(byte[] existing, int width, int height, boolean isGrayscale) {
		int required = isGrayscale ? (width * height) : (width * height * 4);
		if (existing == null || existing.length != required) {
			return new byte[required];
		}
		return existing;
	}

	/**
	 * Mirrors the scale-guard condition in {@code onImageAvailable}:
	 * scaling is enabled when both {@code scaleWidth} and {@code scaleHeight} are > 0.
	 */
	private static void assertScalingEnabled(int scaleWidth, int scaleHeight,
											int currentWidth, int currentHeight,
											boolean expectEnabled) {
		boolean enabled = scaleWidth > 0 && scaleHeight > 0;
		assertEquals(expectEnabled, enabled,
				String.format("scaleWidth=%d scaleHeight=%d", scaleWidth, scaleHeight));
	}
}
