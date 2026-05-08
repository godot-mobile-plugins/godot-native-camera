//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera;

import android.app.Activity;
import android.content.Context;
import android.view.Display;
import android.view.Surface;
import android.view.WindowManager;

import org.godotengine.godot.Godot;
import org.godotengine.plugin.nativecamera.fixtures.FeedRequestFixtures;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;


/**
 * Tests for the {@code computeUprightRotation()} method inside
 * {@link NativeCameraPlugin} and for the {@code autoUpright} field
 * that gates its use.
 *
 * <h2>Formula under test</h2>
 * <pre>
 *   Back camera:  uprightRotation = (sensorOrientation − deviceDegrees + 360) % 360
 *   Front camera: uprightRotation = (sensorOrientation + deviceDegrees + 360) % 360
 * </pre>
 *
 * <h2>Device-orientation mapping</h2>
 * <pre>
 *   Surface.ROTATION_0   → 0°
 *   Surface.ROTATION_90  → 90°
 *   Surface.ROTATION_180 → 180°
 *   Surface.ROTATION_270 → 270°
 * </pre>
 *
 * <h2>Strategy</h2>
 * <p>{@code computeUprightRotation()} is private and non-static, so it is
 * invoked via reflection.  The three instance fields it reads
 * ({@code sensorOrientation}, {@code isFrontFacingCamera}, and the Android
 * {@link Activity}/{@link WindowManager} chain that yields the device rotation)
 * are injected either through reflection or through mocks.</p>
 *
 * <p>Because these tests run on a plain JVM without Robolectric,
 * {@code Build.VERSION.SDK_INT} is 0, which is always less than
 * {@code Build.VERSION_CODES.R} (30).  The plugin therefore always enters its
 * legacy {@code WindowManager.getDefaultDisplay().getRotation()} branch —
 * the very branch exercised by every test here.</p>
 */
@SuppressWarnings("deprecation") // WindowManager.getDefaultDisplay() is deprecated in API 30
@ExtendWith(MockitoExtension.class)
public class NativeCameraPluginAutoUprightTest {

	private Activity activity;
	private Godot godot;
	private NativeCameraPlugin plugin;

	/** Mocked WindowManager returned by {@code activity.getSystemService(WINDOW_SERVICE)}. */
	private WindowManager windowManager;

	/** Mocked Display returned by {@code windowManager.getDefaultDisplay()}. */
	private Display display;

	@BeforeEach
	public void setUp() {
		activity = mock(Activity.class);
		godot = mock(Godot.class);
		lenient().when(godot.getActivity()).thenReturn(activity);

		windowManager = mock(WindowManager.class);
		display = mock(Display.class);

		// Wire the Android display-rotation dependency used by computeUprightRotation().
		// The plugin calls activity.getSystemService(WINDOW_SERVICE) on the legacy branch.
		lenient().when(activity.getSystemService(Context.WINDOW_SERVICE)).thenReturn(windowManager);
		lenient().when(windowManager.getDefaultDisplay()).thenReturn(display);

		plugin = new NativeCameraPlugin(godot);
	}

	@AfterEach
	public void tearDown() {
		plugin.stop();
	}

	// -- Reflection helpers ------------------------------------------------

	/**
	 * Calls the private {@code computeUprightRotation()} instance method and
	 * returns the int result.
	 */
	private int computeUprightRotation() throws Exception {
		Method m = NativeCameraPlugin.class.getDeclaredMethod("computeUprightRotation");
		m.setAccessible(true);
		return (int) m.invoke(plugin);
	}

	/** Sets a private int field on the plugin instance. */
	private void setInt(String fieldName, int value) throws Exception {
		Field f = NativeCameraPlugin.class.getDeclaredField(fieldName);
		f.setAccessible(true);
		f.setInt(plugin, value);
	}

	/** Sets a private boolean field on the plugin instance. */
	private void setBoolean(String fieldName, boolean value) throws Exception {
		Field f = NativeCameraPlugin.class.getDeclaredField(fieldName);
		f.setAccessible(true);
		f.setBoolean(plugin, value);
	}

	/** Gets a private boolean field from the plugin instance. */
	private boolean getBoolean(String fieldName) throws Exception {
		Field f = NativeCameraPlugin.class.getDeclaredField(fieldName);
		f.setAccessible(true);
		return f.getBoolean(plugin);
	}

