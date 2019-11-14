using Uno.Compiler.ExportTargetInterop;
using Uno;
using Uno.Graphics;
using Uno.Platform;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Uno.Threading;

namespace Fuse.PushNotifications
{
	
	[ForeignInclude(Language.Java,
		"android.util.Log",
		"com.google.firebase.iid.FirebaseInstanceId",
		"java.util.ArrayList", 
		"java.util.List", 
		"android.graphics.Color"
	)]
	[Require("Gradle.Dependency.ClassPath", "com.google.gms:google-services:4.3.2")]
	[Require("Gradle.AllProjects.Repository", "maven {url 'https://maven.google.com'}")]
	[Require("Gradle.Dependency.Implementation", "com.google.firebase:firebase-analytics:17.2.1")]
	[Require("Gradle.BuildFile.End", "apply plugin: 'com.google.gms.google-services'")]
	public static class PushNotify
	{
		extern(Android)
		static PushNotify()
		{
			AndroidImpl.ReceivedNotification += OnReceived;
			AndroidImpl.RegistrationFailed += OnRegistrationFailed;
			AndroidImpl.RegistrationSucceeded += OnRegistrationSucceeded;
			AndroidImpl.Init();
		}

		extern(iOS)
		static PushNotify()
		{
			Fuse.PushNotifications.iOSImpl.ReceivedNotification += OnReceived;
			Fuse.PushNotifications.iOSImpl.NotificationRegistrationFailed += OnRegistrationFailed;
			Fuse.PushNotifications.iOSImpl.NotificationRegistrationSucceeded += OnRegistrationSucceeded;
		}

		public static void OnReceived(object sender, KeyValuePair<string,bool> notification)
		{
			var x = _receivedNotification;
			if (x!=null)
				x(null, notification);
			else
				_pendingNotifications.Add(notification);
		}

		public static void OnRegistrationFailed(object sender, string message)
		{
			var x = _registrationFailed;
			if (x!=null)
			{
				x(null, message);
			}
			else
			{
				_pendingSuccess = null;
				_pendingFailure = message;
			}
		}

		public static void OnRegistrationSucceeded(object sender, string message)
		{
			var x = _registrationSucceeded;
			if (x!=null)
			{
				x(null, message);
			}
			else
			{
				_pendingFailure = null;
				_pendingSuccess = message;
			}
		}

		static event EventHandler<string> _registrationSucceeded;
		static event EventHandler<string> _registrationFailed;
		static event EventHandler<KeyValuePair<string,bool>> _receivedNotification;
		static string _pendingSuccess;
		static string _pendingFailure;
		static List<KeyValuePair<string,bool>> _pendingNotifications = new List<KeyValuePair<string,bool>>();

		internal static event EventHandler<KeyValuePair<string,bool>> ReceivedNotification
		{
			add
			{
				_receivedNotification += value;
				foreach (var n in _pendingNotifications)
					value(null, n);
				_pendingNotifications.Clear();
			}
			remove {
				_receivedNotification -= value;
			}
		}

		// NOTE: We dont clean the _pendingSuccess or _pendingFailure fields
		//       As each consumer of PushNotifications will need to know these details.

		internal static event EventHandler<string> RegistrationSucceeded
		{
			add
			{
				_registrationSucceeded += value;
				if (_pendingSuccess!=null)
				{
					value(null, _pendingSuccess);
				}
			}
			remove {
				_registrationSucceeded -= value;
			}
		}

		internal static event EventHandler<string> RegistrationFailed
		{
			add
			{
				_registrationFailed += value;
				if (_pendingFailure!=null)
				{
					value(null, _pendingFailure);
				}
			}
			remove {
				_registrationFailed -= value;
			}
		}

		[Foreign(Language.ObjC)]
		public extern(iOS) static void ClearBadgeNumber()
		@{
			dispatch_async(dispatch_get_main_queue(), ^{
				[UIApplication sharedApplication].applicationIconBadgeNumber = 0;
			});
		@}

		public extern(!iOS) static void ClearBadgeNumber() { }

		[Foreign(Language.ObjC)]
		public extern(iOS) static void ClearAllNotifications()
		@{
			dispatch_async(dispatch_get_main_queue(), ^{
				[UIApplication sharedApplication].applicationIconBadgeNumber = 1;
				[UIApplication sharedApplication].applicationIconBadgeNumber = 0;
			});
		@}

		[Foreign(Language.Java)]
		public extern(Android) static void ClearAllNotifications()
		@{
			android.app.Activity activity = com.fuse.Activity.getRootActivity();
			android.app.NotificationManager nMgr = (android.app.NotificationManager)activity.getSystemService(android.content.Context.NOTIFICATION_SERVICE);
			nMgr.cancelAll();
		@}

		public extern(!iOS && !Android) static void ClearAllNotifications() { }

		public extern(iOS) static void Register()
		{
			iOSImpl.RegisterForPushNotifications();
		}

		public extern(!iOS) static void Register() { }

		public extern(iOS) static bool IsRegisteredForRemoteNotifications()
		{
			return iOSImpl.IsRegisteredForRemoteNotifications();
		}

		public extern(Android) static bool IsRegisteredForRemoteNotifications() { return true; }
		public extern(!iOS && !Android) static bool IsRegisteredForRemoteNotifications() { return true; }
	}
}
