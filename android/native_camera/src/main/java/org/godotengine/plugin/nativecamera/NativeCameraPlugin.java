//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.nativecamera;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.ImageFormat;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.SessionConfiguration;
import android.hardware.camera2.params.OutputConfiguration;
import android.media.Image;
import android.media.ImageReader;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.Log;
import android.view.View;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.Executor;

import org.godotengine.godot.Godot;
import org.godotengine.godot.Dictionary;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import org.godotengine.plugin.nativecamera.model.CameraInfo;
import org.godotengine.plugin.nativecamera.model.FeedRequest;
import org.godotengine.plugin.nativecamera.model.FrameInfo;


public class NativeCameraPlugin extends GodotPlugin {
	public static final String CLASS_NAME = NativeCameraPlugin.class.getSimpleName();
	static final String LOG_TAG = "godot::" + CLASS_NAME;

	private static final SignalInfo CAMERA_PERMISSION_GRANTED_SIGNAL = new SignalInfo("camera_permission_granted");
	private static final SignalInfo CAMERA_PERMISSION_DENIED_SIGNAL = new SignalInfo("camera_permission_denied");
	private static final SignalInfo FRAME_AVAILABLE_SIGNAL = new SignalInfo("frame_available", Dictionary.class);

	private static final int CAMERA_PERMISSION_REQUEST = 1001;

	private CameraDevice camera;
	private CameraCaptureSession session;
	private ImageReader reader;
	private HandlerThread bgThread;
	private Handler bgHandler;

	private byte[] frameBuffer;
	private volatile int framesToSkipDivisor;
	private volatile int rotation;
	private volatile boolean isGrayscale;
	private int frameCounter = 0;

	private volatile boolean running = false;

	public NativeCameraPlugin(Godot godot) {
		super(godot);
	}

	@Override
	public String getPluginName() {
		return CLASS_NAME;
	}

	@Override
	public Set<SignalInfo> getPluginSignals() {
		Set<SignalInfo> signals = new HashSet<>();
		signals.add(CAMERA_PERMISSION_GRANTED_SIGNAL);
		signals.add(CAMERA_PERMISSION_DENIED_SIGNAL);
		signals.add(FRAME_AVAILABLE_SIGNAL);
		return signals;
	}

	@UsedByGodot
	public boolean has_camera_permission() {
		Activity activity = getActivity();

		return (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
				== PackageManager.PERMISSION_GRANTED);
	}

	@UsedByGodot
	public void request_camera_permission() {
		Activity activity = getActivity();

		if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
				== PackageManager.PERMISSION_GRANTED) {
			Log.w(LOG_TAG, "request_camera_permission(): Camera permission already granted");
			return;
		}

