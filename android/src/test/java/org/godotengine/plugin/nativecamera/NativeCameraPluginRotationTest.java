//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera;

import org.godotengine.plugin.nativecamera.fixtures.FrameBufferFixtures;

import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;


/**
 * Tests for the private static rotation helpers inside {@link NativeCameraPlugin}:
 * {@code rotateRGBA} and {@code rotateGray}.
 *
 * <p>Because both methods are private, we invoke them via reflection.  A small
 * accessor helper ({@link #rotateRGBA} / {@link #rotateGray}) keeps test bodies
 * clean while still exercising the real implementation.
 */
public class NativeCameraPluginRotationTest {

	// ── Reflection accessors ─────────────────────────────────────────────

	/** Mirror of the inner RotationResult returned by the plugin. */
	private static class RotationResult {
		byte[] buffer;
		int width;
		int height;
	}

	private static RotationResult rotateRGBA(byte[] src, int w, int h, int rotation)
			throws Exception {
		return invokeRotate("rotateRGBA", src, w, h, rotation);
	}

	private static RotationResult rotateGray(byte[] src, int w, int h, int rotation)
			throws Exception {
		return invokeRotate("rotateGray", src, w, h, rotation);
	}

	private static RotationResult invokeRotate(String methodName, byte[] src,
											int w, int h, int rotation) throws Exception {
		Method m = NativeCameraPlugin.class.getDeclaredMethod(
				methodName, byte[].class, int.class, int.class, int.class);
		m.setAccessible(true);
		Object raw = m.invoke(null, src, w, h, rotation);

		RotationResult r = new RotationResult();
		r.buffer = (byte[]) raw.getClass().getDeclaredField("buffer").get(raw);
		r.width = raw.getClass().getDeclaredField("width").getInt(raw);
		r.height = raw.getClass().getDeclaredField("height").getInt(raw);
		return r;
	}

	// ─────────────────────────────────────────────────────────────────────
	//  rotateRGBA – rotation = 0
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void rotateRGBA_0degrees_returnsSameBuffer() throws Exception {
		byte[] src = FrameBufferFixtures.redRGBA2x2();
		RotationResult r = rotateRGBA(src, 2, 2, 0);
		assertSame(src, r.buffer);
	}

	@Test
	public void rotateRGBA_0degrees_dimensionsUnchanged() throws Exception {
		RotationResult r = rotateRGBA(FrameBufferFixtures.redRGBA2x2(), 2, 2, 0);
		assertEquals(2, r.width);
		assertEquals(2, r.height);
	}

	@Test
	public void rotateRGBA_360degrees_treatedAsZero() throws Exception {
		byte[] src = FrameBufferFixtures.redRGBA2x2();
		RotationResult r = rotateRGBA(src, 2, 2, 360);
		assertSame(src, r.buffer);
	}

