using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Platform;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.PushNotifications
{
	[Require("entity", "Fuse.PushNotifications.iOSImpl.OnNotificationRegistrationSucceeded(string)")]
	[Require("entity", "Fuse.PushNotifications.iOSImpl.OnNotificationRegistrationFailed(string)")]
	[Require("entity", "Fuse.PushNotifications.iOSImpl.OnReceivedNotification(string,bool)")]
	[Require("uContext.sourceFile.didFinishLaunching", "[self application:[notification object] initializePushNotifications:[notification userInfo]];")]
	[Require("uContext.sourceFile.declaration", "#include <iOS/AppDelegatePushNotify.h>")]
	[Require("xcode.framework", "UserNotifications.framework")]
	[Require("source.include", "UserNotifications/UserNotifications.h")]
	extern(iOS)
	internal class iOSImpl
	{

		public static event EventHandler<KeyValuePair<string,bool>> ReceivedNotification;
		static List<KeyValuePair<string,bool>> DelayedNotifications = new List<KeyValuePair<string,bool>>();

		internal static void OnReceivedNotification(string notification, bool fromNotificationBar)
		{
			if (Lifecycle.State == ApplicationState.Foreground ||
				Lifecycle.State == ApplicationState.Interactive)
			{
				var handler = ReceivedNotification;
				if (handler != null)
					handler(null, new KeyValuePair<string,bool>(notification, fromNotificationBar));
			}
			else
			{
				DelayedNotifications.Add(new KeyValuePair<string,bool>(notification, fromNotificationBar));
				Lifecycle.EnteringForeground += DispatchDelayedNotifications;
			}
		}
		private static void DispatchDelayedNotifications(ApplicationState state)
		{
			var handler = ReceivedNotification;
			if (handler != null)
				foreach (var n in DelayedNotifications)
					handler(null, n);
			DelayedNotifications.Clear();
			Lifecycle.EnteringForeground -= DispatchDelayedNotifications;
		}

		public static event EventHandler<string> NotificationRegistrationFailed;
		static string DelayedReason = "";
		internal static void OnNotificationRegistrationFailed(string reason)
		{
			if (Lifecycle.State == ApplicationState.Foreground ||
				Lifecycle.State == ApplicationState.Interactive)
			{
				EventHandler<string> handler = NotificationRegistrationFailed;
				if (handler != null)
					handler(null, reason);
			}
			else
			{
				DelayedReason = reason;
				Lifecycle.EnteringForeground += DispatchDelayedReason;
			}
		}
		private static void DispatchDelayedReason(ApplicationState state)
		{
			EventHandler<string> handler = NotificationRegistrationFailed;
			if (handler != null)
				handler(null, DelayedReason);
			DelayedReason = "";
			Lifecycle.EnteringForeground -= DispatchDelayedReason;
		}

		public static event EventHandler<string> NotificationRegistrationSucceeded;
		static string DelayedRegToken = "";
		internal static void OnNotificationRegistrationSucceeded(string regID)
		{
			if (Lifecycle.State == ApplicationState.Foreground ||
				Lifecycle.State == ApplicationState.Interactive)
			{
				EventHandler<string> handler = NotificationRegistrationSucceeded;
				if (handler != null)
					handler(null, regID);
			}
			else
			{
				DelayedRegToken = regID;
				Lifecycle.EnteringForeground += DispatchDelayedRegToken;
			}
		}
		private static void DispatchDelayedRegToken(ApplicationState state)
		{
			EventHandler<string> handler = NotificationRegistrationSucceeded;
			if (handler != null)
				handler(null, DelayedRegToken);
			DelayedRegToken = "";
			Lifecycle.EnteringForeground -= DispatchDelayedRegToken;
		}

		[Foreign(Language.ObjC)]
		internal static void RegisterForPushNotifications()
		@{
			UIApplication* application = [UIApplication sharedApplication];
			/*
				Explicitly ask for permission else notifications are silent
				https://developer.apple.com/documentation/uikit/uiapplication/1623078-registerforremotenotifications?language=objc
			*/
			UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
			[center requestAuthorizationWithOptions:
					(UNAuthorizationOptionAlert +
					UNAuthorizationOptionSound +
					UNAuthorizationOptionBadge)
					completionHandler:^(BOOL granted, NSError * _Nullable error) {
					/* Continue to register users token, so that if they turn it on
					in their general settings later, it will be "on" in your server side too */
					dispatch_async(dispatch_get_main_queue(), ^{
						[application registerForRemoteNotifications];
					});
			}];
		@}

		[Foreign(Language.ObjC)]
		internal static bool IsRegisteredForRemoteNotifications()
		@{
			__block bool isRegisteredForRemote = true;

			__block bool isNotificationsSettingsEnabled = true;

			dispatch_sync(dispatch_get_main_queue(), ^{
				isRegisteredForRemote = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];

				[[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
					isNotificationsSettingsEnabled = (settings.authorizationStatus == UNAuthorizationStatusAuthorized);
				}];
			});
			return (isRegisteredForRemote && isNotificationsSettingsEnabled);
		@}
	}
}
