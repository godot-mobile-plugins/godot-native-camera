//
// © 2026-present https://github.com/cengiz-pz
//

#ifndef native_camera_plugin_h
#define native_camera_plugin_h

#import <Foundation/Foundation.h>

#include "core/object/object.h"
#include "core/object/class_db.h"


@class NativeCamera;


extern const String CAMERA_PERMISSION_GRANTED_SIGNAL;
extern const String CAMERA_PERMISSION_DENIED_SIGNAL;
extern const String FRAME_AVAILABLE_SIGNAL;


class NativeCameraPlugin : public Object {
	GDCLASS(NativeCameraPlugin, Object);

private:
	static NativeCameraPlugin* instance; // Singleton instance

	static void _bind_methods();

public:
	bool has_camera_permission();
	void request_camera_permission();
	Array get_all_cameras();
	void start(Dictionary requestDict);
	void stop();

	NativeCameraPlugin();
	~NativeCameraPlugin();
};

#endif /* native_camera_plugin_h */
