package com.fuse.sensorkit;

import android.content.Context;
import android.hardware.SensorEvent;
import com.foreign.Uno.Action_Object;

public class UserAccelerationSensor extends AbstractSensor {

    public UserAccelerationSensor(Action_Object onDataChanged) {
        super(SensorType.USER_ACCELERATION, onDataChanged);
    }

    @Override
    protected SensorData buildData(SensorEvent event) {
        return new SensorData(SensorType.USER_ACCELERATION, event.values);
    }

    @Override
    protected String getSensorName() {
        return "User Acceleration";
    }

}