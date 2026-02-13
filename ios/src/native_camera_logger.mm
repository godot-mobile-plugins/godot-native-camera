//
// © 2026-present https://github.com/cengiz-pz
//

#import "native_camera_logger.h"

// Define and initialize the shared os_log_t instance
os_log_t native_camera_log;

__attribute__((constructor)) // Automatically runs at program startup
static void initialize_native_camera_log(void) {
	native_camera_log = os_log_create("org.godotengine.plugin.native_camera", "NativeCameraPlugin");
}
