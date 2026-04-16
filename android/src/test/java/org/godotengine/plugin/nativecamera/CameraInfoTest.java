//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera.model;

import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.graphics.ImageFormat;
import android.util.Size;

import org.godotengine.godot.Dictionary;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link CameraInfo}.
 *
 * <p>All Android framework classes are mocked with Mockito — no real Android runtime is required.
 */
@ExtendWith(MockitoExtension.class)
public class CameraInfoTest {

	// ── helpers ───────────────────────────────────────────────────────────

	private static Size size(int w, int h) {
		Size s = mock(Size.class);
		when(s.getWidth()).thenReturn(w);
		when(s.getHeight()).thenReturn(h);
		return s;
	}

	@SuppressWarnings("unchecked")
	private CameraCharacteristics mockCharacteristics(int facing, Size[] outputSizes) {
		CameraCharacteristics chars = mock(CameraCharacteristics.class);
		StreamConfigurationMap map = mock(StreamConfigurationMap.class);

		// Using any() avoids the raw class literal warning,
		// and SuppressWarnings handles the generic return stubbing.
		when(chars.get(any()))
				.thenReturn(facing)
				.thenReturn(map);

		when(map.getOutputSizes(ImageFormat.YUV_420_888)).thenReturn(outputSizes);

		return chars;
	}

	@SuppressWarnings("unchecked")
	private CameraCharacteristics mockCharacteristicsNoMap(int facing) {
		CameraCharacteristics chars = mock(CameraCharacteristics.class);

		when(chars.get(any()))
				.thenReturn(facing)
				.thenReturn(null);   // no map

		return chars;
	}

	@SuppressWarnings("unchecked")
	private CameraCharacteristics mockCharacteristicsNullFacing(Size[] outputSizes) {
		CameraCharacteristics chars = mock(CameraCharacteristics.class);
		StreamConfigurationMap map = mock(StreamConfigurationMap.class);

		when(chars.get(any()))
				.thenReturn(null)     // null facing
				.thenReturn(map);

		when(map.getOutputSizes(ImageFormat.YUV_420_888)).thenReturn(outputSizes);

		return chars;
	}

	// ── camera_id ─────────────────────────────────────────────────────────

	@Test
	public void buildRawData_cameraIdBackCamera() {
		CameraInfo info = new CameraInfo("0",
				mockCharacteristics(CameraCharacteristics.LENS_FACING_BACK, new Size[0]));
		assertEquals("0", info.buildRawData().get("camera_id"));
	}

	@Test
	public void buildRawData_cameraIdFrontCamera() {
		CameraInfo info = new CameraInfo("1",
				mockCharacteristics(CameraCharacteristics.LENS_FACING_FRONT, new Size[0]));
		assertEquals("1", info.buildRawData().get("camera_id"));
	}

	// ── is_front_facing ───────────────────────────────────────────────────

	@Test
	public void buildRawData_backCamera_isFrontFacingFalse() {
		CameraInfo info = new CameraInfo("0",
				mockCharacteristics(CameraCharacteristics.LENS_FACING_BACK, new Size[0]));
		assertFalse((Boolean) info.buildRawData().get("is_front_facing"));
	}

	@Test
	public void buildRawData_frontCamera_isFrontFacingTrue() {
		CameraInfo info = new CameraInfo("1",
				mockCharacteristics(CameraCharacteristics.LENS_FACING_FRONT, new Size[0]));
		assertTrue((Boolean) info.buildRawData().get("is_front_facing"));
	}

	@Test
	public void buildRawData_nullFacing_isFrontFacingFalse() {
		CameraInfo info = new CameraInfo("2",
				mockCharacteristicsNullFacing(new Size[0]));
		assertFalse((Boolean) info.buildRawData().get("is_front_facing"));
	}

	// ── output_sizes ──────────────────────────────────────────────────────

	@Test
	public void buildRawData_noOutputSizes_returnsEmptyArray() {
		CameraInfo info = new CameraInfo("0",
				mockCharacteristics(CameraCharacteristics.LENS_FACING_BACK, new Size[0]));
		Object[] sizes = (Object[]) info.buildRawData().get("output_sizes");
		assertNotNull(sizes);
		assertEquals(0, sizes.length);
	}

	@Test
	public void buildRawData_twoOutputSizes_returnsTwoEntries() {
		Size[] sizes = {size(1920, 1080), size(1280, 720)};
		CameraInfo info = new CameraInfo("0",
				mockCharacteristics(CameraCharacteristics.LENS_FACING_BACK, sizes));
		Object[] result = (Object[]) info.buildRawData().get("output_sizes");
		assertEquals(2, result.length);
	}

	@Test
	public void buildRawData_outputSizesContainWidthAndHeight() {
		Size[] sizes = {size(640, 480)};
		CameraInfo info = new CameraInfo("0",
				mockCharacteristics(CameraCharacteristics.LENS_FACING_BACK, sizes));
		Object[] result = (Object[]) info.buildRawData().get("output_sizes");
		Dictionary sizeDict = (Dictionary) result[0];
		assertEquals(640, sizeDict.get("width"));
		assertEquals(480, sizeDict.get("height"));
	}

	@Test
	public void buildRawData_nullStreamConfigMap_returnsEmptyOutputSizes() {
		CameraInfo info = new CameraInfo("0",
				mockCharacteristicsNoMap(CameraCharacteristics.LENS_FACING_BACK));
		Object[] result = (Object[]) info.buildRawData().get("output_sizes");
		assertNotNull(result);
		assertEquals(0, result.length);
	}

	@Test
	public void buildRawData_nullOutputSizesArray_returnsEmptyArray() {
		CameraInfo info = new CameraInfo("0",
				mockCharacteristics(CameraCharacteristics.LENS_FACING_BACK, null));
		Object[] result = (Object[]) info.buildRawData().get("output_sizes");
		assertNotNull(result);
		assertEquals(0, result.length);
	}

	// ── key completeness ─────────────────────────────────────────────────

	@Test
	public void buildRawData_containsAllExpectedKeys() {
		CameraInfo info = new CameraInfo("0",
				mockCharacteristics(CameraCharacteristics.LENS_FACING_BACK, new Size[0]));
		Dictionary d = info.buildRawData();
		assertTrue(d.containsKey("camera_id"));
		assertTrue(d.containsKey("is_front_facing"));
		assertTrue(d.containsKey("output_sizes"));
	}
}
