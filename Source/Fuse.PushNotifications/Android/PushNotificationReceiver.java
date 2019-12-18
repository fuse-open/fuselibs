package com.fuse.PushNotifications;

import android.os.Bundle;
import java.util.ArrayList;
import java.util.Map;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class PushNotificationReceiver extends FirebaseMessagingService {
	public static ArrayList<Bundle> _cachedBundles = new ArrayList<Bundle>();
	public static boolean InForeground = false;
	public static String ACTION = "fuseBackgroundNotify";
	static int _notificationID = -1;
	public static int nextID() { return _notificationID += 1; }
	private static Object lock = new Object();

	public PushNotificationReceiver() { 
		super();
	}
	@Override
	public void onNewToken(String refreshedToken) {
		super.onNewToken(refreshedToken);
		com.foreign.Fuse.PushNotifications.AndroidImpl.RegistrationIDUpdated(refreshedToken);
	}
	@Override
	public void onMessageReceived(RemoteMessage message)
	{
		synchronized (lock) {
			Bundle bundle = new Bundle();
			for (Map.Entry<String, String> entry : message.getData().entrySet()) {
				bundle.putString(entry.getKey(), entry.getValue());
			}
			com.foreign.Fuse.PushNotifications.AndroidImpl.OnNotificationRecieved(this, message.getFrom(), bundle);
		}
	}

}
