//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.model;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.nativecamera.fixtures.FrameBufferFixtures;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertTrue;


/**
 * Unit tests for {@link FrameInfo}.
 *
 * <p>FrameInfo is a pure data-container; we verify that {@link FrameInfo#buildRawData()}
 * round-trips every field faithfully into the resulting {@link Dictionary}.
 */
public class FrameInfoTest {

	// ── buffer ────────────────────────────────────────────────────────────

	@Test
	public void buildRawData_bufferMatchesInput() {
		byte[] buf = FrameBufferFixtures.redRGBA2x2();
		FrameInfo info = new FrameInfo(buf, 2, 2, 0, false);
		byte[] returned = (byte[]) info.buildRawData().get("buffer");
		assertArrayEquals(buf, returned);
	}

	@Test
	public void buildRawData_emptyBufferStoredCorrectly() {
		byte[] buf = new byte[0];
		FrameInfo info = new FrameInfo(buf, 0, 0, 0, false);
		byte[] returned = (byte[]) info.buildRawData().get("buffer");
		assertNotNull(returned);
		assertEquals(0, returned.length);
	}

	// ── width / height ────────────────────────────────────────────────────

	@Test
	public void buildRawData_widthAndHeightRoundTrip() {
		FrameInfo info = new FrameInfo(new byte[4], 640, 480, 0, false);
		Dictionary d = info.buildRawData();
		assertEquals(640, d.get("width"));
		assertEquals(480, d.get("height"));
	}

	@Test
	public void buildRawData_widthAndHeightAfterRotation90_reflect_swappedDimensions() {
		// The plugin swaps w/h when rotating 90°; FrameInfo just stores whatever is given.
		FrameInfo info = new FrameInfo(new byte[480 * 640 * 4], 480, 640, 90, false);
		Dictionary d = info.buildRawData();
		assertEquals(480, d.get("width"));
		assertEquals(640, d.get("height"));
	}

	// ── rotation ─────────────────────────────────────────────────────────

	@Test
	public void buildRawData_rotationZeroStoredCorrectly() {
		FrameInfo info = new FrameInfo(new byte[4], 1, 1, 0, false);
		assertEquals(0, info.buildRawData().get("rotation"));
	}

	@Test
	public void buildRawData_rotation90StoredCorrectly() {
		FrameInfo info = new FrameInfo(new byte[4], 1, 1, 90, false);
		assertEquals(90, info.buildRawData().get("rotation"));
	}

	@Test
	public void buildRawData_rotation180StoredCorrectly() {
		FrameInfo info = new FrameInfo(new byte[4], 1, 1, 180, false);
		assertEquals(180, info.buildRawData().get("rotation"));
	}

	@Test
	public void buildRawData_rotation270StoredCorrectly() {
		FrameInfo info = new FrameInfo(new byte[4], 1, 1, 270, false);
		assertEquals(270, info.buildRawData().get("rotation"));
	}

	// ── isGrayscale ───────────────────────────────────────────────────────

	@Test
	public void buildRawData_isGrayscaleFalse() {
		FrameInfo info = new FrameInfo(new byte[16], 2, 2, 0, false);
		assertFalse((Boolean) info.buildRawData().get("is_grayscale"));
	}

	@Test
	public void buildRawData_isGrayscaleTrue() {
		FrameInfo info = new FrameInfo(new byte[4], 2, 2, 0, true);
		assertTrue((Boolean) info.buildRawData().get("is_grayscale"));
	}

	// ── key completeness ─────────────────────────────────────────────────

	@Test
	public void buildRawData_containsAllExpectedKeys() {
		FrameInfo info = new FrameInfo(new byte[4], 2, 2, 0, false);
		Dictionary d = info.buildRawData();
		assertTrue(d.containsKey("buffer"));
		assertTrue(d.containsKey("width"));
		assertTrue(d.containsKey("height"));
		assertTrue(d.containsKey("rotation"));
		assertTrue(d.containsKey("is_grayscale"));
	}

	@Test
	public void buildRawData_exactlyFiveKeys() {
		FrameInfo info = new FrameInfo(new byte[4], 2, 2, 0, false);
		assertEquals(5, info.buildRawData().size());
	}

	// ── independence of successive calls ─────────────────────────────────

	@Test
	public void buildRawData_calledTwice_returnsDifferentDictInstances() {
		FrameInfo info = new FrameInfo(new byte[4], 2, 2, 0, false);
		Dictionary d1 = info.buildRawData();
		Dictionary d2 = info.buildRawData();
		assertNotSame(d1, d2);
	}
}
