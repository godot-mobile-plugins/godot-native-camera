//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.fixtures;

import org.godotengine.godot.Dictionary;


/**
 * Centralised test data for {@link org.godotengine.plugin.nativecamera.model.FeedRequest}.
 */
public final class FeedRequestFixtures {

	private FeedRequestFixtures() {
	}

	// ── canonical complete request ──────────────────────────────────────────

	public static Dictionary fullDict() {
		Dictionary d = new Dictionary();
		d.put("camera_id", "0");
		d.put("width", (long) 1280);
		d.put("height", (long) 720);
		d.put("frames_to_skip", (long) 2);
		d.put("rotation", (long) 90);
		d.put("is_grayscale", false);
		return d;
	}

	public static Dictionary grayscaleDict() {
		Dictionary d = fullDict();
		d.put("is_grayscale", true);
		d.put("rotation", (long) 0);
		return d;
	}

	public static Dictionary rotated180Dict() {
		Dictionary d = fullDict();
		d.put("rotation", (long) 180);
		return d;
	}

	public static Dictionary rotated270Dict() {
		Dictionary d = fullDict();
		d.put("rotation", (long) 270);
		return d;
	}

	// ── partial / missing-field variants ────────────────────────────────────

	/** Only camera_id supplied – every other field should fall back to its default. */
	public static Dictionary minimalDict() {
		Dictionary d = new Dictionary();
		d.put("camera_id", "1");
		return d;
	}

	/** Completely empty dictionary. */
	public static Dictionary emptyDict() {
		return new Dictionary();
	}

	// ── front-camera variant ────────────────────────────────────────────────

	public static Dictionary frontCameraDict() {
		Dictionary d = fullDict();
		d.put("camera_id", "1");
		return d;
	}
}
