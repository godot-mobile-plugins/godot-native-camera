//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.model;

import android.util.Size;

import org.godotengine.godot.Dictionary;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link FrameSize}.
 *
 * <p>{@link android.util.Size} is an Android framework class, so it is mocked
 * with Mockito rather than requiring a real Android runtime.
 */
@ExtendWith(MockitoExtension.class)
public class FrameSizeTest {

	// ── helper ────────────────────────────────────────────────────────────

	private static Size size(int w, int h) {
		Size s = mock(Size.class);
		when(s.getWidth()).thenReturn(w);
		when(s.getHeight()).thenReturn(h);
		return s;
	}

	// ── normal resolutions ────────────────────────────────────────────────

	@Test
	public void buildRawData_1920x1080_widthCorrect() {
		assertEquals(1920, new FrameSize(size(1920, 1080)).buildRawData().get("width"));
	}

	@Test
	public void buildRawData_1920x1080_heightCorrect() {
		assertEquals(1080, new FrameSize(size(1920, 1080)).buildRawData().get("height"));
	}

	@Test
	public void buildRawData_1280x720_roundTrips() {
		Dictionary d = new FrameSize(size(1280, 720)).buildRawData();
		assertEquals(1280, d.get("width"));
		assertEquals(720, d.get("height"));
	}

	@Test
	public void buildRawData_640x480_roundTrips() {
		Dictionary d = new FrameSize(size(640, 480)).buildRawData();
		assertEquals(640, d.get("width"));
		assertEquals(480, d.get("height"));
	}

	// ── edge cases ────────────────────────────────────────────────────────

	@Test
	public void buildRawData_squareFrame_sameWidthAndHeight() {
		Dictionary d = new FrameSize(size(512, 512)).buildRawData();
		assertEquals(d.get("width"), d.get("height"));
	}

	@Test
	public void buildRawData_1x1_minimalFrame() {
		Dictionary d = new FrameSize(size(1, 1)).buildRawData();
		assertEquals(1, d.get("width"));
		assertEquals(1, d.get("height"));
	}

	// ── key completeness ─────────────────────────────────────────────────

	@Test
	public void buildRawData_containsWidthKey() {
		assertTrue(new FrameSize(size(100, 200)).buildRawData().containsKey("width"));
	}

	@Test
	public void buildRawData_containsHeightKey() {
		assertTrue(new FrameSize(size(100, 200)).buildRawData().containsKey("height"));
	}

	@Test
	public void buildRawData_exactlyTwoKeys() {
		assertEquals(2, new FrameSize(size(100, 200)).buildRawData().size());
	}

	// ── successive calls ─────────────────────────────────────────────────

	@Test
	public void buildRawData_calledTwice_returnsDifferentInstances() {
		FrameSize fs = new FrameSize(size(320, 240));
		assertNotSame(fs.buildRawData(), fs.buildRawData());
	}
}
