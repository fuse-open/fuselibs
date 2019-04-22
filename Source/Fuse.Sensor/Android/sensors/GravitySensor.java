package com.fuse.sensorkit;

import android.content.Context;
import android.hardware.SensorEvent;
import com.foreign.Uno.Action_Object;

public class GravitySensor extends AbstractSensor {

    public GravitySensor(Action_Object onDataChanged) {
        super(SensorType.GRAVITY, onDataChanged);
    }

    @Override
    protected SensorData buildData(SensorEvent event) {
        return new SensorData(SensorType.GRAVITY, event.values);
    }

    @Override
    protected String getSensorName() {
        return "Gravity";
    }

}