		ActivityCompat.requestPermissions(
				activity,
				new String[]{Manifest.permission.CAMERA},
				CAMERA_PERMISSION_REQUEST
		);
	}

	@UsedByGodot
	public Object[] get_all_cameras() {
		Activity activity = getActivity();

		List<Dictionary> resultList = new ArrayList<>();

		if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
				!= PackageManager.PERMISSION_GRANTED) {
			Log.e(LOG_TAG, "get_all_cameras(): Camera permission not granted");
			return resultList.toArray();
		}

		CameraManager manager = (CameraManager) activity.getSystemService(Context.CAMERA_SERVICE);
		try {
			for (String cameraId : manager.getCameraIdList()) {
				resultList.add(new CameraInfo(cameraId, manager.getCameraCharacteristics(cameraId)).buildRawData());
			}
		} catch (CameraAccessException | SecurityException e) {
			Log.e(LOG_TAG, "get_all_cameras(): Failed to generate camera list", e);
		}

		return resultList.toArray();
	}

	@UsedByGodot
	public void start(Dictionary requestDict) {
		Activity activity = getActivity();

		if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
				!= PackageManager.PERMISSION_GRANTED) {
			Log.e(LOG_TAG, "start(): Camera permission not granted");
			return;
		}

		if (running) return;

		running = true;
		startThread();

		FeedRequest feedRequest = new FeedRequest(requestDict);
		framesToSkipDivisor = feedRequest.getFramesToSkip() + 1;
		rotation = feedRequest.getRotation(); // degrees
		isGrayscale = feedRequest.isGrayscale();
		openCamera(feedRequest);
	}

	@UsedByGodot
	public void stop() {
		running = false; // Immediate stop flag
		if (session != null) {
			session.close();
			session = null;
		}
		if (camera != null) {
			camera.close();
			camera = null;
		}
		if (reader != null) {
			reader.close();
			reader = null;
		}
		stopThread();
	}

	private void startThread() {
		bgThread = new HandlerThread("CameraCaptureThread");
		bgThread.start();
		bgHandler = new Handler(bgThread.getLooper());
	}

	private void stopThread() {
		if (bgThread != null) {
			bgThread.quitSafely();
			try {
				bgThread.join();
				bgThread = null;
				bgHandler = null;
			} catch (InterruptedException e) {
				Log.e(LOG_TAG, "stopThread(): Failed", e);
			}
		}
	}

	private void openCamera(FeedRequest request) {
		Activity activity = getActivity();

		CameraManager manager = (CameraManager) activity.getSystemService(Context.CAMERA_SERVICE);
		try {
			reader = ImageReader.newInstance(request.getWidth(), request.getHeight(), ImageFormat.YUV_420_888, 2);
			reader.setOnImageAvailableListener(this::onImageAvailable, bgHandler);

			manager.openCamera(request.getCameraId(), deviceCallback, bgHandler);
		} catch (CameraAccessException | SecurityException e) {
			Log.e(LOG_TAG, "openCamera(): Failed", e);
		}
	}

	void emitFrame(byte[] buffer, int width, int height, int rotation, boolean isGrayscale) {
		Activity activity = getActivity();

		Log.d(LOG_TAG, String.format("emitFrame(): Emitting frame buffer size: %d image size: %dx%d, rotation: %d, gray?: %b",
				buffer.length, width, height, rotation, isGrayscale));

		// Run on Android UI thread -> Godot main thread
		activity.runOnUiThread(() -> {
			emitSignal(FRAME_AVAILABLE_SIGNAL.getName(), new FrameInfo(buffer.clone(), width,
					height, rotation, isGrayscale).buildRawData());
		});
	}

	private final CameraDevice.StateCallback deviceCallback = new CameraDevice.StateCallback() {
		@Override
		public void onOpened(CameraDevice cameraDevice) {
			camera = cameraDevice;
			createCameraPreviewSession();
		}

		@Override public void onDisconnected(CameraDevice cameraDevice) { cameraDevice.close(); }
		@Override public void onError(CameraDevice cameraDevice, int error) { cameraDevice.close(); }
	};

	private void createCameraPreviewSession() {
		try {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
				// Use modern SessionConfiguration for API 28+
				OutputConfiguration outputConfig = new OutputConfiguration(reader.getSurface());

				// Ensure the callback runs on our background thread
				Executor executor = bgHandler::post; 

				SessionConfiguration sessionConfig = new SessionConfiguration(
						SessionConfiguration.SESSION_REGULAR,
						Collections.singletonList(outputConfig),
						executor,
						sessionCallback
				);
				camera.createCaptureSession(sessionConfig);
			} else {// Use the annotation to suppress the warning for the legacy path
				// This is necessary for devices running Android 8.1 or lower
				createLegacyCaptureSession();
			}
		} catch (CameraAccessException e) {
			e.printStackTrace();
		}
	}

	@SuppressWarnings("deprecation")
	private void createLegacyCaptureSession() throws CameraAccessException {
		camera.createCaptureSession(
				Collections.singletonList(reader.getSurface()),
				sessionCallback,
				bgHandler
		);
	}

	private final CameraCaptureSession.StateCallback sessionCallback =
			new CameraCaptureSession.StateCallback() {
				@Override
				public void onConfigured(CameraCaptureSession captureSession) {
					session = captureSession;
					try {
						CaptureRequest.Builder req =
								camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
						req.addTarget(reader.getSurface());
						req.set(CaptureRequest.CONTROL_AF_MODE,
								CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
						session.setRepeatingRequest(req.build(), null, bgHandler);
					} catch (CameraAccessException e) {
						e.printStackTrace();
					}
				}

				@Override public void onConfigureFailed(CameraCaptureSession session) {}
			};

	private void onImageAvailable(ImageReader reader) {
		if (!running) return;

		try {
			Image image = reader.acquireLatestImage();
			if (image == null) return;

			if (!running) {
				image.close();
				return;
			}

			frameCounter++;
			if (frameCounter % framesToSkipDivisor != 0) {
				image.close();
				return;
			}

			int width = image.getWidth();
			int height = image.getHeight();

			// Calculate size RGBA8 = 4 bytes, Grayscale = 1 byte per pixel
			int requiredSize = isGrayscale ? (width * height) : (width * height * 4);

			if (frameBuffer == null || frameBuffer.length != requiredSize) {
				frameBuffer = new byte[requiredSize];
			}

			Image.Plane yPlane = image.getPlanes()[0];
			ByteBuffer yBuffer = yPlane.getBuffer();
			int yRowStride = yPlane.getRowStride();
			int yPixelStride = yPlane.getPixelStride(); // Usually 1

			byte[] output = frameBuffer;
			int offset = 0;

			if (isGrayscale) {
				if (yPixelStride == 1 && yRowStride == width) {
					yBuffer.get(output, 0, width * height);
				} else {
					for (int y = 0; y < height; y++) {
						int rowStart = y * yRowStride;
						for (int x = 0; x < width; x++) {
							output[offset++] = yBuffer.get(rowStart + x * yPixelStride);
						}
					}
				}
			} else {
				// Color processing (YUV -> RGBA conversion)
				Image.Plane uPlane = image.getPlanes()[1];
				Image.Plane vPlane = image.getPlanes()[2];

				ByteBuffer uBuffer = uPlane.getBuffer();
				ByteBuffer vBuffer = vPlane.getBuffer();

				int uRowStride = uPlane.getRowStride();
				int vRowStride = vPlane.getRowStride();
				int uPixelStride = uPlane.getPixelStride();
				int vPixelStride = vPlane.getPixelStride();

				for (int y = 0; y < height; y++) {
					int yRowStart = y * yRowStride;
					int uvRowStart = (y / 2) * uRowStride; // UV is subsampled vertically

					for (int x = 0; x < width; x++) {
						// Get Y
						int yVal = yBuffer.get(yRowStart + x * yPixelStride) & 0xFF;

						// Get U and V (Subsampled 2x2)
						int uvCol = (x / 2) * uPixelStride;
						int uVal = (uBuffer.get(uvRowStart + uvCol) & 0xFF) - 128;
						int vVal = (vBuffer.get(uvRowStart + uvCol) & 0xFF) - 128;

						// YUV to RGB Conversion
						// R = Y + 1.402 * V
						// G = Y - 0.34414 * U - 0.71414 * V
						// B = Y + 1.772 * U

						int r = (int) (yVal + 1.402f * vVal);
						int g = (int) (yVal - 0.34414f * uVal - 0.71414f * vVal);
						int b = (int) (yVal + 1.772f * uVal);

						// Clamp and Write RGBA (4 bytes)
						output[offset++] = (byte) (r < 0 ? 0 : (r > 255 ? 255 : r)); // R
						output[offset++] = (byte) (g < 0 ? 0 : (g > 255 ? 255 : g)); // G
						output[offset++] = (byte) (b < 0 ? 0 : (b > 255 ? 255 : b)); // B
						output[offset++] = (byte) 255; // Alpha (Opaque)
					}
				}
			}

			if (rotation != 0) {
				RotationResult result;
				if (isGrayscale) {
					result = rotateGray(output, width, height, rotation);
				} else {
					result = rotateRGBA(output, width, height, rotation);
				}

				output = result.buffer;
				width = result.width;
				height = result.height;
			}

			if (running) {
				emitFrame(output, width, height, rotation, isGrayscale);
			}

			image.close();
		} catch (Exception e) {
			Log.e(LOG_TAG, "onImageAvailable(): Error while processing frame", e);
		}
	}

	@Override
	public void onMainRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
		super.onMainRequestPermissionsResult(requestCode, permissions, grantResults);

		if (requestCode == CAMERA_PERMISSION_REQUEST) {
			if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
				Log.d(LOG_TAG, "Camera Permission Granted by user");
				emitSignal(CAMERA_PERMISSION_GRANTED_SIGNAL.getName());
			} else {
				Log.d(LOG_TAG, "Camera Permission Denied by user");
				emitSignal(CAMERA_PERMISSION_DENIED_SIGNAL.getName());
			}
		}
	}

	@Override
	public void onGodotSetupCompleted() {
		super.onGodotSetupCompleted();

		// TODO: Godot is ready
	}

	@Override
	public void onMainDestroy() {
		// TODO: Plugin cleanup
	}

	private static class RotationResult {
		byte[] buffer;
		int width;
		int height;

		RotationResult(byte[] buffer, int width, int height) {
			this.buffer = buffer;
			this.width = width;
			this.height = height;
		}
	}

	private static RotationResult rotateRGBA(
		byte[] src,
		int width,
		int height,
		int rotation
	) {
		rotation = ((rotation % 360) + 360) % 360;

		if (rotation == 0) {
			return new RotationResult(src, width, height);
		}

		int newWidth = (rotation == 90 || rotation == 270) ? height : width;
		int newHeight = (rotation == 90 || rotation == 270) ? width : height;

		byte[] dst = new byte[src.length];

		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				int srcIndex = (y * width + x) * 4;

				int dx = 0, dy = 0;

				switch (rotation) {
					case 90:
						dx = height - 1 - y;
						dy = x;
						break;
					case 180:
						dx = width - 1 - x;
						dy = height - 1 - y;
						break;
					case 270:
						dx = y;
						dy = width - 1 - x;
						break;
				}

				int dstIndex = (dy * newWidth + dx) * 4;

				dst[dstIndex] = src[srcIndex];
				dst[dstIndex + 1] = src[srcIndex + 1];
				dst[dstIndex + 2] = src[srcIndex + 2];
				dst[dstIndex + 3] = src[srcIndex + 3];
			}
		}

		return new RotationResult(dst, newWidth, newHeight);
	}

	private static RotationResult rotateGray(
		byte[] src,
		int width,
		int height,
		int rotation
	) {
		rotation = ((rotation % 360) + 360) % 360;

		if (rotation == 0) {
			return new RotationResult(src, width, height);
		}

		int newWidth = (rotation == 90 || rotation == 270) ? height : width;
		int newHeight = (rotation == 90 || rotation == 270) ? width : height;

		byte[] dst = new byte[src.length];

		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				int srcIndex = y * width + x;

				int dx = 0, dy = 0;

				switch (rotation) {
					case 90:
						dx = height - 1 - y;
						dy = x;
						break;
					case 180:
						dx = width - 1 - x;
						dy = height - 1 - y;
						break;
					case 270:
						dx = y;
						dy = width - 1 - x;
						break;
				}

				int dstIndex = dy * newWidth + dx;

				dst[dstIndex] = src[srcIndex];
			}
		}

		return new RotationResult(dst, newWidth, newHeight);
	}
}
