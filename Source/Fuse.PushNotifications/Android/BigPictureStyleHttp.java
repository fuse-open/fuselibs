package com.fuse.PushNotifications;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import androidx.core.app.NotificationCompat;
import android.util.Log;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

import static java.net.HttpURLConnection.HTTP_OK;

public class BigPictureStyleHttp extends AsyncTask<String, Void, Bitmap>
{
	private Exception exception;
	private NotificationManager _notificationManager;
	private int _id;
	private NotificationCompat.Builder _notificationBuilder;
	private NotificationCompat.BigPictureStyle _style;
	private String _sound;

	private void launchNotification(Bitmap bitmap)
	{
		_style.bigPicture(bitmap);
		_notificationBuilder.setStyle(_style);

		Notification n = _notificationBuilder.build();
		if (_sound != "")
			n.defaults |= Notification.DEFAULT_SOUND;
		n.defaults |= Notification.DEFAULT_LIGHTS;
		n.defaults |= Notification.DEFAULT_VIBRATE;
		_notificationManager.notify(_id, n);

	}

	public BigPictureStyleHttp(NotificationManager notificationManager, int id, NotificationCompat.Builder notificationBuilder,
							   NotificationCompat.BigPictureStyle style, String sound)
	{
		this._notificationManager = notificationManager;
		this._id = id;
		this._notificationBuilder = notificationBuilder;
		this._style = style;
		this._sound = sound;
	}

	@Override
	protected Bitmap doInBackground(String... params)
	{
		return downloadBitmap(params[0]);
	}

	@Override
	protected void onPostExecute(Bitmap bm)
	{
		launchNotification(bm);
	}

	private Bitmap downloadBitmap(String url)
	{
		HttpURLConnection urlConnection = null;
		try
		{
			URL uri = new URL(url);
			urlConnection = (HttpURLConnection) uri.openConnection();

			int statusCode = urlConnection.getResponseCode();
			if (statusCode != HTTP_OK)
			{
				return null;
			}

			InputStream inputStream = urlConnection.getInputStream();
			if (inputStream != null)
			{
				Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
				return bitmap;
			}
		}
		catch (Exception e)
		{
			Log.d("URLCONNECTIONERROR", e.toString());
			if (urlConnection != null)
			{
				urlConnection.disconnect();
			}
			Log.w("Fuse.PushNotifications", "Error downloading image from " + url);
		}
		finally
		{
			if (urlConnection != null)
			{
				urlConnection.disconnect();
			}
		}
		return null;
	}

}
