using Uno;
using Uno.Graphics;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Fuse.Triggers;
using Fuse.Resources;

using Fuse.Platform;
using Uno.Compiler.ExportTargetInterop;
using Uno.Compiler.ExportTargetInterop.Android;

namespace Fuse.PushNotifications
{
	[ForeignInclude(Language.Java,
					"android.app.Activity",
					"android.os.AsyncTask",
					"android.app.Notification",
					"android.content.Context",
					"android.content.Intent",
					"android.media.RingtoneManager",
					"android.net.Uri",
					"android.os.Bundle",
					"android.graphics.Color",
					"android.util.Log",
					"androidx.core.app.NotificationCompat",
					"com.fuse.PushNotifications.PushNotificationReceiver",
					"com.fuse.PushNotifications.BigPictureStyleHttp",
					"java.util.ArrayList",
					"java.util.HashMap",
					"org.json.JSONException",
					"org.json.JSONObject",
					"com.google.android.gms.common.ConnectionResult",
					"com.google.android.gms.common.GoogleApiAvailability"
					)]
	[Require("Gradle.Dependency.Implementation", "com.google.firebase:firebase-messaging:20.0.1")]
	extern(Android)
	internal class AndroidImpl
	{
		public static event EventHandler<string> RegistrationSucceeded;
		public static event EventHandler<string> RegistrationFailed;
		public static event EventHandler<KeyValuePair<string,bool>> ReceivedNotification;

		static bool _init = false;
		static List<string> _cachedMessages = new List<string>();
		static int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;

		internal static void Init()
		{
			if (!_init)
			{
				JInit();
				_init = true;
				Lifecycle.EnteringInteractive += OnEnteringInteractive;
				Lifecycle.ExitedInteractive += OnExitedInteractive;
			}
		}

		[Foreign(Language.Java)]
		static void JInit()
		@{
			// Set up vars and hook into fuse intent listeners
			com.fuse.Activity.subscribeToIntents(
				new com.fuse.Activity.IntentListener() {
					public void onIntent (Intent newIntent) {
						@{OnRecieve(Java.Object,bool):Call(newIntent.getExtras(), false)};
					}
				},
				PushNotificationReceiver.ACTION);

			// Set up FCM
			final Activity activity = com.fuse.Activity.getRootActivity();
			activity.runOnUiThread(new Runnable() {
					@Override
						public void run() {
						// Check device for Play Services APK. If check succeeds, proceed with FCM registration.
						if (@{CheckPlayServices():Call()}) {

							String _regID = com.google.firebase.iid.FirebaseInstanceId.getInstance().getToken();
							if (_regID != null) {
								@{getRegistrationIdSuccess(string):Call(_regID)};
							}
						} else {
							@{getRegistrationIdError(string):Call("Google Play Services need to be updated")};
						}
					}
				});
		@}


		// Check the device to make sure it has the Google Play Services APK. If
		// it doesn't, display a dialog that allows users to download the APK from
		// the Google Play Store or enable it in the device's system settings.
		[Foreign(Language.Java)]
		static bool CheckPlayServices()
		@{

			Activity activity = com.fuse.Activity.getRootActivity();
			GoogleApiAvailability apiAvailability = GoogleApiAvailability.getInstance();
			int resultCode = apiAvailability.isGooglePlayServicesAvailable(activity);
			if (resultCode != ConnectionResult.SUCCESS) {
				if (apiAvailability.isUserResolvableError(resultCode)) {
					apiAvailability.getErrorDialog(activity, resultCode, @{PLAY_SERVICES_RESOLUTION_REQUEST})
						.show();
				} else {
					return false;
				}
				return false;
			}
			return true;
		@}

		[Foreign(Language.Java), ForeignFixedName]
		static void RegistrationIDUpdated(string regid)
		@{
			@{getRegistrationIdSuccess(string):Call(regid)};
		@}

		static void getRegistrationIdSuccess(string regid)
		{
			var x = RegistrationSucceeded;
			if (x!=null)
				x(null, regid);
		}

		static void getRegistrationIdError(string message)
		{
			var x = RegistrationFailed;
			if (x!=null)
				x(null, message);
		}

		//----------------------------------------------------------------------

		[Foreign(Language.Java)]
		static void cacheBundle(Java.Object _bundle)
		@{
			Bundle bundle = (Bundle)_bundle;
			PushNotificationReceiver._cachedBundles.add(bundle);
		@}

