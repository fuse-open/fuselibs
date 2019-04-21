package com.fuse.sensorkit;

import android.content.Context;
import android.hardware.SensorEvent;
import com.foreign.Uno.Action_Object;

public class PedometerSensor extends AbstractSensor {

    public PedometerSensor(Action_Object onDataChanged) {
        super(SensorType.STEP_COUNTER, onDataChanged);
    }

    @Override
    protected SensorData buildData(SensorEvent event) {
        return new SensorData(SensorType.STEP_COUNTER, new float[] {event.values[0], 0.0f, 0.0f});
    }

    @Override
    protected String getSensorName() {
        return "Pedometer";
    }

}