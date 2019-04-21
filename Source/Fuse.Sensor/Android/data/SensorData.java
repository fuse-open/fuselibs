package com.fuse.sensorkit;

public class SensorData
{
    protected final SensorType moduleType;
    protected final float[] data;

    public SensorData(SensorType moduleType, float[] data) {
        this.moduleType = moduleType;
        this.data = data;
    }

    public SensorType getSensorType() {
        return moduleType;
    }

    public float[] getData() {
        return this.data;
    }
}
