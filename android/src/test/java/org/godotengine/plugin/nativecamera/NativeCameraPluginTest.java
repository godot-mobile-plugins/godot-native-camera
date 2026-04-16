//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import org.godotengine.godot.Godot;
import org.godotengine.plugin.nativecamera.fixtures.FeedRequestFixtures;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;

/**
 * Unit tests for {@link NativeCameraPlugin}.
 *
 * <p>All Android framework dependencies are mocked with Mockito:
 * <ul>
 *   <li>{@link Activity} — mocked instance injected via a mocked {@link Godot}.</li>
 *   <li>{@link ContextCompat} / {@link ActivityCompat} — mocked as static to control
 *       permission check and request outcomes without a real runtime.</li>
 * </ul>
 *
 * <p>Tests cover plugin metadata, permission guard rails, signal registration,
 * and start/stop lifecycle state.
 */
@ExtendWith(MockitoExtension.class)
public class NativeCameraPluginTest {

	private Activity activity;
	private Godot godot;
	private NativeCameraPlugin plugin;

	// Static mocks are opened once per test and closed in @AfterEach so that
	// each test starts with a clean slate and no static mock leaks between tests.
	private MockedStatic<ContextCompat> mockedContextCompat;
	private MockedStatic<ActivityCompat> mockedActivityCompat;

	@BeforeEach
	public void setUp() {
		activity = mock(Activity.class);
		godot = mock(Godot.class);
		// lenient: many tests (metadata, stop, onMainRequestPermissionsResult) never
		// reach getActivity(), so strict mode would flag this as an unnecessary stubbing.
		lenient().when(godot.getActivity()).thenReturn(activity);

		mockedContextCompat = mockStatic(ContextCompat.class);
		mockedActivityCompat = mockStatic(ActivityCompat.class);

		plugin = new NativeCameraPlugin(godot);
	}

	@AfterEach
	public void tearDown() {
		mockedContextCompat.close();
		mockedActivityCompat.close();
		plugin.stop(); // ensure any background thread is cleaned up
	}

	// ── Permission-check helper ───────────────────────────────────────────

	private void grantCameraPermission() {
		mockedContextCompat.when(() ->
				ContextCompat.checkSelfPermission(eq(activity), eq(Manifest.permission.CAMERA)))
				.thenReturn(PackageManager.PERMISSION_GRANTED);
	}

	private void denyCameraPermission() {
		mockedContextCompat.when(() ->
				ContextCompat.checkSelfPermission(eq(activity), eq(Manifest.permission.CAMERA)))
				.thenReturn(PackageManager.PERMISSION_DENIED);
	}

	// ── Plugin metadata ───────────────────────────────────────────────────

	@Test
	public void getPluginName_returnsSimpleClassName() {
		assertEquals("NativeCameraPlugin", plugin.getPluginName());
	}

	@Test
	public void getPluginSignals_containsThreeSignals() {
		assertEquals(3, plugin.getPluginSignals().size());
	}

	@Test
	public void getPluginSignals_containsCameraPermissionGranted() {
		assertTrue(plugin.getPluginSignals().stream()
				.anyMatch(s -> s.getName().equals("camera_permission_granted")));
	}

	@Test
	public void getPluginSignals_containsCameraPermissionDenied() {
		assertTrue(plugin.getPluginSignals().stream()
				.anyMatch(s -> s.getName().equals("camera_permission_denied")));
	}

	@Test
	public void getPluginSignals_containsFrameAvailable() {
		assertTrue(plugin.getPluginSignals().stream()
				.anyMatch(s -> s.getName().equals("frame_available")));
	}

	// ── has_camera_permission ─────────────────────────────────────────────

	@Test
	public void hasCameraPermission_whenDenied_returnsFalse() {
		denyCameraPermission();
		assertFalse(plugin.has_camera_permission());
	}

	@Test
	public void hasCameraPermission_whenGranted_returnsTrue() {
		grantCameraPermission();
		assertTrue(plugin.has_camera_permission());
	}

	// ── request_camera_permission ─────────────────────────────────────────

	@Test
	public void requestCameraPermission_whenAlreadyGranted_doesNotCallRequestPermissions() {
		grantCameraPermission();
		plugin.request_camera_permission();
		mockedActivityCompat.verify(
				() -> ActivityCompat.requestPermissions(any(), any(), anyInt()),
				never());
	}

	@Test
	public void requestCameraPermission_whenDenied_callsRequestPermissionsWithCameraPermission() {
		denyCameraPermission();
		plugin.request_camera_permission();
		mockedActivityCompat.verify(
				() -> ActivityCompat.requestPermissions(
						eq(activity),
						argThat(perms -> {
							for (String p : perms) {
								if (Manifest.permission.CAMERA.equals(p)) {
									return true;
								}
							}
							return false;
						}),
						eq(1001)),
				times(1));
	}

	// ── onMainRequestPermissionsResult ────────────────────────────────────

	@Test
	public void onMainRequestPermissionsResult_granted_doesNotThrow() {
		plugin.onMainRequestPermissionsResult(
				1001,
				new String[]{Manifest.permission.CAMERA},
				new int[]{PackageManager.PERMISSION_GRANTED});
	}

	@Test
	public void onMainRequestPermissionsResult_denied_doesNotThrow() {
		plugin.onMainRequestPermissionsResult(
				1001,
				new String[]{Manifest.permission.CAMERA},
				new int[]{PackageManager.PERMISSION_DENIED});
	}

	@Test
	public void onMainRequestPermissionsResult_wrongRequestCode_doesNotThrow() {
		plugin.onMainRequestPermissionsResult(
				9999,
				new String[]{Manifest.permission.CAMERA},
				new int[]{PackageManager.PERMISSION_GRANTED});
	}

	@Test
	public void onMainRequestPermissionsResult_emptyGrantResults_doesNotThrow() {
		plugin.onMainRequestPermissionsResult(1001, new String[]{}, new int[]{});
	}

	// ── get_all_cameras ───────────────────────────────────────────────────

	@Test
	public void getAllCameras_withoutPermission_returnsEmptyArray() {
		denyCameraPermission();
		Object[] cameras = plugin.get_all_cameras();
		assertNotNull(cameras);
		assertEquals(0, cameras.length);
	}

	// ── start / stop state guard ──────────────────────────────────────────

	@Test
	public void start_withoutPermission_doesNotSetRunningState() throws Exception {
		denyCameraPermission();
		plugin.start(FeedRequestFixtures.fullDict());

		java.lang.reflect.Field runningField =
				NativeCameraPlugin.class.getDeclaredField("running");
		runningField.setAccessible(true);
		assertFalse((Boolean) runningField.get(plugin));
	}

	@Test
	public void stop_whenNotRunning_doesNotThrow() {
		plugin.stop();
	}

	@Test
	public void stop_calledTwice_doesNotThrow() {
		plugin.stop();
		plugin.stop();
	}
}
