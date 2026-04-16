//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.model;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.nativecamera.fixtures.FeedRequestFixtures;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;


/**
 * Unit tests for {@link FeedRequest}.
 *
 * <p>FeedRequest wraps a Godot {@link Dictionary} and exposes typed getters.
 * Because Godot integers arrive as {@code Long}, each numeric getter must
 * downcast to {@code int} without throwing.
 */
public class FeedRequestTest {

	// ── cameraId ─────────────────────────────────────────────────────────

	@Test
	public void getCameraId_returnsValueFromDict() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.fullDict());
		assertEquals("0", req.getCameraId());
	}

	@Test
	public void getCameraId_missingKey_returnsEmptyString() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.emptyDict());
		assertEquals("", req.getCameraId());
	}

	@Test
	public void getCameraId_frontCamera_returnsCorrectId() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.frontCameraDict());
		assertEquals("1", req.getCameraId());
	}

	// ── width ─────────────────────────────────────────────────────────────

	@Test
	public void getWidth_returnsValueFromDict() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.fullDict());
		assertEquals(1280, req.getWidth());
	}

	@Test
	public void getWidth_missingKey_returnsNegativeOne() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.emptyDict());
		assertEquals(-1, req.getWidth());
	}

	// ── height ────────────────────────────────────────────────────────────

	@Test
	public void getHeight_returnsValueFromDict() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.fullDict());
		assertEquals(720, req.getHeight());
	}

	@Test
	public void getHeight_missingKey_returnsNegativeOne() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.emptyDict());
		assertEquals(-1, req.getHeight());
	}

	// ── framesToSkip ──────────────────────────────────────────────────────

	@Test
	public void getFramesToSkip_returnsValueFromDict() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.fullDict());
		assertEquals(2, req.getFramesToSkip());
	}

	@Test
	public void getFramesToSkip_missingKey_returnsDefaultOne() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.emptyDict());
		assertEquals(1, req.getFramesToSkip());
	}

	@Test
	public void getFramesToSkip_minimalDict_returnsDefaultOne() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.minimalDict());
		assertEquals(1, req.getFramesToSkip());
	}

	// ── rotation ──────────────────────────────────────────────────────────

	@Test
	public void getRotation_returnsValueFromDict() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.fullDict());
		assertEquals(90, req.getRotation());
	}

	@Test
	public void getRotation_180_returnsCorrectValue() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.rotated180Dict());
		assertEquals(180, req.getRotation());
	}

	@Test
	public void getRotation_270_returnsCorrectValue() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.rotated270Dict());
		assertEquals(270, req.getRotation());
	}

	@Test
	public void getRotation_missingKey_returnsDefaultZero() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.emptyDict());
		assertEquals(0, req.getRotation());
	}

	// ── isGrayscale ───────────────────────────────────────────────────────

	@Test
	public void isGrayscale_falseInFullDict() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.fullDict());
		assertFalse(req.isGrayscale());
	}

	@Test
	public void isGrayscale_trueInGrayscaleDict() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.grayscaleDict());
		assertTrue(req.isGrayscale());
	}

	@Test
	public void isGrayscale_missingKey_defaultsFalse() {
		FeedRequest req = new FeedRequest(FeedRequestFixtures.emptyDict());
		assertFalse(req.isGrayscale());
	}

	// ── getRawData ────────────────────────────────────────────────────────

	@Test
	public void getRawData_returnsSameDictInstance() {
		Dictionary dict = FeedRequestFixtures.fullDict();
		FeedRequest req = new FeedRequest(dict);
		assertSame(dict, req.getRawData());
	}

	// ── type coercion (Long -> int) ───────────────────────────────────────

	@Test
	public void intFields_neverThrowClassCastException_forLongValues() {
		// Godot always sends integers as Long; verify no ClassCastException is thrown.
		Dictionary d = new Dictionary();
		d.put("width", Long.MAX_VALUE);
		d.put("height", Long.MAX_VALUE);
		d.put("frames_to_skip", Long.MAX_VALUE);
		d.put("rotation", Long.MAX_VALUE);
		FeedRequest req = new FeedRequest(d);
		// Just calling the getters must not throw
		req.getWidth();
		req.getHeight();
		req.getFramesToSkip();
		req.getRotation();
	}
}
