package com.fuse.PushNotifications;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import java.util.ArrayList;
import com.fuse.PushNotifications.PushNotificationService;

public class PushNotificationReceiver extends BroadcastReceiver {
	public static ArrayList<Bundle> _cachedBundles = new ArrayList<Bundle>();
	public static boolean InForeground = false;
	public static String ACTION = "fuseBackgroundNotify";
	static int _notificationID = -1;
	public static int nextID() { return _notificationID += 1; }
	private static Object lock = new Object();


	@Override
	public void onReceive(Context context, Intent intent) {
		Log.d("Push Notification Receiver", "Notification Received");
	    ComponentName comp = new ComponentName(context.getPackageName(),
	            PushNotificationService.class.getName());
	    intent.setComponent(comp);
	    PushNotificationService.enqueueWork(context, PushNotificationService.class, 1000, intent);
	    setResultCode(Activity.RESULT_OK);
	}

}