	@Test
	public void rotateRGBA_negativeDegrees_normalised() throws Exception {
		// -90 should behave the same as 270
		byte[] src = FrameBufferFixtures.indexedRGBA2x3();
		RotationResult rMinus = rotateRGBA(src.clone(), 2, 3, -90);
		RotationResult r270 = rotateRGBA(src.clone(), 2, 3, 270);
		assertArrayEquals(r270.buffer, rMinus.buffer);
		assertEquals(r270.width, rMinus.width);
		assertEquals(r270.height, rMinus.height);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  rotateRGBA – rotation = 90
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void rotateRGBA_90degrees_swapsDimensions() throws Exception {
		RotationResult r = rotateRGBA(FrameBufferFixtures.indexedRGBA2x3(), 2, 3, 90);
		assertEquals(3, r.width);
		assertEquals(2, r.height);
	}

	@Test
	public void rotateRGBA_90degrees_bufferLengthUnchanged() throws Exception {
		byte[] src = FrameBufferFixtures.indexedRGBA2x3();
		RotationResult r = rotateRGBA(src, 2, 3, 90);
		assertEquals(src.length, r.buffer.length);
	}

	/**
	* For a 90° CW rotation the top-left pixel of the source becomes the
	* bottom-left pixel of the destination.
	*
	* <p>With the indexed 2×3 buffer:
	* <pre>
	*   src(0,0) = R=0, G=0   →  dst pixel at (newWidth-1, 0) = last column, first row
	*                          In a 3×2 output that is pixel index (2,0)
	*                          → dstIndex = (0 * 3 + 2) * 4 = 8
	* </pre>
	*/
	@Test
	public void rotateRGBA_90degrees_topLeftMovesToBottomLeft() throws Exception {
		byte[] src = FrameBufferFixtures.indexedRGBA2x3(); // 2 wide, 3 tall
		RotationResult r = rotateRGBA(src, 2, 3, 90);
		// src(row=0, col=0) R=0, G=0 → dst pixel at dx=(h-1-0)=2, dy=0 → index=(0*3+2)*4=8
		assertEquals((byte) 0, r.buffer[8]);     // R = original row = 0
		assertEquals((byte) 0, r.buffer[8 + 1]); // G = original col = 0
	}

	// ─────────────────────────────────────────────────────────────────────
	//  rotateRGBA – rotation = 180
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void rotateRGBA_180degrees_dimensionsUnchanged() throws Exception {
		RotationResult r = rotateRGBA(FrameBufferFixtures.indexedRGBA2x3(), 2, 3, 180);
		assertEquals(2, r.width);
		assertEquals(3, r.height);
	}

	@Test
	public void rotateRGBA_180degrees_appliedTwice_recoversOriginal() throws Exception {
		byte[] src = FrameBufferFixtures.indexedRGBA2x3();
		RotationResult r1 = rotateRGBA(src.clone(), 2, 3, 180);
		RotationResult r2 = rotateRGBA(r1.buffer, 2, 3, 180);
		assertArrayEquals(src, r2.buffer);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  rotateRGBA – rotation = 270
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void rotateRGBA_270degrees_swapsDimensions() throws Exception {
		RotationResult r = rotateRGBA(FrameBufferFixtures.indexedRGBA2x3(), 2, 3, 270);
		assertEquals(3, r.width);
		assertEquals(2, r.height);
	}

	/**
	* 90° followed by 270° must recover the original buffer.
	*/
	@Test
	public void rotateRGBA_90then270_recoversOriginal() throws Exception {
		byte[] src = FrameBufferFixtures.indexedRGBA2x3();
		RotationResult r90 = rotateRGBA(src.clone(), 2, 3, 90);
		RotationResult back = rotateRGBA(r90.buffer, r90.width, r90.height, 270);
		assertArrayEquals(src, back.buffer);
	}

	/**
	* Four 90° rotations must produce the identity.
	*/
	@Test
	public void rotateRGBA_four90degreeRotations_recoversOriginal() throws Exception {
		byte[] src = FrameBufferFixtures.indexedRGBA2x3();
		int w = 2;
		int h = 3;
		byte[] current = src.clone();
		for (int i = 0; i < 4; i++) {
			RotationResult r = rotateRGBA(current, w, h, 90);
			current = r.buffer;
			int tmp = w;
			w = r.width;
			h = r.height;
			// After two 90° rotations w/h are back to original values
		}
		assertArrayEquals(src, current);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  rotateGray – rotation = 0
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void rotateGray_0degrees_returnsSameBuffer() throws Exception {
		byte[] src = FrameBufferFixtures.midGray2x2();
		RotationResult r = rotateGray(src, 2, 2, 0);
		assertSame(src, r.buffer);
	}

	@Test
	public void rotateGray_0degrees_dimensionsUnchanged() throws Exception {
		RotationResult r = rotateGray(FrameBufferFixtures.midGray2x2(), 2, 2, 0);
		assertEquals(2, r.width);
		assertEquals(2, r.height);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  rotateGray – rotation = 90
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void rotateGray_90degrees_swapsDimensions() throws Exception {
		RotationResult r = rotateGray(FrameBufferFixtures.indexedGray2x3(), 2, 3, 90);
		assertEquals(3, r.width);
		assertEquals(2, r.height);
	}

	@Test
	public void rotateGray_90degrees_bufferLengthUnchanged() throws Exception {
		byte[] src = FrameBufferFixtures.indexedGray2x3();
		RotationResult r = rotateGray(src, 2, 3, 90);
		assertEquals(src.length, r.buffer.length);
	}

	/**
	* Indexed gray 2×3 layout (value = row*10 + col):
	* <pre>
	*   0   1
	*  10  11
	*  20  21
	* </pre>
	* After 90° CW the 3×2 output should be:
	* <pre>
	*  20  10   0
	*  21  11   1
	* </pre>
	* dst pixel at (dy=0, dx=2) = src(row=0, col=0) = 0
	*/
	@Test
	public void rotateGray_90degrees_correctPixelPlacement() throws Exception {
		byte[] src = FrameBufferFixtures.indexedGray2x3();
		RotationResult r = rotateGray(src, 2, 3, 90);
		// src(row=0,col=0)=0 → dx=h-1-0=2, dy=0  → dst[0*3+2]=dst[2]=0
		assertEquals((byte) 0, r.buffer[2]);
		// src(row=0,col=1)=1 → dx=2, dy=1         → dst[1*3+2]=dst[5]=1
		assertEquals((byte) 1, r.buffer[5]);
		// src(row=2,col=0)=20 → dx=0, dy=0        → dst[0*3+0]=dst[0]=20
		assertEquals((byte) 20, r.buffer[0]);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  rotateGray – rotation = 180
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void rotateGray_180degrees_dimensionsUnchanged() throws Exception {
		RotationResult r = rotateGray(FrameBufferFixtures.indexedGray2x3(), 2, 3, 180);
		assertEquals(2, r.width);
		assertEquals(3, r.height);
	}

	@Test
	public void rotateGray_180degrees_appliedTwice_recoversOriginal() throws Exception {
		byte[] src = FrameBufferFixtures.indexedGray2x3();
		RotationResult r1 = rotateGray(src.clone(), 2, 3, 180);
		RotationResult r2 = rotateGray(r1.buffer, 2, 3, 180);
		assertArrayEquals(src, r2.buffer);
	}

	// ─────────────────────────────────────────────────────────────────────
	//  rotateGray – rotation = 270
	// ─────────────────────────────────────────────────────────────────────

	@Test
	public void rotateGray_270degrees_swapsDimensions() throws Exception {
		RotationResult r = rotateGray(FrameBufferFixtures.indexedGray2x3(), 2, 3, 270);
		assertEquals(3, r.width);
		assertEquals(2, r.height);
	}

	@Test
	public void rotateGray_90then270_recoversOriginal() throws Exception {
		byte[] src = FrameBufferFixtures.indexedGray2x3();
		RotationResult r90 = rotateGray(src.clone(), 2, 3, 90);
		RotationResult back = rotateGray(r90.buffer, r90.width, r90.height, 270);
		assertArrayEquals(src, back.buffer);
	}

	@Test
	public void rotateGray_negativeDegrees_normalised() throws Exception {
		byte[] src = FrameBufferFixtures.indexedGray2x3();
		RotationResult rMinus = rotateGray(src.clone(), 2, 3, -270);
		RotationResult r90 = rotateGray(src.clone(), 2, 3, 90);
		assertArrayEquals(r90.buffer, rMinus.buffer);
	}
}
