package com.fuse.sensorkit;

import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import com.foreign.Uno.Action_Object;

public class ConnectionStateSensor {

    private Action_Object onDataChanged;
    protected boolean isSensing = false;
    private final BroadcastReceiver mBroadcastReceiver;

    public ConnectionStateSensor(Action_Object onDataChanged) {
        this.onDataChanged = onDataChanged;
        mBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (ConnectionStateSensor.this.onDataChanged != null){
                    boolean connectionStatus = false;
                    NetworkInfo networkInfo =(NetworkInfo) intent.getExtras().get(ConnectivityManager.EXTRA_NETWORK_INFO);
                    if(networkInfo!=null && networkInfo.getState() == NetworkInfo.State.CONNECTED) {
                        connectionStatus = true;
                    } else if(intent.getBooleanExtra(ConnectivityManager.EXTRA_NO_CONNECTIVITY,Boolean.FALSE)) {
                        connectionStatus = false;
                    }
                    ConnectionStateSensor.this.onDataChanged.run(new ConnectionStateData(connectionStatus, connectionStatus ? "connected" : "disconnected"));
                }
            }
        };
    }

    public void start() {
        this.isSensing = true;
        IntentFilter filter = new IntentFilter();
        filter.addAction("android.net.conn.CONNECTIVITY_CHANGE");
        com.fuse.Activity.getRootActivity().registerReceiver(mBroadcastReceiver, filter);
    }

    public void stop() {
        com.fuse.Activity.getRootActivity().unregisterReceiver(mBroadcastReceiver);
        this.isSensing = false;
    }

    public boolean isSensing() {
        return isSensing;
    }
}