		static void OnEnteringInteractive(ApplicationState newState)
		{
			NoteInteractivity(true);
			var x = ReceivedNotification;
			if (x!=null)
			{
				foreach (var message in _cachedMessages)
					x(null, new KeyValuePair<string,bool>(message, true));
			}
			_cachedMessages.Clear();
		}


		static void OnExitedInteractive(ApplicationState newState)
		{
			NoteInteractivity(false);
		}

		//----------------------------------------------------------------------

		static void OnRecieve(Java.Object bundle, bool fromNotificationBar)
		{
			var message = BundleToJSONStr(bundle);
			if (Lifecycle.State == ApplicationState.Interactive)
			{
				var x = ReceivedNotification;
				if (x!=null)
					x(null, new KeyValuePair<string,bool>(message, fromNotificationBar));
			}
			else
			{
				_cachedMessages.Add(message);
			}
		}


		[Foreign(Language.Java)]
		static Java.Object BundleToJSONObject(Java.Object _bundle)
		@{
			Bundle bundle = (Bundle)_bundle;

			JSONObject resultJson = new JSONObject();

			if (bundle == null) {
				return resultJson;
			}

			try {
				for (String bundleKey : bundle.keySet()) {

					Object bundleValue = bundle.get(bundleKey);

					if (bundleValue instanceof Bundle) {
						resultJson.put(bundleKey, @{BundleToJSONObject(Java.Object):Call((Bundle) bundleValue)} );
					} else if (bundleValue instanceof String) {
						resultJson.put(bundleKey, "" + bundleValue);
					} else if (bundleValue instanceof Boolean) {
						resultJson.put(bundleKey, (boolean) bundleValue);
					} else if (bundleValue instanceof Integer) {
						resultJson.put(bundleKey, (int) bundleValue);
					} else if (bundleValue instanceof Double) {
						resultJson.put(bundleKey, (double) bundleValue);
					} else if (bundleValue instanceof Long) {
						resultJson.put(bundleKey, (long) bundleValue);
					}
				}
			} catch (JSONException je) {
				Log.d("PushNotifications.Impl.BundleToJSONObject", "BAD JSON");
			}

			return resultJson;
		@}

		[Foreign(Language.Java)]
		static string BundleToJSONStr(Java.Object _bundle)
		@{
			Bundle bundle = (Bundle)_bundle;

			if (bundle == null) {
				return "";
			}

			JSONObject resultJson = new JSONObject();

			try {
				for (String bundleKey : bundle.keySet()) {

					Object bundleValue = bundle.get(bundleKey);

					if (bundleValue instanceof Bundle) {
						resultJson.put(bundleKey, @{BundleToJSONObject(Java.Object):Call((Bundle) bundleValue)} );
					} else if (bundleValue instanceof String) {
						resultJson.put(bundleKey, "" + bundleValue);
					} else if (bundleValue instanceof Boolean) {
						resultJson.put(bundleKey, (boolean) bundleValue);
					} else if (bundleValue instanceof Integer) {
						resultJson.put(bundleKey, (int) bundleValue);
					} else if (bundleValue instanceof Double) {
						resultJson.put(bundleKey, (double) bundleValue);
					} else if (bundleValue instanceof Long) {
						resultJson.put(bundleKey, (long) bundleValue);
					}
				}
			} catch (JSONException je) {
				Log.d("PushNotifications.Impl.BundleToJSONStr", "BAD JSON");

				//fallback to older implementation

				HashMap<String,Object> result = new HashMap<String, Object>();
				for (String key : bundle.keySet()) {
					Object item = bundle.get(key);
					/* Only map simple serializable primitive items */
					if (item!=null && (
							item instanceof String ||
							item instanceof Long ||
							item instanceof Integer ||
							item instanceof Boolean ||
							item instanceof Double
						)) {
						result.put(key, item);
					}
				}
				resultJson = new JSONObject(result);
			}

			String finalPayload = resultJson.toString();
			return finalPayload;
		@}

		//----------------------------------------------------------------------

