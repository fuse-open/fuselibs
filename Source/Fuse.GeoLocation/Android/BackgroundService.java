package fuse.geolocation;

import android.os.IBinder;
import android.app.PendingIntent;
import android.content.Intent;
import android.app.Service;
import android.util.Log;
import android.os.Build;
import android.graphics.Color;
import android.content.Context;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import androidx.core.app.NotificationCompat;

public class BackgroundService extends Service
{
	private static final int SERVICE_ID = 101;

	public static final String ACTION_START_FOREGROUND_SERVICE = "ACTION_START_FOREGROUND_SERVICE";
    public static final String ACTION_STOP_FOREGROUND_SERVICE = "ACTION_STOP_FOREGROUND_SERVICE";

	public BackgroundService()
	{
		// Log.d("BACKGROUND SERVICE", "CREATED");
	}

	@Override
	public IBinder onBind(Intent intent) {

		throw new UnsupportedOperationException("Not yet implemented");
	}

	@Override
	public void onCreate()
	{
		super.onCreate();
		// Log.d("BACKGROUND SERVICE", "onCREATE()");
	}



	@Override
	public int onStartCommand(Intent intent, int flags, int startId)
	{
		if(intent != null)
		{
			String action = intent.getAction();

			switch (action)
			{
				case ACTION_START_FOREGROUND_SERVICE: startForegroundService();
					break;
				case ACTION_STOP_FOREGROUND_SERVICE: stopForegroundService();
					break;
			}
		}

		return START_STICKY;
	}



	private void startForegroundService()
	{
		// Log.d("BACKGROUND SERVICE", "startForeground");

        Intent intent = new Intent(this, @(Activity.Package).@(Activity.Name).class);
        intent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);

		NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        String channelId = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? createNotificationChannel(notificationManager) : "";
        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(this, channelId);
        notificationBuilder
        		.setOngoing(true)
        		.setAutoCancel(false)
		        .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_SERVICE);

        //color icons in android 10 (Q)
        if (Build.VERSION.SDK_INT >= 29) {
        	notificationBuilder.setSmallIcon(@(Activity.Package).R.mipmap.icon);
        } else {
        	notificationBuilder.setSmallIcon(@(Activity.Package).R.mipmap.bk_location);
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

        NotificationCompat.BigTextStyle bigTextStyle = new NotificationCompat.BigTextStyle();
        bigTextStyle.setBigContentTitle("Background Location");
        bigTextStyle.bigText("Background Location is Actively Using Your Location.");
        notificationBuilder.setStyle(bigTextStyle);

        Notification notification = notificationBuilder.build();

        startForeground(SERVICE_ID, notification);
	}

	private String createNotificationChannel(NotificationManager notificationManager){
        String channelId = "location_foreground_service_channelid";
        String channelName = "Background Location";
        NotificationChannel channel = new NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH);
        // omitted the LED color
        channel.setImportance(NotificationManager.IMPORTANCE_NONE);
        channel.setLockscreenVisibility(Notification.VISIBILITY_PRIVATE);
        notificationManager.createNotificationChannel(channel);
        return channelId;
    }

	private void stopForegroundService()
	{
		// Log.d("FOREGROUND SERVICE", "Stop foreground service");

        // Stop foreground service and remove the notification.
        stopForeground(true);

        // Stop the foreground service.
        stopSelf();
	}

}
