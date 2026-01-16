//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.model;

import android.util.Log;
import android.util.Size;

import org.godotengine.godot.Dictionary;


public class FrameSize {
	private static final String CLASS_NAME = FrameSize.class.getSimpleName();
	private static final String LOG_TAG = "godot::" + CLASS_NAME;

	private static final String DATA_WIDTH_PROPERTY = "width";
	private static final String DATA_HEIGHT_PROPERTY = "height";

	private Size size;

	public FrameSize(Size size) {
		this.size = size;
	}

	public Dictionary buildRawData() {
		Dictionary dict = new Dictionary();

		dict.put(DATA_WIDTH_PROPERTY, size.getWidth());
		dict.put(DATA_HEIGHT_PROPERTY, size.getHeight());

		return dict;
	}
}
