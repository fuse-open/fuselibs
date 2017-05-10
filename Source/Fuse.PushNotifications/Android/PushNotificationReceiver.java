package com.fuse.PushNotifications;

import android.os.Bundle;
import java.util.ArrayList;
import com.google.android.gms.gcm.GcmListenerService;

public class PushNotificationReceiver extends GcmListenerService {
	public static ArrayList<Bundle> _cachedBundles = new ArrayList<Bundle>();
	public static boolean InForeground = false;
	public static String ACTION = "fuseBackgroundNotify";
	static int _notificationID = -1;
	public static int nextID() { return _notificationID += 1; }
	private static Object lock = new Object();
	
	@Override
	public void onMessageReceived(String from, Bundle bundle)
	{
		synchronized (lock) {
			com.foreign.Fuse.PushNotifications.AndroidImpl.OnNotificationRecieved(this, from, bundle);
		}
	}
}
