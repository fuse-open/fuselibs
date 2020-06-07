package com.fuse.PushNotifications;

import android.os.Bundle;
import java.util.ArrayList;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.Arrays;
import java.util.Iterator;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;
import android.util.Log;

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

			try {
				//reconstruct JSON string from Map and test it
				String jsonStr = "{";
				for (Map.Entry<String, String> entry : message.getData().entrySet()) {
					jsonStr += "\"" + entry.getKey() + "\":";
					if (entry.getValue().charAt(0) == '{') {
						jsonStr += entry.getValue() + ",";
					} else {
						jsonStr += "\"" + entry.getValue() + "\"" + ",";
					}
				}
				jsonStr = jsonStr.replaceAll(",$", "");
				jsonStr += "}";

				JSONObject jsonObj = new JSONObject(jsonStr);

	            jsonStr = jsonObj.toString();

	            bundle = jsonStrToBundle(jsonStr);

			} catch (JSONException je) {
				Log.d("onMessageReceived", "BAD JSON");

				//fallback to older implementation
				for (Map.Entry<String, String> entry : message.getData().entrySet()) {
					bundle.putString(entry.getKey(), entry.getValue());
				}
			}

			com.foreign.Fuse.PushNotifications.AndroidImpl.OnNotificationRecieved(this, message.getFrom(), bundle);
		}
	}

    public static Bundle jsonStrToBundle(String jsonStr) {
        Bundle bundle = new Bundle();

        try {
            JSONObject jsonObject = new JSONObject(jsonStr.trim());
            bundle = handleJSONObject(jsonObject);
        } catch (JSONException notObject) {
            try {
                JSONArray jsonArr = new JSONArray(jsonStr.trim());
                bundle = handleJSONArray(jsonArr);
            } catch (JSONException badJSON) {
                Log.d("jsonStrToBundle", "BAD JSON");
            }
        }

        return bundle;
    }


    public static Bundle handleJSONArray(JSONArray jsonArray) {
        Bundle bundle = new Bundle();

        for (int i = 0; i < jsonArray.length(); i++) {

            try {
                Object jsonArrayValue = jsonArray.get(i);

                if (jsonArrayValue instanceof JSONObject) {
                    bundle.putBundle("" + i, handleJSONObject((JSONObject) jsonArrayValue));
                } else if (jsonArrayValue instanceof JSONArray) {
                    bundle.putBundle("" + i, handleJSONArray((JSONArray) jsonArrayValue));
                } else if (jsonArrayValue instanceof String) {
                    bundle.putString("" + i, "" + jsonArrayValue);
                } else if (jsonArrayValue instanceof Boolean) {
                    bundle.putBoolean("" + i, (boolean) jsonArrayValue);
                } else if (jsonArrayValue instanceof Integer) {
                    bundle.putInt("" + i, (int) jsonArrayValue);
                } else if (jsonArrayValue instanceof Double) {
                    bundle.putDouble("" + i, (double) jsonArrayValue);
                } else if (jsonArrayValue instanceof Long) {
                    bundle.putLong("" + i, (long) jsonArrayValue);
                }
            } catch (JSONException je) {
                Log.d("handleJSONArray", "BAD JSON VALUE IN JSON ARRAY, AT POSITION: " + i);
            }
        }

        return bundle;
    }

    public static Bundle handleJSONObject(JSONObject jsonObject) {
        Bundle bundle = new Bundle();

        Iterator<String> keys = jsonObject.keys();

        while(keys.hasNext()) {
            String keyStr = keys.next();

            try {
                Object keyValue = jsonObject.get(keyStr);

                if (keyValue instanceof JSONObject) {
                    bundle.putBundle(keyStr, handleJSONObject((JSONObject) keyValue));
                } else if (keyValue instanceof JSONArray) {
                    bundle.putBundle(keyStr, handleJSONArray((JSONArray) keyValue));
                } else if (keyValue instanceof String) {
                    bundle.putString(keyStr, "" + keyValue);
                } else if (keyValue instanceof Boolean) {
                    bundle.putBoolean(keyStr, (boolean) keyValue);
                } else if (keyValue instanceof Integer) {
                    bundle.putInt(keyStr, (int) keyValue);
                } else if (keyValue instanceof Double) {
                    bundle.putDouble(keyStr, (double) keyValue);
                } else if (keyValue instanceof Long) {
                    bundle.putLong(keyStr, (long) keyValue);
                }
            } catch (JSONException je) {
                Log.d("handleJSONObject", "BAD JSON VALUE IN JSON OBJECT, AT KEY: " + keyStr);
            }
        }

        return bundle;
    }
}
