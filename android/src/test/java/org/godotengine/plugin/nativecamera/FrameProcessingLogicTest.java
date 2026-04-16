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
 * Tests for the frame-skip and buffer-sizing logic embedded in
 * {@code NativeCameraPlugin.onImageAvailable()}.
 *
 * <p>These rules come directly from the plugin source:
 * <ul>
 *   <li>{@code framesToSkipDivisor = feedRequest.getFramesToSkip() + 1}</li>
 *   <li>A frame is processed when {@code ++frameCounter % divisor == 0}</li>
 *   <li>RGBA buffer size  = {@code width * height * 4}</li>
 *   <li>Gray buffer size  = {@code width * height}</li>
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
}