	/**
	 * Configures the mocked display to report the given {@link Surface} rotation
	 * constant (ROTATION_0 / ROTATION_90 / ROTATION_180 / ROTATION_270).
	 */
	private void setDeviceRotation(int surfaceRotation) {
		when(display.getRotation()).thenReturn(surfaceRotation);
	}

	// -- autoUpright field: populated correctly from FeedRequest ----------

	@Test
	public void autoUprightField_falseByDefault() throws Exception {
		// Before any start() call the field must be false.
		assertFalse(getBoolean("autoUpright"));
	}

	@Test
	public void autoUprightField_trueAfterExplicitSet() throws Exception {
		setBoolean("autoUpright", true);
		assertTrue(getBoolean("autoUpright"));
	}

	@Test
	public void autoUprightField_falseWhenFeedRequestDisablesIt() throws Exception {
		// Simulates what start() does: it reads isAutoUpright() from the request.
		setBoolean("autoUpright",
				new org.godotengine.plugin.nativecamera.model.FeedRequest(
						FeedRequestFixtures.fullDict()).isAutoUpright());
		assertFalse(getBoolean("autoUpright"));
	}

	@Test
	public void autoUprightField_trueWhenFeedRequestEnablesIt() throws Exception {
		setBoolean("autoUpright",
				new org.godotengine.plugin.nativecamera.model.FeedRequest(
						FeedRequestFixtures.autoUprightDict()).isAutoUpright());
		assertTrue(getBoolean("autoUpright"));
	}

	// -- Back camera — sensor orientation 90° (most common Android sensor) -

	/**
	 * Typical back camera resting in natural (portrait) orientation.
	 * Formula: (90 − 0 + 360) % 360 = 90
	 */
	@Test
	public void backCamera_sensor90_devicePortrait_returns90() throws Exception {
		setInt("sensorOrientation", 90);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_0);

