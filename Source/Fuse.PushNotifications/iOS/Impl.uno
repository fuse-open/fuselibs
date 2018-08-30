using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Platform;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.PushNotifications
{
	[Require("Entity", "Fuse.PushNotifications.iOSImpl.OnNotificationRegistrationSucceeded(string)")]
	[Require("Entity", "Fuse.PushNotifications.iOSImpl.OnNotificationRegistrationFailed(string)")]
	[Require("Entity", "Fuse.PushNotifications.iOSImpl.OnReceivedNotification(string,bool)")]
	[Require("uContext.SourceFile.DidFinishLaunching", "[self application:[notification object] initializePushNotifications:[notification userInfo]];")]
	[Require("uContext.SourceFile.Declaration", "#include <iOS/AppDelegatePushNotify.h>")]
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
			if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
				// use registerUserNotificationSettings
				dispatch_async(dispatch_get_main_queue(), ^{
					[application registerUserNotificationSettings: [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound  | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)  categories:nil]];
					[application registerForRemoteNotifications];
				});
			} else {
				// use registerForRemoteNotificationTypes:
				dispatch_async(dispatch_get_main_queue(), ^{
					[application registerForRemoteNotificationTypes:
					 UIRemoteNotificationTypeBadge |
					 UIRemoteNotificationTypeSound |
					 UIRemoteNotificationTypeAlert];
				});
			}
		@}
	}
}