		[Foreign(Language.Java)]
		static void NoteInteractivity(bool isItInteractive)
		@{
			PushNotificationReceiver.InForeground = isItInteractive;
			ArrayList<Bundle> bundles = PushNotificationReceiver._cachedBundles;
			if (isItInteractive && bundles!=null && bundles.size()>0) {
				for (Bundle bundle : bundles)
					@{OnRecieve(Java.Object,bool):Call(bundle, true)};
				bundles.clear();
			}
		@}


		[Foreign(Language.Java), ForeignFixedName]
		static void OnNotificationRecieved(Java.Object listener, string from, Java.Object _bundle)
		@{
			final Bundle bundle = (Bundle)_bundle;

			if (!PushNotificationReceiver.InForeground) {
				
				String notification = @{BundleToJSONStr(Java.Object):Call((Bundle) bundle.get("notification"))};
				String aps = @{BundleToJSONStr(Java.Object):Call((Bundle) bundle.get("aps"))};
				
				if (notification != null) {
					// using the google style 'notification' subtree
					@{NotificationFromJson(Java.Object,string,Java.Object):Call(listener, notification, bundle)};
				} else if (aps != null) {
					// using the apple style 'aps' subtree
					@{NotificationFromJson(Java.Object,string,Java.Object):Call(listener, aps, bundle)};
				} else {
					@{cacheBundle(Java.Object):Call(bundle)};
				}
			} else {
				@{OnRecieve(Java.Object,bool):Call(bundle, false)};
			}
		@}

		[Foreign(Language.Java)]
		static void NotificationFromJson(Java.Object listener, string _jsonStr, Java.Object _bundle)
		@{
			JSONObject json = null;
			try { json = (_jsonStr==null) ? null : new JSONObject(_jsonStr); } catch (JSONException e) {}

			Bundle bundle = (Bundle)_bundle;

			Object alertObj = json.opt("alert");

			if (alertObj == null) {
				@{cacheBundle(Java.Object):Call(bundle)};
				return;
			}

			Class cls = alertObj.getClass();

			if (cls == String.class)
			{
				String title = (String)alertObj;
				@{SpitOutNotification(Java.Object,
					string,string,
					string,string,string,string,
					string,string,
					string,string,string,
					string,string,string,
					string,string,string,
					string,string,string,
					string,string,
					string,string,
					Java.Object):Call(listener,
						title,
						"",
						json.optString("bigTitle"),
						json.optString("bigBody"),
						json.optString("notificationStyle"),
						json.optString("featuredImage"),
						json.optString("sound"),
						json.optString("color"),
						json.optString("notificationPriority"),
						json.optString("notificationCategory"),
						json.optString("notificationLockscreenVisibility"),
						json.optString("notificationChannelId"),
						json.optString("notificationChannelName"),
						json.optString("notificationChannelDescription"),
						json.optString("notificationChannelImportance"),
						json.optString("notificationChannelLockscreenVisibility"),
						json.optString("notificationChannelLightColor"),
						json.optString("notificationChannelIsVibrationOn"),
						json.optString("notificationChannelIsSoundOn"),
						json.optString("notificationChannelIsShowBadgeOn"),
						json.optString("notificationChannelGroupId"),
						json.optString("notificationChannelGroupName"),
						json.optString("notificationBadgeNumber"),
						json.optString("notificationBadgeIconType"),
						bundle)};
			}
			else
			{
				JSONObject alert = (JSONObject)alertObj;
				if (alertObj!=null)
				{
					@{SpitOutNotification(Java.Object,
						string,string,
						string,string,string,string,
						string,string,
						string,string,string,
						string,string,string,
						string,string,string,
						string,string,string,
						string,string,
						string,string,
						Java.Object):Call(listener,
						alert.optString("title"),
						alert.optString("body"),
						alert.optString("bigTitle"),
						alert.optString("bigBody"),
						alert.optString("notificationStyle"),
						alert.optString("featuredImage"),
						alert.optString("sound"),
						alert.optString("color"),
						alert.optString("notificationPriority"),
						alert.optString("notificationCategory"),
						alert.optString("notificationLockscreenVisibility"),
						alert.optString("notificationChannelId"),
						alert.optString("notificationChannelName"),
						alert.optString("notificationChannelDescription"),
						alert.optString("notificationChannelImportance"),
						alert.optString("notificationChannelLockscreenVisibility"),
						alert.optString("notificationChannelLightColor"),
						alert.optString("notificationChannelIsVibrationOn"),
						alert.optString("notificationChannelIsSoundOn"),
						alert.optString("notificationChannelIsShowBadgeOn"),
						alert.optString("notificationChannelGroupId"),
						alert.optString("notificationChannelGroupName"),
						alert.optString("notificationBadgeNumber"),
						alert.optString("notificationBadgeIconType"),
						bundle)};
				}
			}
		@}

