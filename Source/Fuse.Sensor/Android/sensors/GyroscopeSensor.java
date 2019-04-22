package com.fuse.sensorkit;

import android.content.Context;
import android.hardware.SensorEvent;
import com.foreign.Uno.Action_Object;

public class GyroscopeSensor extends AbstractSensor {

    public GyroscopeSensor(Action_Object onDataChanged) {
        super(SensorType.GYROSCOPE, onDataChanged);
    }

    @Override
    protected SensorData buildData(SensorEvent event) {
        return new SensorData(SensorType.GYROSCOPE, event.values);
    }

    @Override
    protected String getSensorName() {
        return "Gyroscope";
    }

}