package com.fuse.PushNotifications;

import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v4.os.AsyncTaskCompat;
import android.util.Log;

import com.google.android.gms.gcm.GcmReceiver;

import android.support.v4.app.JobIntentService;

import static com.fuse.PushNotifications.GcmConstants.ACTION_C2DM_RECEIVE;
import static com.fuse.PushNotifications.GcmConstants.ACTION_NOTIFICATION_OPEN;
import static com.fuse.PushNotifications.GcmConstants.EXTRA_ERROR;
import static com.fuse.PushNotifications.GcmConstants.EXTRA_FROM;
import static com.fuse.PushNotifications.GcmConstants.EXTRA_MESSAGE_ID;
import static com.fuse.PushNotifications.GcmConstants.EXTRA_MESSAGE_TYPE;
import static com.fuse.PushNotifications.GcmConstants.EXTRA_PENDING_INTENT;
import static com.fuse.PushNotifications.GcmConstants.MESSAGE_TYPE_DELETED_MESSAGE;
import static com.fuse.PushNotifications.GcmConstants.MESSAGE_TYPE_GCM;
import static com.fuse.PushNotifications.GcmConstants.MESSAGE_TYPE_SEND_ERROR;
import static com.fuse.PushNotifications.GcmConstants.MESSAGE_TYPE_SEND_EVENT;

public class PushNotificationService extends JobIntentService{
	private static final String TAG = "GcmListenerService";

	private int startId;
    private int counter = 0;
    private final Object lock = new Object();

    public void onDeletedMessages() {
        // To be overwritten
    }

    public void onMessageSent(String msgId) {
        // To be overwritten
    }

    public void onSendError(String msgId, String error) {
        // To be overwritten
    }

	public void onMessageReceived(String from, Bundle bundle)
	{
        Log.d(TAG,"On Message Received");
		synchronized (lock) {
			com.foreign.Fuse.PushNotifications.AndroidImpl.OnNotificationRecieved(this, from, bundle);
		}
	}


	@Override
	protected void onHandleWork(Intent intent) {
        Log.d(TAG, "handling work");
        synchronized (lock) {
            this.startId = startId;
            this.counter++;
        }

        if (intent != null) {
            Log.d(TAG, "Intent is not empty");
            Log.d(TAG, intent.getAction()+" ");
            if (ACTION_NOTIFICATION_OPEN.equals(intent.getAction())) {
                handlePendingNotification(intent);
                finishCounter();
                GcmReceiver.completeWakefulIntent(intent);
            } else if (ACTION_C2DM_RECEIVE.equals(intent.getAction())) {
                final Intent newIntent = intent;
                AsyncTaskCompat.executeParallel(new AsyncTask<Void, Void, Void>() {
                    @Override
                    protected Void doInBackground(Void... params) {
                        handleC2dmMessage(newIntent);
                        return null;
                    }
                });
            } else {
                Log.w(TAG, "Unknown intent action: " + intent.getAction());
            }
        } else {
            Log.d(TAG, "Intent is empty");
            finishCounter();
        }
    }

    private void handleC2dmMessage(Intent intent) {
        Log.d(TAG, "handling me");
        try {
            String messageType = intent.getStringExtra(EXTRA_MESSAGE_TYPE);
            if (messageType == null || MESSAGE_TYPE_GCM.equals(messageType)) {
                String from = intent.getStringExtra(EXTRA_FROM);
                Bundle data = intent.getExtras();
                data.remove(EXTRA_MESSAGE_TYPE);
                data.remove("android.support.content.wakelockid"); // WakefulBroadcastReceiver.EXTRA_WAKE_LOCK_ID
                data.remove(EXTRA_FROM);
                onMessageReceived(from, data);
            } else if (MESSAGE_TYPE_DELETED_MESSAGE.equals(messageType)) {
                onDeletedMessages();
            } else if (MESSAGE_TYPE_SEND_EVENT.equals(messageType)) {
                onMessageSent(intent.getStringExtra(EXTRA_MESSAGE_ID));
            } else if (MESSAGE_TYPE_SEND_ERROR.equals(messageType)) {
                onSendError(intent.getStringExtra(EXTRA_MESSAGE_ID), intent.getStringExtra(EXTRA_ERROR));
            } else {
                Log.w(TAG, "Unknown message type: " + messageType);
            }
            finishCounter();
        } finally {
            GcmReceiver.completeWakefulIntent(intent);
        }
    }

    private void handlePendingNotification(Intent intent) {
        PendingIntent pendingIntent = intent.getParcelableExtra(EXTRA_PENDING_INTENT);
        if (pendingIntent != null) {
            try {
                pendingIntent.send();
            } catch (PendingIntent.CanceledException e) {
                Log.w(TAG, "Notification cancelled", e);
            }
        } else {
            Log.w(TAG, "Notification was null");
        }
    }

    private void finishCounter() {
        synchronized (lock) {
            this.counter--;
            if (counter == 0) {
                stopSelfResult(startId);
            }
        }
    }
}