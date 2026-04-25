//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.fixtures;

import org.godotengine.godot.Dictionary;


/**
 * Factory methods that build {@link Dictionary} instances for use in
 * {@link org.godotengine.plugin.nativecamera.model.FeedRequest} unit tests.
 */
public final class FeedRequestFixtures {

	private FeedRequestFixtures() {
	}

	/** All fields populated with non-default values. scale_width and scale_height are 0 (disabled). */
	public static Dictionary fullDict() {
		Dictionary d = new Dictionary();
		d.put("camera_id", "0");
		d.put("width", 1280L);
		d.put("height", 720L);
		d.put("frames_to_skip", 2L);
		d.put("rotation", 90L);
		d.put("is_grayscale", false);
		d.put("mirror_horizontal", false);
		d.put("mirror_vertical", false);
		d.put("scale_width", 0L);
		d.put("scale_height", 0L);
		return d;
	}

	/** No fields at all — every getter should return its safe default. */
	public static Dictionary emptyDict() {
		return new Dictionary();
	}

	/**
	 * Only camera_id + width + height; optional fields absent so that
	 * their defaults are exercised.
	 */
	public static Dictionary minimalDict() {
		Dictionary d = new Dictionary();
		d.put("camera_id", "0");
		d.put("width", 1280L);
		d.put("height", 720L);
		return d;
	}

	/** Front-facing camera (id = "1"). */
	public static Dictionary frontCameraDict() {
		Dictionary d = fullDict();
		d.put("camera_id", "1");
		return d;
	}

	/** Rotation set to 180°. */
	public static Dictionary rotated180Dict() {
		Dictionary d = fullDict();
		d.put("rotation", 180L);
		return d;
	}

	/** Rotation set to 270°. */
	public static Dictionary rotated270Dict() {
		Dictionary d = fullDict();
		d.put("rotation", 270L);
		return d;
	}

	/** is_grayscale = true, everything else at full-dict values. */
	public static Dictionary grayscaleDict() {
		Dictionary d = fullDict();
		d.put("is_grayscale", true);
		return d;
	}

	/** mirror_horizontal = true, everything else at full-dict values. */
	public static Dictionary mirrorHorizontalDict() {
		Dictionary d = fullDict();
		d.put("mirror_horizontal", true);
		return d;
	}

	/** mirror_vertical = true, everything else at full-dict values. */
	public static Dictionary mirrorVerticalDict() {
		Dictionary d = fullDict();
		d.put("mirror_vertical", true);
		return d;
	}

	/** Both mirror axes enabled. */
	public static Dictionary mirrorBothDict() {
		Dictionary d = fullDict();
		d.put("mirror_horizontal", true);
		d.put("mirror_vertical", true);
		return d;
	}

	// ── Scale variants ─────────────────────────────────────────────────────

	/**
	 * Both scale dimensions set to 640×360 — half the default 1280×720 capture
	 * size. Scaling should be applied because both values are non-zero.
	 */
	public static Dictionary scaledDict() {
		Dictionary d = fullDict();
		d.put("scale_width", 640L);
		d.put("scale_height", 360L);
		return d;
	}

	/**
	 * scale_width populated, scale_height remains 0 (from fullDict).
	 * Scaling must NOT be applied when either dimension is zero.
	 */
	public static Dictionary scaleWidthOnlyDict() {
		Dictionary d = fullDict();
		d.put("scale_width", 640L);
		// scale_height stays 0L from fullDict
		return d;
	}

	/**
	 * scale_height populated, scale_width remains 0 (from fullDict).
	 * Scaling must NOT be applied when either dimension is zero.
	 */
	public static Dictionary scaleHeightOnlyDict() {
		Dictionary d = fullDict();
		d.put("scale_height", 360L);
		// scale_width stays 0L from fullDict
		return d;
	}

	/**
	 * Scale dimensions that equal the capture resolution (1280×720).
	 * The guard passes; the plugin skips the copy as src == dst size.
	 */
	public static Dictionary scaleIdentityDict() {
		Dictionary d = fullDict();
		d.put("scale_width", 1280L);
		d.put("scale_height", 720L);
		return d;
	}
}
