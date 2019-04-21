package com.fuse.sensorkit;

import android.content.Context;
import android.hardware.SensorEvent;
import com.foreign.Uno.Action_Object;

public class RotationSensor extends AbstractSensor {

    public RotationSensor(Action_Object onDataChanged) {
        super(SensorType.ROTATION, onDataChanged);
    }

    @Override
    protected SensorData buildData(SensorEvent event) {
        return new SensorData(SensorType.ROTATION, event.values);
    }

    @Override
    protected String getSensorName() {
        return "Rotation";
    }

}