		[Foreign(Language.Java)]
		static void SpitOutNotification(Java.Object _listener, 
			string title, string body, 
			string bigTitle, string bigBody, string notificationStyle, string featuredImage, 
			string sound, string color, 
			string notificationPriority, string notificationCategory, string notificationLockscreenVisibility,
			string notificationChannelId, string notificationChannelName, string notificationChannelDescription, 
			string notificationChannelImportance, string notificationChannelLockscreenVisibility, string notificationChannelLightColor,
			string notificationChannelIsVibrationOn, string notificationChannelIsSoundOn, string notificationChannelIsShowBadgeOn,
			string notificationChannelGroupId, string notificationChannelGroupName, 
			string notificationBadgeNumber, string notificationBadgeIconType,
			Java.Object _payload)
		@{
			int id = PushNotificationReceiver.nextID();
			Context context = (Context)_listener;
			Bundle payload = (Bundle)_payload;
			Intent intent = new Intent(context, @(Activity.Package).@(Activity.Name).class);
			intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
			intent.setAction(PushNotificationReceiver.ACTION);
			intent.replaceExtras(payload);
			android.app.PendingIntent pendingIntent = android.app.PendingIntent.getActivity(context, id, intent, android.app.PendingIntent.FLAG_UPDATE_CURRENT);
			android.app.NotificationManager notificationManager = (android.app.NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);

			/// Setup Default notification channel properties to fallback on
			/// NB: Once a channel is created, you can't change the importance, etc.
			// Notification Channel id - unique identifier that you could use to get the channel properties
			String channelId = "@(Project.Android.Notification.DefaultChannelId)";
			channelId = (channelId != "") ? channelId : "default_channel";
			/* Notification Channel name - appears in the App notification settings, under "Categories" or a group name 
				- https://developer.android.com/training/notify-user/channels */
			String channelName = "@(Project.Android.Notification.DefaultChannelName)";
			channelName = (channelName != "") ? channelName : "App";
			// Notification Channel description - appears under channel name in the App settings
			String channelDescription = "@(Project.Android.Notification.DefaultChannelDescription)";
			channelDescription = (channelDescription != "") ? channelDescription : "";
			String channelImportanceIn = "@(Project.Android.Notification.DefaultChannelImportance)";
			channelImportanceIn = (channelImportanceIn != "") ? channelImportanceIn : "";

			/* Notification Channel overrides from notification payload
				Minimum: each notification must define a Channel Id and Channel Name, else will be part of default notification channel
			*/
			if (
				(notificationChannelId!=null && !notificationChannelId.isEmpty()) &&
				(notificationChannelName!=null && !notificationChannelName.isEmpty())
			) { 
				channelId = notificationChannelId;
				channelName = notificationChannelName;
			}
			if (notificationChannelDescription!=null && !notificationChannelDescription.isEmpty()) { channelDescription = notificationChannelDescription; }
			if (notificationChannelImportance!=null && !notificationChannelImportance.isEmpty()) { channelImportanceIn = notificationChannelImportance; }

			// Notification Channel - (Categories) since Oreo, is mandatory. Allows push to work on devices above API 25.
			if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {

				// Notification Channel Importance - https://developer.android.com/training/notify-user/channels#importance
				int channelImportance = android.app.NotificationManager.IMPORTANCE_DEFAULT;
				switch(channelImportanceIn.toLowerCase()) {
					case "urgent": channelImportance = android.app.NotificationManager.IMPORTANCE_HIGH; break;
					case "high": channelImportance = android.app.NotificationManager.IMPORTANCE_DEFAULT; break;
					case "medium": channelImportance = android.app.NotificationManager.IMPORTANCE_LOW; break;
					case "low": channelImportance = android.app.NotificationManager.IMPORTANCE_MIN; break;
					case "none": channelImportance = android.app.NotificationManager.IMPORTANCE_NONE; break;
				}

				android.app.NotificationChannel channel = new android.app.NotificationChannel(
					channelId,
					channelName,
					channelImportance);
				channel.setDescription(channelDescription);

				/* Notification Channel Light Color - https://developer.android.com/training/notify-user/channels#CreateChannel
					NB: A device supports this feature if you can find the option here for all apps:
					Settings > Apps & notifications > Notifications > Blink light
				*/
				#if @(Project.Android.Notification.DefaultChannelLightColor:IsSet)
					channel.enableLights(true);
					try {
						channel.setLightColor(Color.parseColor("@(Project.Android.Notification.DefaultChannelLightColor)"));
					} catch (Exception e) { //try with #
						try {
							channel.setLightColor(Color.parseColor("#@(Project.Android.Notification.DefaultChannelLightColor)"));
						} catch (Exception e2) {}
					}
				#endif
				// Allow for notificationChannelLightColor to be overridden from notification payload
				if (notificationChannelLightColor!=null && !notificationChannelLightColor.isEmpty()) {
					channel.enableLights(true);
					try {
						channel.setLightColor(Color.parseColor(notificationChannelLightColor));
					} catch (Exception e) {
						try {
							channel.setLightColor(Color.parseColor("#" + notificationChannelLightColor));
						} catch (Exception e2) {}
					}
				}

				/* Notification Channel Vibration On
					default vibration pattern: {0, 250, 250, 250}
					- https://android.googlesource.com/platform/frameworks/base/+/master/services/core/java/com/android/server/notification/NotificationManagerService.java
				*/
				long[] DEFAULT_VIBRATE_PATTERN = {0, 250, 250, 250};
				#if @(Project.Android.Notification.NotificationChannelIsVibrationOn:IsSet)
					if (Boolean.parseBoolean("@(Project.Android.Notification.NotificationChannelIsVibrationOn)")) {
						channel.enableVibration(true);
						channel.setVibrationPattern(DEFAULT_VIBRATE_PATTERN);
					}
				#endif
				// Allow for notificationChannelIsVibrationOn to be overridden from notification payload
				if (notificationChannelIsVibrationOn!=null && !notificationChannelIsVibrationOn.isEmpty()
					&& Boolean.parseBoolean(notificationChannelIsVibrationOn)) {
					channel.enableVibration(true);
					channel.setVibrationPattern(DEFAULT_VIBRATE_PATTERN);
				}

				// Notification Channel Sound On 
				#if @(Project.Android.Notification.NotificationChannelIsSoundOn:IsSet)
					if (Boolean.parseBoolean("@(Project.Android.Notification.NotificationChannelIsSoundOn)")) {
						Uri defaultSoundUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION);
						android.media.AudioAttributes att = new android.media.AudioAttributes.Builder()
							.setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
							.setContentType(android.media.AudioAttributes.CONTENT_TYPE_UNKNOWN)
							.build();
						if (notificationCategory.toLowerCase() == "alarm" || notificationCategory.toLowerCase() == "reminder") {
							defaultSoundUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM);
							att = new android.media.AudioAttributes.Builder()
								.setUsage(android.media.AudioAttributes.USAGE_ALARM)
								.setContentType(android.media.AudioAttributes.CONTENT_TYPE_UNKNOWN)
								.build();
						}
						channel.setSound(defaultSoundUri, att);
					}
				#endif
				// Allow for notificationChannelIsSoundOn to be overridden from notification payload
				if (notificationChannelIsSoundOn!=null && !notificationChannelIsSoundOn.isEmpty() 
					&& Boolean.parseBoolean(notificationChannelIsSoundOn)) {
					Uri defaultSoundUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION);
					android.media.AudioAttributes att = new android.media.AudioAttributes.Builder()
						.setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
						.setContentType(android.media.AudioAttributes.CONTENT_TYPE_UNKNOWN)
						.build();
					if (notificationCategory.toLowerCase() == "alarm" || notificationCategory.toLowerCase() == "reminder") {
						defaultSoundUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM);
						att = new android.media.AudioAttributes.Builder()
							.setUsage(android.media.AudioAttributes.USAGE_ALARM)
							.setContentType(android.media.AudioAttributes.CONTENT_TYPE_UNKNOWN)
							.build();
					}
					channel.setSound(defaultSoundUri, att);
				}
				
				// Notification Channel Lock Screen Visibility - same as notification lock screen visibility which is deprecated from Oreo+ (see below)
				String notificationChannelLockscreenVisibilityIn = "";
				#if @(Project.Android.Notification.NotificationChannelLockscreenVisibility:IsSet)
					notificationChannelLockscreenVisibilityIn = "@(Project.Android.Notification.NotificationChannelLockscreenVisibility)";
				#endif
				if (notificationChannelLockscreenVisibility!=null && !notificationChannelLockscreenVisibility.isEmpty())
					notificationChannelLockscreenVisibilityIn = notificationChannelLockscreenVisibility;
				switch(notificationChannelLockscreenVisibilityIn.toLowerCase()) {
					case "public": channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC); break;
					case "secret": channel.setLockscreenVisibility(Notification.VISIBILITY_SECRET); break;
					case "private": channel.setLockscreenVisibility(Notification.VISIBILITY_PRIVATE); break;
				}

				/* Notification Channel Show Badge
					NB: A device supports this feature if you can find the option here for all apps:
					Settings > Apps & notifications > Notifications > Allow notification dots
				*/
				#if @(Project.Android.Notification.NotificationChannelIsShowBadgeOn:IsSet)
					channel.setShowBadge(Boolean.parseBoolean("@(Project.Android.Notification.NotificationChannelIsShowBadgeOn)"));
				#endif
				// Allow for notificationChannelIsShowBadgeOn to be overridden from notification payload
				if (notificationChannelIsShowBadgeOn!=null && !notificationChannelIsShowBadgeOn.isEmpty()) {
					channel.setShowBadge(Boolean.parseBoolean(notificationChannelIsShowBadgeOn));
				}

				///Set up default notification channel group
				// Notification Channel Group id - unique identifier that you could use to set/get the channel group
				String channelGroupId = "@(Project.Android.Notification.DefaultChannelGroupId)";
				channelGroupId = (channelGroupId != "") ? channelGroupId : "default_group";
				/* Notification Channel Group name - appears in the App notification settings, replaces "Categories"
				e.g. Personal e.g. Business e.g. Social
						- https://developer.android.com/training/notify-user/channels#CreateChannelGroup */
				String channelGroupName = "@(Project.Android.Notification.DefaultChannelGroupName)";
				channelGroupName = (channelGroupName != "") ? channelGroupName : "Categories";
				// Notification Channel Group overrides from notification payload
				if (
					(notificationChannelGroupId!=null && !notificationChannelGroupId.isEmpty()) &&
					(notificationChannelGroupName!=null && !notificationChannelGroupName.isEmpty())
				) { 
					channelGroupId = notificationChannelGroupId;
					channelGroupName = notificationChannelGroupName;
				}
				notificationManager.createNotificationChannelGroup(new android.app.NotificationChannelGroup(channelGroupId, channelGroupName));

				channel.setGroup(channelGroupId);
				notificationManager.createNotificationChannel(channel);
			}

			NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(context, channelId)
				.setSmallIcon(@(Activity.Package).R.mipmap.notif) // required
				.setContentText(body) // required
				.setAutoCancel(true)
				.setContentIntent(pendingIntent);

			// For API < Oreo API 26
			if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) { 
				//Notification Sound 
				if (sound=="default")
				{
					if (android.os.Build.VERSION.SDK_INT >= 21) { //Lollipop
						//see below by notification
					} else { //less than Lollipop
						Uri defaultSoundUri= RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
						notificationBuilder.setSound(defaultSoundUri, android.media.AudioManager.STREAM_NOTIFICATION);
					}
				}
			}

			// Notification Badge Number (Android 8, Oreo, API 26)
			// - https://developer.android.com/training/notify-user/badges
			if (notificationBadgeNumber!=null && !notificationBadgeNumber.isEmpty()) {
				notificationBuilder.setNumber(Integer.parseInt(notificationBadgeNumber));
			}

			// Notification Badge Icon Type
			// - https://developer.android.com/training/notify-user/badges
			switch(notificationBadgeIconType.toLowerCase()) {
				case "none": notificationBuilder.setBadgeIconType(NotificationCompat.BADGE_ICON_NONE); break;
				case "small": notificationBuilder.setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL); break;
				case "large": notificationBuilder.setBadgeIconType(NotificationCompat.BADGE_ICON_LARGE); break;
			}

			/* Notification Lock Screen Visibility - https://developer.android.com/training/notify-user/build-notification#lockscreenNotification
				public: shows the notification's full content.
				secret: doesn't show any part of this notification on the lock screen.
				private: shows basic information, such as the notification's icon and the content title, but hides the notification's full content.
			*/
			String notificationLockscreenVisibilityIn = "";
			#if @(Project.Android.Notification.NotificationLockscreenVisibility:IsSet)
				notificationLockscreenVisibilityIn = "@(Project.Android.Notification.NotificationLockscreenVisibility)";
			#endif
			if (notificationLockscreenVisibility!=null && !notificationLockscreenVisibility.isEmpty())
				notificationLockscreenVisibilityIn = notificationLockscreenVisibility;
			switch(notificationLockscreenVisibilityIn.toLowerCase()) {
				case "public": notificationBuilder.setVisibility(NotificationCompat.VISIBILITY_PUBLIC); break;
				case "secret": notificationBuilder.setVisibility(NotificationCompat.VISIBILITY_SECRET); break;
				case "private": notificationBuilder.setVisibility(NotificationCompat.VISIBILITY_PRIVATE); break;
			}
			
			/* Notification Category - https://developer.android.com/training/notify-user/build-notification#system-category
				Android uses a some pre-defined system-wide categories to determine whether to disturb the user with 
				a given notification when the user has enabled Do Not Disturb mode.
			*/
			switch(notificationCategory.toLowerCase()) {
				// Important in Do Not Disturb mode - https://developer.android.com/guide/topics/ui/notifiers/notifications#dnd-mode
				case "alarm": notificationBuilder.setCategory(NotificationCompat.CATEGORY_ALARM); break;
				case "reminder": notificationBuilder.setCategory(NotificationCompat.CATEGORY_REMINDER); break;
				case "event": notificationBuilder.setCategory(NotificationCompat.CATEGORY_EVENT); break;
				case "call": notificationBuilder.setCategory(NotificationCompat.CATEGORY_CALL); break;
				case "message": notificationBuilder.setCategory(NotificationCompat.CATEGORY_MESSAGE); break;
				// Other categories (Updated Sep 2018) - https://developer.android.com/reference/android/support/v4/app/NotificationCompat
				case "email": notificationBuilder.setCategory(NotificationCompat.CATEGORY_EMAIL); break;
				case "promo": notificationBuilder.setCategory(NotificationCompat.CATEGORY_PROMO); break;
				case "recommendation": notificationBuilder.setCategory(NotificationCompat.CATEGORY_RECOMMENDATION); break;
				case "social": notificationBuilder.setCategory(NotificationCompat.CATEGORY_SOCIAL); break;
				// System related categories
				case "error": notificationBuilder.setCategory(NotificationCompat.CATEGORY_ERROR); break;
				case "progress": notificationBuilder.setCategory(NotificationCompat.CATEGORY_PROGRESS); break;
				case "service": notificationBuilder.setCategory(NotificationCompat.CATEGORY_SERVICE); break;
				case "status": notificationBuilder.setCategory(NotificationCompat.CATEGORY_STATUS); break;
				case "system": notificationBuilder.setCategory(NotificationCompat.CATEGORY_SYSTEM); break;
				case "transport": notificationBuilder.setCategory(NotificationCompat.CATEGORY_TRANSPORT); break;
			}

			// Notification Priority - The priority determines how intrusive the notification should be on Android 7.1 (Nougat - API 25) and lower
			switch(notificationPriority.toLowerCase()) {
				case "high": notificationBuilder.setPriority(NotificationCompat.PRIORITY_HIGH); break;
				case "low": notificationBuilder.setPriority(NotificationCompat.PRIORITY_LOW); break;
				case "max": notificationBuilder.setPriority(NotificationCompat.PRIORITY_MAX); break;
				case "min": notificationBuilder.setPriority(NotificationCompat.PRIORITY_MIN); break;
				default: notificationBuilder.setPriority(NotificationCompat.PRIORITY_DEFAULT); break;
			}

			/* 
				Notification Title - From Nougat (API 24), the app name is included in notification,
				so this allows you to hide your title when using it for your app name
				Example value: 24 
			*/
			if (title!=null && !title.isEmpty()) {
				String noTitleStyleMinAPIVersion = "@(Project.Android.Notification.NoTitleStyleMinAPIVersion)";
				if (noTitleStyleMinAPIVersion != "" && (android.os.Build.VERSION.SDK_INT >= Integer.parseInt(noTitleStyleMinAPIVersion)) ) {
					// Don't set title - Oreo+ will remove it from the UI
				} else {
					notificationBuilder.setContentTitle(title);
				}
			}

			/*
				Notification Color - Add color to your icon and from Oreo+ it adds the color to your app name as well
				 - https://developer.android.com/guide/topics/ui/notifiers/notifications
				parseColor() format #RRGGBB or #AARRGGBB 
				 - https://developer.android.com/reference/android/graphics/Color#parseColor(java.lang.String)
				Example value: #8811ff
			*/
			#if @(Project.Android.NotificationIcon.Color:IsSet)
				try {
					notificationBuilder.setColor(Color.parseColor("@(Project.Android.NotificationIcon.Color)"));
				} catch (Exception e) { //try with #
					try {
						notificationBuilder.setColor(Color.parseColor("#@(Project.Android.NotificationIcon.Color)"));
					} catch (Exception e2) {}
				}
			#endif
			// Allow for color to be overridden from notification payload
			if (color!=null && !color.isEmpty()) {
				try {
					notificationBuilder.setColor(Color.parseColor(color));
				} catch (Exception e) { //try with #
					try {
						notificationBuilder.setColor(Color.parseColor("#" + color));
					} catch (Exception e2) {}
				}
			}


			if (notificationStyle != null && !notificationStyle.isEmpty())
			{
				String BIGTEXTSTYLE = "bigtextstyle";
				String BIGPICTURESTYLE = "bigpicturestyle";
				if (notificationStyle == BIGTEXTSTYLE || notificationStyle.equals(BIGTEXTSTYLE))
				{
					notificationBuilder.setStyle(new NotificationCompat.BigTextStyle()
						.bigText(bigBody)
						.setBigContentTitle(bigTitle));

				}
				else if (notificationStyle == BIGPICTURESTYLE || notificationStyle.equals(BIGPICTURESTYLE))
				{
					NotificationCompat.BigPictureStyle style = new NotificationCompat.BigPictureStyle();

					if (bigTitle!=null && !bigTitle.isEmpty())
						style.setBigContentTitle(bigTitle);
					if (bigBody!=null && !bigBody.isEmpty())
						style.setSummaryText(bigBody);

					if (featuredImage.startsWith("http://") || featuredImage.startsWith("https://"))
					{
						BigPictureStyleHttp bps = new BigPictureStyleHttp(notificationManager, id, notificationBuilder, style, sound);
						bps.execute(featuredImage);
						return;
					}
					else
					{
						int iconResourceID = com.fuse.R.get(featuredImage);

						if (iconResourceID!=-1)
						{
							style.bigPicture(android.graphics.BitmapFactory.decodeResource(context.getResources(), iconResourceID));
						}
						else
						{
							String packageName = "@(Project.Name)";
							java.io.InputStream afs = com.fuse.PushNotifications.BundleFiles.OpenBundledFile(context, packageName, featuredImage);

							if (afs != null)
							{
								android.graphics.Bitmap bitmap = android.graphics.BitmapFactory.decodeStream(afs);
								try
								{
									afs.close();
								}
								catch (java.io.IOException e)
								{
									debug_log("Could close the notification image '" + featuredImage);
									e.printStackTrace();
									return;
								}
								style.bigPicture(bitmap);
							}
							else
							{
								debug_log("Could not the load image '" + featuredImage + "' as either a bundled file or android resource");
							}
						}
						notificationBuilder.setStyle(style);
					}
				}
			}

			Notification n = notificationBuilder.build();
			if (sound!="" && android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) { //< Oreo API 26
				if(android.os.Build.VERSION.SDK_INT >= 21) { //Lollipop
					Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
					n.sound = defaultSoundUri;
					n.category = Notification.CATEGORY_ALARM;
					
					android.media.AudioAttributes.Builder attrs = new android.media.AudioAttributes.Builder();
					attrs.setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION);
					attrs.setUsage(android.media.AudioAttributes.USAGE_ALARM);
					n.audioAttributes = attrs.build();
				}
				n.defaults |= Notification.DEFAULT_SOUND;
			}
			n.defaults |= Notification.DEFAULT_LIGHTS;
			n.defaults |= Notification.DEFAULT_VIBRATE;
			notificationManager.notify(id, n);
		@}
	}
}
