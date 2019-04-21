package com.fuse.sensorkit;

import android.content.Context;
import android.hardware.SensorEvent;
import com.foreign.Uno.Action_Object;

public class AccelerometerSensor extends AbstractSensor {

    public AccelerometerSensor(Action_Object onDataChanged) {
        super(SensorType.ACCELEROMETER, onDataChanged);
    }

    @Override
    protected SensorData buildData(SensorEvent event) {
        return new SensorData(SensorType.ACCELEROMETER, event.values);
    }

    @Override
    protected String getSensorName() {
        return "Accelerometer";
    }

}