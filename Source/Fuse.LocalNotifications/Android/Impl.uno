using Uno;
using Uno.Graphics;
using Fuse.Platform;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Fuse.Triggers;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;
using Uno.Compiler.ExportTargetInterop.Android;

namespace Fuse.LocalNotifications
{
    [ForeignInclude(Language.Java,
                    "android.content.BroadcastReceiver",
                    "android.content.Context",
                    "android.content.Intent",
                    "android.app.Activity",
                    "android.app.AlarmManager",
                    "android.app.Notification",
                    "android.app.NotificationChannel",
                    "android.app.NotificationManager",
                    "androidx.core.app.NotificationCompat",
                    "androidx.core.app.NotificationManagerCompat",
                    "android.app.PendingIntent",
                    "android.content.res.Resources",
                    "android.graphics.BitmapFactory",
                    "android.graphics.Color",
                    "android.media.RingtoneManager",
                    "android.net.Uri",
                    "android.os.Build",
                    "android.util.Log")]
    internal extern(android) static class AndroidImpl
    {
        static bool _init = false;
        static bool _hasFocus = false;

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

        static void OnEnteringInteractive(ApplicationState newState)
        {
            NoteInteractivity(true);
        }

        static void OnExitedInteractive(ApplicationState newState)
        {
            NoteInteractivity(false);
        }

        [Foreign(Language.Java), ForeignFixedName]
        static void NoteInteractivity(bool isItInteractive)
        @{
            com.fuse.LocalNotifications.LocalNotificationReceiver.InForeground = isItInteractive;
        @}

        [Foreign(Language.Java), ForeignFixedName]
        static void JInit()
        @{
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                int importance = NotificationManager.IMPORTANCE_DEFAULT;
                String channelId = "@(Project.Android.Notification.DefaultChannelId)";
                channelId = (channelId != "") ? channelId : "default_channel";
                String channelName = "@(Project.Android.Notification.DefaultChannelName)";
                channelName = (channelName != "") ? channelName : "App";
                String channelDescription = "@(Project.Android.Notification.DefaultChannelDescription)";
                channelDescription = (channelDescription != "") ? channelDescription : "";
                NotificationChannel channel = new NotificationChannel(channelId, channelName, importance);
                channel.setDescription(channelDescription);
                NotificationManagerCompat notificationManager = NotificationManagerCompat.from(com.fuse.Activity.getRootActivity());
                notificationManager.createNotificationChannel(channel);
            }

            com.fuse.Activity.subscribeToIntents(
                new com.fuse.Activity.IntentListener() {
                    public void onIntent (Intent newIntent) {
                        String title = newIntent.getStringExtra("title");
                        String body = newIntent.getStringExtra("bbody");
                        String payload = newIntent.getStringExtra(@{ACTION});
                        String result = "{ 'title': '" + title + "', 'body': '" + body + "', 'payload': '" + payload + "' }";
                        @{NotificationRecieved(string):Call(result)};
                    }
                },
                @{ACTION});
        @}

        static void NotificationRecieved(string payload)
        {
            Fuse.LocalNotifications.Notify.OnReceived(null, payload);
        }

        static string ACTION = "com.fuse.LocalNotifications.strPayload";

        static int ID = -1;

        static int NextID()
        {
            return ID += 1;
        }

        [Foreign(Language.Java)]
        public static void Later(string title, string body, bool sound, string strPayload, int delaySeconds=0)
        @{
            android.app.Activity currentActivity = com.fuse.Activity.getRootActivity();
            android.app.AlarmManager alarmManager =
                (android.app.AlarmManager)currentActivity.getSystemService(android.content.Context.ALARM_SERVICE);
            android.content.Intent intent =
                new android.content.Intent(currentActivity, com.fuse.LocalNotifications.LocalNotificationReceiver.class);

            int id = @{NextID():Call()};

            intent.putExtra("id", id);
            intent.putExtra("title", title);
            intent.putExtra("body", body);
            intent.putExtra("sound", sound);
            intent.putExtra(@{ACTION}, strPayload.toString());

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S)
            {
                alarmManager.set(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + (delaySeconds * 1000),
                                android.app.PendingIntent.getBroadcast(currentActivity, id, intent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT));
            }
            else
            {
                alarmManager.set(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + (delaySeconds * 1000),
                                android.app.PendingIntent.getBroadcast(currentActivity, id, intent, PendingIntent.FLAG_UPDATE_CURRENT));
            }
        @}

        [Foreign(Language.Java), ForeignFixedNameAttribute]
        static void OnNotificationRecieved(Java.Object _context, Java.Object _intent)
        @{
            // Have to have a copy of ACTION here as this code will run BEFORE the app is started
            String ACTION = "com.fuse.LocalNotifications.strPayload";
            Context context = (Context)_context;
            Intent intent = (Intent)_intent;

            String title = intent.getStringExtra("title");
            String body = intent.getStringExtra("body");
            boolean sound = (boolean)intent.getBooleanExtra("sound", false);
            String payload = intent.getStringExtra(ACTION);
            int id = intent.getIntExtra("id", 0);

            if (com.fuse.LocalNotifications.LocalNotificationReceiver.InForeground)
            {
                String result = "{ 'title': '" + title + "', 'body': '" + body + "', 'payload': '" + payload + "' }";
                @{NotificationRecieved(string):Call(result)};
            }
            else
            {
                Intent notificationIntent = new Intent(context, @(Activity.Package).@(Activity.Name).class);
                notificationIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                notificationIntent.setAction(ACTION);
                notificationIntent.replaceExtras(intent.getExtras());

                PendingIntent contentIntent = null;
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S)
                {
                    contentIntent = PendingIntent.getActivity
                        (context, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
                }
                else
                {
                    contentIntent = PendingIntent.getActivity
                            (context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);
                }
                String channelId = "@(Project.Android.Notification.DefaultChannelId)";
                channelId = (channelId != "") ? channelId : "default_channel";
                NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(context, channelId)
                        .setSmallIcon(@(Activity.Package).R.mipmap.notif)
                        .setContentTitle(title)
                        .setContentText(body)
                        .setWhen(System.currentTimeMillis())
                        .setAutoCancel(true)
                        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                        .setVibrate(new long[] { 1000L, 1000L })
                        .setContentIntent(contentIntent);

                if (sound)
                {
                    Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
                    notificationBuilder.setSound(defaultSoundUri);
                }

                NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
                Notification n = notificationBuilder.build();
                if (sound)
                    n.defaults |= Notification.DEFAULT_SOUND;
                n.defaults |= Notification.DEFAULT_LIGHTS;
                n.defaults |= Notification.DEFAULT_VIBRATE;
                notificationManager.notify(id, n);
            }
        @}
    }
}