		assertEquals(90, computeUprightRotation());
	}

	/**
	 * Back camera, device rotated 90° CW (landscape).
	 * Formula: (90 − 90 + 360) % 360 = 0 — no rotation needed.
	 */
	@Test
	public void backCamera_sensor90_deviceLandscape90_returns0() throws Exception {
		setInt("sensorOrientation", 90);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_90);

		assertEquals(0, computeUprightRotation());
	}

	/**
	 * Back camera, device rotated 180° (upside-down portrait).
	 * Formula: (90 − 180 + 360) % 360 = 270
	 */
	@Test
	public void backCamera_sensor90_deviceUpsideDown_returns270() throws Exception {
		setInt("sensorOrientation", 90);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_180);

		assertEquals(270, computeUprightRotation());
	}

	/**
	 * Back camera, device rotated 270° CW (reverse landscape).
	 * Formula: (90 − 270 + 360) % 360 = 180
	 */
	@Test
	public void backCamera_sensor90_deviceLandscape270_returns180() throws Exception {
		setInt("sensorOrientation", 90);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_270);

		assertEquals(180, computeUprightRotation());
	}

	// -- Back camera — sensor orientation 0° ------------------------------

	@Test
	public void backCamera_sensor0_devicePortrait_returns0() throws Exception {
		setInt("sensorOrientation", 0);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_0);

		assertEquals(0, computeUprightRotation());
	}

	@Test
	public void backCamera_sensor0_deviceLandscape90_returns270() throws Exception {
		// (0 − 90 + 360) % 360 = 270
		setInt("sensorOrientation", 0);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_90);

		assertEquals(270, computeUprightRotation());
	}

	// -- Back camera — sensor orientation 180° ----------------------------

	@Test
	public void backCamera_sensor180_devicePortrait_returns180() throws Exception {
		// (180 − 0 + 360) % 360 = 180
		setInt("sensorOrientation", 180);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_0);

		assertEquals(180, computeUprightRotation());
	}

	@Test
	public void backCamera_sensor180_deviceLandscape90_returns90() throws Exception {
		// (180 − 90 + 360) % 360 = 90
		setInt("sensorOrientation", 180);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_90);

		assertEquals(90, computeUprightRotation());
	}

	// -- Back camera — sensor orientation 270° ----------------------------

	@Test
	public void backCamera_sensor270_devicePortrait_returns270() throws Exception {
		// (270 − 0 + 360) % 360 = 270
		setInt("sensorOrientation", 270);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_0);

		assertEquals(270, computeUprightRotation());
	}

	@Test
	public void backCamera_sensor270_deviceLandscape270_returns0() throws Exception {
		// (270 − 270 + 360) % 360 = 0
		setInt("sensorOrientation", 270);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_270);

		assertEquals(0, computeUprightRotation());
	}

	@Test
	public void backCamera_sensor270_deviceLandscape90_returns180() throws Exception {
		// (270 − 90 + 360) % 360 = 540 % 360 = 180
		setInt("sensorOrientation", 270);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_90);

		assertEquals(180, computeUprightRotation());
	}

	// -- Front camera — sensor orientation 270° (most common selfie sensor) -

	/**
	 * Front camera in portrait.  Selfie sensors add rather than subtract because
	 * the image is horizontally mirrored.
	 * Formula: (270 + 0 + 360) % 360 = 270
	 */
	@Test
	public void frontCamera_sensor270_devicePortrait_returns270() throws Exception {
		setInt("sensorOrientation", 270);
		setBoolean("isFrontFacingCamera", true);
		setDeviceRotation(Surface.ROTATION_0);

		assertEquals(270, computeUprightRotation());
	}

	/**
	 * Front camera rotated 90°.
	 * Formula: (270 + 90 + 360) % 360 = 720 % 360 = 0 — no rotation needed.
	 */
	@Test
	public void frontCamera_sensor270_deviceLandscape90_returns0() throws Exception {
		setInt("sensorOrientation", 270);
		setBoolean("isFrontFacingCamera", true);
		setDeviceRotation(Surface.ROTATION_90);

		assertEquals(0, computeUprightRotation());
	}

	/**
	 * Front camera rotated 180°.
	 * Formula: (270 + 180 + 360) % 360 = 810 % 360 = 90
	 */
	@Test
	public void frontCamera_sensor270_deviceUpsideDown_returns90() throws Exception {
		setInt("sensorOrientation", 270);
		setBoolean("isFrontFacingCamera", true);
		setDeviceRotation(Surface.ROTATION_180);

		assertEquals(90, computeUprightRotation());
	}

	/**
	 * Front camera rotated 270°.
	 * Formula: (270 + 270 + 360) % 360 = 900 % 360 = 180
	 */
	@Test
	public void frontCamera_sensor270_deviceLandscape270_returns180() throws Exception {
		setInt("sensorOrientation", 270);
		setBoolean("isFrontFacingCamera", true);
		setDeviceRotation(Surface.ROTATION_270);

		assertEquals(180, computeUprightRotation());
	}

	// -- Front camera — sensor orientation 90° ----------------------------

	@Test
	public void frontCamera_sensor90_devicePortrait_returns90() throws Exception {
		// (90 + 0 + 360) % 360 = 90
		setInt("sensorOrientation", 90);
		setBoolean("isFrontFacingCamera", true);
		setDeviceRotation(Surface.ROTATION_0);

		assertEquals(90, computeUprightRotation());
	}

	@Test
	public void frontCamera_sensor90_deviceLandscape90_returns180() throws Exception {
		// (90 + 90 + 360) % 360 = 540 % 360 = 180
		setInt("sensorOrientation", 90);
		setBoolean("isFrontFacingCamera", true);
		setDeviceRotation(Surface.ROTATION_90);

		assertEquals(180, computeUprightRotation());
	}

	// -- Front camera — sensor orientation 0° -----------------------------

	@Test
	public void frontCamera_sensor0_devicePortrait_returns0() throws Exception {
		// (0 + 0 + 360) % 360 = 0
		setInt("sensorOrientation", 0);
		setBoolean("isFrontFacingCamera", true);
		setDeviceRotation(Surface.ROTATION_0);

		assertEquals(0, computeUprightRotation());
	}

	@Test
	public void frontCamera_sensor0_deviceLandscape90_returns90() throws Exception {
		// (0 + 90 + 360) % 360 = 450 % 360 = 90
		setInt("sensorOrientation", 0);
		setBoolean("isFrontFacingCamera", true);
		setDeviceRotation(Surface.ROTATION_90);

		assertEquals(90, computeUprightRotation());
	}

	// -- Front vs back produce different results for the same inputs -------

	/**
	 * When the sensor orientation and device rotation are the same, front and
	 * back cameras must generally produce different results because the
	 * formulas differ (subtract vs add).
	 *
	 * <p>With sensor=90 and device=90: back=0, front=180 — they must differ.
	 */
	@Test
	public void frontAndBackCamera_sameSensorAndDeviceRotation_produceDifferentResults()
			throws Exception {
		setInt("sensorOrientation", 90);
		setDeviceRotation(Surface.ROTATION_90);

		setBoolean("isFrontFacingCamera", false);
		int backResult = computeUprightRotation();

		setBoolean("isFrontFacingCamera", true);
		int frontResult = computeUprightRotation();

		assertNotEquals(backResult, frontResult,
				"Back and front cameras should require different rotations for the same inputs");
	}

	// -- Result is always a valid rotation value ---------------------------

	/**
	 * Whatever the inputs, the result must be one of the four canonical
	 * rotation angles {0, 90, 180, 270}.
	 */
	@Test
	public void allDeviceRotations_backCamera_resultIsAlwaysCanonical() throws Exception {
		int[] surfaceRotations = {
				Surface.ROTATION_0, Surface.ROTATION_90,
				Surface.ROTATION_180, Surface.ROTATION_270
		};
		int[] sensorAngles = {0, 90, 180, 270};
		int[] validAngles = {0, 90, 180, 270};

		setBoolean("isFrontFacingCamera", false);

		for (int sensor : sensorAngles) {
			setInt("sensorOrientation", sensor);
			for (int deviceRot : surfaceRotations) {
				setDeviceRotation(deviceRot);
				int result = computeUprightRotation();
				boolean isValid = false;
				for (int valid : validAngles) {
					if (result == valid) {
						isValid = true;
						break;
					}
				}
				assertTrue(isValid,
						String.format("Expected canonical angle but got %d "
								+ "(sensor=%d, deviceRot=%d)", result, sensor, deviceRot));
			}
		}
	}

	@Test
	public void allDeviceRotations_frontCamera_resultIsAlwaysCanonical() throws Exception {
		int[] surfaceRotations = {
				Surface.ROTATION_0, Surface.ROTATION_90,
				Surface.ROTATION_180, Surface.ROTATION_270
		};
		int[] sensorAngles = {0, 90, 180, 270};
		int[] validAngles = {0, 90, 180, 270};

		setBoolean("isFrontFacingCamera", true);

		for (int sensor : sensorAngles) {
			setInt("sensorOrientation", sensor);
			for (int deviceRot : surfaceRotations) {
				setDeviceRotation(deviceRot);
				int result = computeUprightRotation();
				boolean isValid = false;
				for (int valid : validAngles) {
					if (result == valid) {
						isValid = true;
						break;
					}
				}
				assertTrue(isValid,
						String.format("Expected canonical angle but got %d "
								+ "(sensor=%d, deviceRot=%d)", result, sensor, deviceRot));
			}
		}
	}

	// -- Consistent across consecutive calls ------------------------------

	/**
	 * Two successive calls with the same device orientation must return the
	 * same value — the method must be side-effect-free and read-only.
	 */
	@Test
	public void computeUprightRotation_consecutiveCalls_returnSameValue() throws Exception {
		setInt("sensorOrientation", 90);
		setBoolean("isFrontFacingCamera", false);
		setDeviceRotation(Surface.ROTATION_90);

		int first = computeUprightRotation();
		int second = computeUprightRotation();

		assertEquals(first, second);
	}

	/**
	 * Result changes immediately when the simulated device rotation changes,
	 * confirming that the live display rotation is read on every call.
	 */
	@Test
	public void computeUprightRotation_updatesWhenDeviceRotationChanges() throws Exception {
		setInt("sensorOrientation", 90);
		setBoolean("isFrontFacingCamera", false);

		setDeviceRotation(Surface.ROTATION_0);
		int portrait = computeUprightRotation(); // expected 90

		setDeviceRotation(Surface.ROTATION_90);
		int landscape = computeUprightRotation(); // expected 0

		assertNotEquals(portrait, landscape,
				"Rotation result must update when the device orientation changes");
		assertEquals(90, portrait);
		assertEquals(0, landscape);
	}
}
