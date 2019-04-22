package com.fuse.sensorkit;

public class ConnectionStateData
{
    protected final boolean status;
    protected final String statusString;

    public ConnectionStateData(boolean status, String statusString) {
        this.status = status;
        this.statusString = statusString;
    }

    public boolean getStatus() {
        return this.status;
    }

    public String getStatusString() {
        return this.statusString;
    }
}
