package com.fuse.sensorkit;

import android.content.Context;
import android.hardware.SensorEvent;
import com.foreign.Uno.Action_Object;

public class PressureSensor extends AbstractSensor {

    public PressureSensor(Action_Object onDataChanged) {
        super(SensorType.PRESSURE, onDataChanged);
    }

    @Override
    protected SensorData buildData(SensorEvent event) {
        return new SensorData(SensorType.PRESSURE, new float[] {event.values[0], 0.0f, 0.0f});
    }

    @Override
    protected String getSensorName() {
        return "Pressure";
    }

}