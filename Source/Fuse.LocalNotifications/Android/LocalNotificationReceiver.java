package com.fuse.LocalNotifications;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import org.json.JSONObject;

public class LocalNotificationReceiver extends BroadcastReceiver {
    public static boolean InForeground = false;

    @Override
    public void onReceive(Context context, Intent intent)
    {
        com.foreign.Fuse.LocalNotifications.AndroidImpl.OnNotificationRecieved(context, intent);
    }

	public static String MakePayloadString(String title, String body, String payload)
	{
		JSONObject jsonObj = new JSONObject();
		try
		{
			jsonObj.put("title", (title == null ? "" : title));
			jsonObj.put("body", (body == null ? "" : body));
			jsonObj.put("payload", (payload == null ? "" : payload));
		}
		catch (Exception e)
		{
		}
		return jsonObj.toString();
	}
}
