//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.model;

import android.util.Log;
import android.util.Size;

import android.graphics.ImageFormat;
import android.hardware.camera2.CameraCharacteristics;

import java.util.ArrayList;
import java.util.List;

import org.godotengine.godot.Dictionary;


public class CameraInfo {
	private static final String CLASS_NAME = CameraInfo.class.getSimpleName();
	private static final String LOG_TAG = "godot::" + CLASS_NAME;

	private static final String DATA_CAMERA_ID_PROPERTY = "camera_id";
	private static final String DATA_IS_FRONT_FACING_PROPERTY = "is_front_facing";
	private static final String DATA_OUTPUT_SIZES_PROPERTY = "output_sizes";

	private String cameraId;
	private CameraCharacteristics characteristics;

	public CameraInfo(String cameraId, CameraCharacteristics characteristics) {
		this.cameraId = cameraId;
		this.characteristics = characteristics;
	}

	public Dictionary buildRawData() {
		Dictionary dict = new Dictionary();

		dict.put(DATA_CAMERA_ID_PROPERTY, cameraId);

		Integer facing = characteristics.get(CameraCharacteristics.LENS_FACING);
		// Default to BACK if null, otherwise check if FRONT
		dict.put(DATA_IS_FRONT_FACING_PROPERTY, facing != null && facing == CameraCharacteristics.LENS_FACING_FRONT);

		Size[] sizes = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
					.getOutputSizes(ImageFormat.YUV_420_888);
					
		List<Dictionary> dictList = new ArrayList<>();
		for (Size size : sizes) {
			dictList.add(new FrameSize(size).buildRawData());
		}
		dict.put(DATA_OUTPUT_SIZES_PROPERTY, dictList.toArray());

		return dict;
	}
}
