//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.model;

import org.godotengine.godot.Dictionary;


public class FeedRequest {
	private static final String CLASS_NAME = FeedRequest.class.getSimpleName();
	private static final String LOG_TAG = "godot::" + CLASS_NAME;

	private static final String DATA_CAMERA_ID_PROPERTY = "camera_id";
	private static final String DATA_WIDTH_PROPERTY = "width";
	private static final String DATA_HEIGHT_PROPERTY = "height";
	private static final String DATA_FRAMES_TO_SKIP_PROPERTY = "frames_to_skip";
	private static final String DATA_ROTATION_PROPERTY = "rotation";
	private static final String DATA_IS_GRAYSCALE_PROPERTY = "is_grayscale";

	private Dictionary _data;


	public FeedRequest(Dictionary data) {
		this._data = data;
	}


	public String getCameraId() {
		return _data.containsKey(DATA_CAMERA_ID_PROPERTY) ? (String) _data.get(DATA_CAMERA_ID_PROPERTY) : "";
	}


	public int getWidth() {
		return _data.containsKey(DATA_WIDTH_PROPERTY) ? toInt(_data.get(DATA_WIDTH_PROPERTY)) : -1;
	}


	public int getHeight() {
		return _data.containsKey(DATA_HEIGHT_PROPERTY) ? toInt(_data.get(DATA_HEIGHT_PROPERTY)) : -1;
	}


	public int getFramesToSkip() {
		return _data.containsKey(DATA_FRAMES_TO_SKIP_PROPERTY) ? toInt(_data.get(DATA_FRAMES_TO_SKIP_PROPERTY)) : 1;
	}


	public int getRotation() {
		return _data.containsKey(DATA_ROTATION_PROPERTY) ? toInt(_data.get(DATA_ROTATION_PROPERTY)) : 0;
	}


	public boolean isGrayscale() {
		return _data.containsKey(DATA_IS_GRAYSCALE_PROPERTY) ? (boolean) _data.get(DATA_IS_GRAYSCALE_PROPERTY) : false;
	}


	public Dictionary getRawData() {
		return _data;
	}
	

	private int toInt(Object godotInt) {
		return ((Long) godotInt).intValue();
	}
}
