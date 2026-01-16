//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.model;

import android.util.Log;

import org.godotengine.godot.Dictionary;


public class FrameInfo {
	private static final String CLASS_NAME = FrameInfo.class.getSimpleName();
	private static final String LOG_TAG = "godot::" + CLASS_NAME;

	private static final String DATA_BUFFER_PROPERTY = "buffer";
	private static final String DATA_WIDTH_PROPERTY = "width";
	private static final String DATA_HEIGHT_PROPERTY = "height";
	private static final String DATA_ROTATION_PROPERTY = "rotation";
	private static final String DATA_IS_GRAYSCALE_PROPERTY = "is_grayscale";

	private byte[] buffer;
	private int width;
	private int height;
	private int rotation;
	private boolean isGrayscale;

	public FrameInfo(byte[] buffer, int width, int height, int rotation, boolean isGrayscale) {
		this.buffer = buffer;
		this.width = width;
		this.height = height;
		this.rotation = rotation;
		this.isGrayscale = isGrayscale;
	}

	public Dictionary buildRawData() {
		Dictionary dict = new Dictionary();

		dict.put(DATA_BUFFER_PROPERTY, buffer);
		dict.put(DATA_WIDTH_PROPERTY, width);
		dict.put(DATA_HEIGHT_PROPERTY, height);
		dict.put(DATA_ROTATION_PROPERTY, rotation);
		dict.put(DATA_IS_GRAYSCALE_PROPERTY, isGrayscale);

		return dict;
	}
}
