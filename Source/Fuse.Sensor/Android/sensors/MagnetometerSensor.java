package com.fuse.sensorkit;

import android.content.Context;
import android.hardware.SensorEvent;
import com.foreign.Uno.Action_Object;

public class MagnetometerSensor extends AbstractSensor {

    public MagnetometerSensor(Action_Object onDataChanged) {
        super(SensorType.MAGNETOMETER, onDataChanged);
    }

    @Override
    protected SensorData buildData(SensorEvent event) {
        return new SensorData(SensorType.MAGNETOMETER, event.values);
    }

    @Override
    protected String getSensorName() {
        return "Magnetometer";
    }

}