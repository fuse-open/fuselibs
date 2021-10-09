package com.fuse.mediapicker;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import java.util.Arrays;

final class MediaPickerUtils {
	/** returns true, if permission present in manifest, otherwise false */
	private static boolean isPermissionPresentInManifest(Context context, String permissionName) {
		try {
			PackageManager packageManager = context.getPackageManager();
			PackageInfo packageInfo =
					packageManager.getPackageInfo(context.getPackageName(), PackageManager.GET_PERMISSIONS);

			String[] requestedPermissions = packageInfo.requestedPermissions;
			return Arrays.asList(requestedPermissions).contains(permissionName);
		} catch (PackageManager.NameNotFoundException e) {
			e.printStackTrace();
			return false;
		}
	}

	static boolean needRequestCameraPermission(Context context) {
		boolean greatOrEqualM = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M;
		return greatOrEqualM && isPermissionPresentInManifest(context, Manifest.permission.CAMERA);
	}
}
