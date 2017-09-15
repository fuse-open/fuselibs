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
					"android.content.res.Resources",
					"android.media.RingtoneManager",
					"android.net.Uri",
					"android.os.Bundle",
					"android.support.v4.app.NotificationCompat",
					"com.fuse.PushNotifications.PushNotificationReceiver",
					"com.fuse.PushNotifications.BigPictureStyleHttp",
					"com.google.android.gms.gcm.GcmListenerService",
					"com.google.android.gms.gcm.GoogleCloudMessaging",
					"com.google.android.gms.common.ConnectionResult",
					"com.google.android.gms.common.GooglePlayServicesUtil",
					"java.util.ArrayList",
					"java.util.HashMap",
					"org.json.JSONException",
					"org.json.JSONObject")]
	[Require("Gradle.Dependency.Compile", "com.google.android.gms:play-services-gcm:9.2.0")]
	extern(Android)
	internal class AndroidImpl
	{
		public static event EventHandler<string> RegistrationSucceeded;
		public static event EventHandler<string> RegistrationFailed;
		public static event EventHandler<KeyValuePair<string,bool>> ReceivedNotification;

		static bool _init = false;
		static List<string> _cachedMessages = new List<string>();
		static string _senderID = extern<string>"uString::Ansi(\"@(Project.Android.GooglePlay.SenderID:Or(''))\")";
		static int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;

		internal static void Init()
		{
			if (!_init)
			{
				if (_senderID!="")
				{
					JInit();
					_init = true;
					Lifecycle.EnteringInteractive += OnEnteringInteractive;
					Lifecycle.ExitedInteractive += OnExitedInteractive;
				} else {
					debug_log "Fuse.PushNotifications: You have tried to start the android push notification service but do not have a 'Project.Android.GooglePlay.SenderID' specified in your unoproj file. Please add one and try again.";
				}
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

			// Set up GCM
			final String senderID = @{_senderID};
			final Activity activity = com.fuse.Activity.getRootActivity();
			activity.runOnUiThread(new Runnable() {
					@Override
						public void run() {
						// Check device for Play Services APK. If check succeeds, proceed with GCM registration.
						if (@{CheckPlayServices():Call()}) {
							GoogleCloudMessaging _gcm = GoogleCloudMessaging.getInstance(activity);
							if (_gcm == null) {
								_gcm = GoogleCloudMessaging.getInstance(activity.getApplicationContext());
							}
							final GoogleCloudMessaging gcm = _gcm;
							new AsyncTask<Void, Void, String>() {
								@Override protected String doInBackground(Void... params) {
									String msg = "";
									try {
										String _regID = gcm.register(senderID);
										@{getRegistrationIdSuccess(string):Call(_regID)};
										return "Device registered, registration ID=" + _regID;
									} catch (java.io.IOException ex) {
										msg = "Error :" + ex.getMessage();
										@{getRegistrationIdError(string):Call(msg)};
										return msg;
									}
								}
								@Override protected void onPostExecute(String msg) {}
							}.execute();
						} else {
							debug_log("No valid Google Play Services APK found.");
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
			int resultCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(activity);
			if (resultCode != ConnectionResult.SUCCESS) {
				if (GooglePlayServicesUtil.isUserRecoverableError(resultCode)) {
					GooglePlayServicesUtil.getErrorDialog(resultCode, activity, @{PLAY_SERVICES_RESOLUTION_REQUEST}).show();
				} else {
					debug_log("This device is not supported.");
				}
				return false;
			}
			return true;
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
			var message = GetPayloadFromBundle(bundle);
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
		static string GetPayloadFromBundle(Java.Object _bundle)
		@{
			Bundle bundle = (Bundle)_bundle;
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
			JSONObject resultJson = new JSONObject(result);
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
				String notification = bundle.getString("notification");
				String aps = bundle.getString("aps");
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
				String s = (String)alertObj;
				@{SpitOutNotification(Java.Object,string,string,string,string,string,string,string,Java.Object):Call(listener,
						s,
						"",
						json.optString("bigTitle"),
						json.optString("bigBody"),
						json.optString("notificationStyle"),
						json.optString("featuredImage"),
						json.optString("sound"),
						bundle)};
			}
			else
			{
				JSONObject alert = (JSONObject)alertObj;
				if (alertObj!=null)
				{
					@{SpitOutNotification(Java.Object,string,string,string,string,string,string,string,Java.Object):Call(listener,
						alert.optString("title"),
						alert.optString("body"),
						alert.optString("bigTitle"),
						alert.optString("bigBody"),
						alert.optString("notificationStyle"),
						alert.optString("featuredImage"),
						alert.optString("sound"),
						bundle)};
				}
			}
		@}

		[Foreign(Language.Java)]
		static void SpitOutNotification(Java.Object _listener, string title, string body, string bigTitle, string bigBody, string notificationStyle, string featuredImage, string sound, Java.Object _payload)
		@{
			Context context = (Context)_listener;
			Bundle payload = (Bundle)_payload;
			Intent intent = new Intent(context, @(Activity.Package).@(Activity.Name).class);
			intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
			intent.setAction(PushNotificationReceiver.ACTION);
			intent.replaceExtras(payload);
			android.app.PendingIntent pendingIntent = android.app.PendingIntent.getActivity(context, 0, intent, android.app.PendingIntent.FLAG_ONE_SHOT);
			android.app.NotificationManager notificationManager = (android.app.NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);

			NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(context)
				.setSmallIcon(@(Activity.Package).R.mipmap.notif)
				.setContentTitle(title)
				.setContentText(body)
				.setAutoCancel(true)
				.setContentIntent(pendingIntent);

			if (sound=="default")
			{
				Uri defaultSoundUri= RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
				notificationBuilder.setSound(defaultSoundUri);
			}

			int id = PushNotificationReceiver.nextID();

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
					if (featuredImage.startsWith("http://") || featuredImage.startsWith("https://"))
					{
						BigPictureStyleHttp bps = new BigPictureStyleHttp(notificationManager, id, notificationBuilder, bigTitle, bigBody, sound);
						bps.execute(featuredImage);
						return;
					}
					else
					{
						Bitmap bitmap = null;
						int iconResourceID = com.fuse.R.get(featuredImage);

						if (iconResourceID!=-1)
						{
							bitmap = android.graphics.BitmapFactory.decodeResource(context.getResources(), iconResourceID);
						}
						else
						{
							String packageName = "@(Project.Name)";
							InputStream afs = com.fuse.PushNotifications.BundleFiles.OpenBundledFile(context, packageName, featuredImage);

							if (afs != null)
							{
								bitmap = android.graphics.BitmapFactory.decodeStream(afs);
								try
								{
									afs.close();
								}
								catch (IOException e)
								{
									Log.d(packageName, "Could close the notification image '" + featuredImage);
									e.printStackTrace();
									return;
								}
							}
							else
							{
								Log.d(packageName, "Could not the load image '" + featuredImage + "' as either a bundled file or android resource");
							}
						}

						notificationBuilder.setStyle(new NotificationCompat.BigPictureStyle()
							.bigPicture(bitmap)
							.setBigContentTitle(bigTitle)
							.setSummaryText(bigBody));
					}
				}
			}

			Notification n = notificationBuilder.build();
			if (sound!="")
				n.defaults |= Notification.DEFAULT_SOUND;
			n.defaults |= Notification.DEFAULT_LIGHTS;
			n.defaults |= Notification.DEFAULT_VIBRATE;
			notificationManager.notify(id, n);
		@}
	}
}
