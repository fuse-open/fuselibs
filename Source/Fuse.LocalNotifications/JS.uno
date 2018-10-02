using Uno;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;
using Uno.UX;

namespace Fuse.LocalNotifications
{
	/** Create, schedule and react to notifications created locally
		@scriptmodule FuseJS/LocalNotifications

		@include Docs/Guide.md

		## Remarks

		This module is an @EventEmitter, so the methods from @EventEmitter can be used to listen to events.

		You need to add a reference to `"Fuse.LocalNotifications"` in your project file to use this feature.
	*/
	[UXGlobalModule]
	public sealed class LocalNotify : NativeEventEmitterModule
	{
		static readonly LocalNotify _instance;

		public LocalNotify()
			: base(true,
				"receivedMessage")

		{
			if(_instance != null) return;
			Uno.UX.Resource.SetGlobalKey(_instance = this, "FuseJS/LocalNotifications");

			var onReceivedMessage = new NativeEvent("onReceivedMessage");

			On("receivedMessage", onReceivedMessage);

			AddMember(new NativeFunction("now", Now));
			AddMember(new NativeFunction("later", Later));
			AddMember(new NativeFunction("clearBadgeNumber", ClearBadgeNumber));
			AddMember(new NativeFunction("clearAllNotifications", ClearAllNotifications));
			AddMember(onReceivedMessage);

			Fuse.LocalNotifications.Notify.Received += OnReceived;
		}
		
		/**
			@scriptevent receivedMessage
		*/
		void OnReceived(object sender, string message)
		{
			Emit("receivedMessage", message);
		}

		/** Displays a notification to the user after the time specified by `secondsFromNow` has passed.
		
			@scriptmethod later(secondsFromNow, title, body, payload, sound, badgeNumber)
			
			@param secondsFromNow (Number) How long in seconds until the notification fires.
			@param title (String) The title of the notification.
			@param body (String) The body text of the notification.
			@param payload (String) A string that is not shown in the notification itself, but will be present in the callback.
			@param sound (bool) A boolean specifying whether the device should make the default notification sound when it is shown in the notification bar.
			@param badgeNumber (Number) An optional parameter that is only used on iOS to put a badge number against the apps icon. This is often used for showing the quantity of 'things' that need the user's attention. For example an email app could show the number of unread emails.
		*/
		public object Later(Context context, object[] args)
		{
			if(args.Length > 0)
			{
				var secondsFromNow = GetInt(args[0], "secondsFromNow");
				var badgeNumber = (args.Length > 5) ? GetInt(args[5], "badgeNumber") : 0;
				var hasSoundArg = (args.Length > 4);

				Fuse.LocalNotifications.Notify.Later(
					secondsFromNow,   // secondsFromNow
					(string)args[1],  // title
					(string)args[2],  // body
					(args[3]!=null ? (string)args[3] : ""), // payload
					(hasSoundArg ? (bool)args[4] : true),   // sound
					badgeNumber);     // badgeNumber
			}
			return null;
		}

		/** Instantly displays a notification to the user.
		
			@scriptmethod now(title, body, payload, sound, badgeNumber)
			
			@param title (String) The title of the notification.
			@param body (String) The body text of the notification.
			@param payload (String) A string that is not shown in the notification itself, but will be present in the callback.
			@param sound (bool) A boolean specifying whether the device should make the default notification sound when it is shown in the notification bar.
			@param badgeNumber (Number) An optional parameter that is only used on iOS to put a badge number against the apps icon. This is often used for showing the quantity of 'things' that need the user's attention. For example an email app could show the number of unread emails.
		*/
		public object Now(Context context, object[] args)
		{
			if(args.Length > 0)
			{
				var badgeNumber = (args.Length > 4) ? GetInt(args[4], "badgeNumber") : 0;
				var hasSoundArg = args.Length > 3;
				Fuse.LocalNotifications.Notify.Now(
					(string)args[0],  // title
					(string)args[1],  // body
					(args[2]==null ? "" : (string)args[2]), // payload
					(hasSoundArg ? (bool)args[3] : true),   // sound
					badgeNumber);     // badgeNumber
			}
			return null;
		}

		static int GetInt(object arg, string argName)
		{
			if (arg == null)
				return 0;
			if (arg is int)
				return (int)arg;
			else if (arg is double)
				return (int)((double)arg);
			else
				throw new Exception("Invalid value for argument '" + argName + "' passed from JS to LocalNotifications");
			return 0;
		}

		/**
			@scriptmethod clearBadgeNumber
			
			Clears the badge number shown on the iOS home screen.
		*/
		public object ClearBadgeNumber(Context context, object[] args)
		{
			Fuse.LocalNotifications.Notify.ClearBadgeNumber();
			return null;
		}
		
		/**
			@scriptmethod clearAllNotifications
			
			Dismisses all currently active notifications created by our app.
		*/
		public object ClearAllNotifications(Context context, object[] args)
		{
			Fuse.LocalNotifications.Notify.ClearAllNotifications();
			return null;
		}
	}
}
