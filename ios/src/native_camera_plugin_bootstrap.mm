//
// © 2026-present https://github.com/cengiz-pz
//

#import <Foundation/Foundation.h>

#import "native_camera_plugin_bootstrap.h"
#import "native_camera_plugin.h"
#import "native_camera_logger.h"

#import "core/config/engine.h"


NativeCameraPlugin *native_camera_plugin;


void native_camera_plugin_init() {
	os_log_debug(native_camera_log, "NativeCameraPlugin: Initializing plugin at timestamp: %f", [[NSDate date] timeIntervalSince1970]);

	native_camera_plugin = memnew(NativeCameraPlugin);
	Engine::get_singleton()->add_singleton(Engine::Singleton("NativeCameraPlugin", native_camera_plugin));
	os_log_debug(native_camera_log, "NativeCameraPlugin: Singleton registered");
}


void native_camera_plugin_deinit() {
	os_log_debug(native_camera_log, "NativeCameraPlugin: Deinitializing plugin");
	native_camera_log = NULL; // Prevent accidental reuse

	if (native_camera_plugin) {
		memdelete(native_camera_plugin);
		native_camera_plugin = nullptr;
	}
}
