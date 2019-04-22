package com.fuse.sensorkit;

import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import com.foreign.Uno.Action_Object;

public class BatterySensor {

    private Action_Object onDataChanged;
    protected boolean isSensing = false;

    // Last data sensed
    private int mLastLevelSensed = Integer.MAX_VALUE;
    private int mLastScaleSensed = Integer.MAX_VALUE;
    private int mLastTemperatureSensed = Integer.MAX_VALUE;
    private int mLastVoltageSensed = Integer.MAX_VALUE;
    private int mLastPluggedSensed = Integer.MAX_VALUE;
    private int mLastStatusSensed = Integer.MAX_VALUE;
    private int mLastHealthSensed = Integer.MAX_VALUE;

    private final BroadcastReceiver mBroadcastReceiver;

    public BatterySensor(Action_Object onDataChanged) {
        this.onDataChanged = onDataChanged;
        mBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                // Read Battery
                int level = intent.getIntExtra("level", -1);
                int scale = intent.getIntExtra("scale", -1);
                int temperature = intent.getIntExtra("temperature", 0);
                int voltage = intent.getIntExtra("voltage", 0);
                int plugged = intent.getIntExtra("plugged", -1);
                int status = intent.getIntExtra("status", 0);
                int health = intent.getIntExtra("health", 0);
                BatteryData data = new BatteryData(level, scale, temperature, voltage, plugged, status, health);
                if (BatterySensor.this.onDataChanged != null && BatterySensor.this.shouldPostData(data))
                    BatterySensor.this.onDataChanged.run(data);
            }
        };
    }

    public void start() {
        this.isSensing = true;
        IntentFilter filter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
        com.fuse.Activity.getRootActivity().registerReceiver(mBroadcastReceiver, filter);
    }

    public void stop() {
        com.fuse.Activity.getRootActivity().unregisterReceiver(mBroadcastReceiver);
        this.isSensing = false;
        // Clear last sensed values
        mLastLevelSensed = Integer.MAX_VALUE;
        mLastScaleSensed = Integer.MAX_VALUE;
        mLastTemperatureSensed = Integer.MAX_VALUE;
        mLastVoltageSensed = Integer.MAX_VALUE;
        mLastPluggedSensed = Integer.MAX_VALUE;
        mLastStatusSensed = Integer.MAX_VALUE;
        mLastHealthSensed = Integer.MAX_VALUE;
    }

    public boolean isSensing() {
        return isSensing;
    }

    protected boolean shouldPostData(BatteryData data) {
        // Only post when specific values changed
        int level = data.getLevel();
        int scale = data.getScale();
        int temperature = data.getTemperature();
        int voltage = data.getVoltage();
        int plugged = data.getPlugged();
        int status = data.getBatteryStatus();
        int health = data.getBatteryHealth();

        // Ignore Temperature and Voltage
        boolean shouldPost = (mLastLevelSensed != level ||
                              mLastScaleSensed != scale ||
                              mLastPluggedSensed != plugged ||
                              mLastStatusSensed != status ||
                              mLastHealthSensed != health );

        if (shouldPost) {
            this.mLastLevelSensed = level;
            this.mLastScaleSensed = scale;
            this.mLastTemperatureSensed = temperature;
            this.mLastVoltageSensed = voltage;
            this.mLastPluggedSensed = plugged;
            this.mLastStatusSensed = status;
            this.mLastHealthSensed = health;
        }

        return shouldPost;
    }

}