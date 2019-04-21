package com.fuse.sensorkit;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Build;
import com.foreign.Uno.Action_Object;

public abstract class AbstractSensor {

    private final SensorManager mSensorManager;
    private final Sensor mSensor;
    private final SensorEventListener mSensorEventListener;
    protected boolean isSensing = false;
    private Action_Object onDataChanged;

    public AbstractSensor(final SensorType sensorType, Action_Object onDataChanged) {
        this.onDataChanged = onDataChanged;
        mSensorManager = (SensorManager) com.fuse.Activity.getRootActivity().getSystemService(Context.SENSOR_SERVICE);
        mSensor = mSensorManager.getDefaultSensor(getSensorType(sensorType));

        mSensorEventListener = new SensorEventListener() {

            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {
                // Ignore
            }

            @Override
            public void onSensorChanged(SensorEvent event) {
                SensorData data = buildData(event);
                if (AbstractSensor.this.onDataChanged != null)
                    AbstractSensor.this.onDataChanged.run(data);
            }
        };
    }

    public void start() throws Exception {
        this.isSensing = true;
        boolean status = mSensorManager.registerListener(mSensorEventListener, mSensor, SensorManager.SENSOR_DELAY_NORMAL);
        if (!status) {
            throw new Exception(getSensorName() + " sensor is not available.");
        }
    }

    public void stop() {
        mSensorManager.unregisterListener(mSensorEventListener);
        this.isSensing = false;
    }

    protected abstract SensorData buildData(SensorEvent event);

    protected abstract String getSensorName();

    public boolean isSensing() {
        return isSensing;
    }

    private static int getSensorType(SensorType sensorType) {

        switch (sensorType) {

            case ACCELEROMETER:
                return Sensor.TYPE_ACCELEROMETER;

            case GRAVITY:
                return Sensor.TYPE_GRAVITY;

            case GYROSCOPE:
                return Sensor.TYPE_GYROSCOPE;

            case USER_ACCELERATION:
                return Sensor.TYPE_LINEAR_ACCELERATION;

            case ROTATION:
                return Sensor.TYPE_ROTATION_VECTOR;

            case MAGNETOMETER:
                return Sensor.TYPE_MAGNETIC_FIELD;

            case STEP_COUNTER:
                return Sensor.TYPE_STEP_COUNTER;

            case PRESSURE:
                return Sensor.TYPE_PRESSURE;
        }
        return 0;
    }
}