package com.fuse.sensorkit;

import android.os.BatteryManager;
import java.util.Locale;

import static android.os.BatteryManager.*;

public class BatteryData {

    protected final int level;
    protected final int scale;
    protected final int temperature;
    protected final int voltage;
    protected final int plugged;
    protected final int status;
    protected final int health;

    public BatteryData(int level, int scale, int temperature, int voltage, int plugged, int status, int health) {
        this.level = level;
        this.scale = scale;
        this.temperature = temperature;
        this.voltage = voltage;
        this.plugged = plugged;
        this.status = status;
        this.health = health;
    }

    public float getLevelRatio() {

        // Calculate the level: level/scale
        if (level >= 0 && scale > 0) {
            return level / (float)scale;
        }
        else {
            return 0;
        }
    }

    public int getLevel() {
        return this.level;
    }

    public int getScale() {
        return this.scale;
    }

    public int getTemperature() {
        return this.temperature;
    }

    public int getVoltage() {
        return this.voltage;
    }

    public int getPlugged() {
        return this.plugged;
    }

    public int getBatteryStatus() {
        return this.status;
    }

    public int getBatteryHealth() {
        return this.health;
    }

    public String getPluggedString() {
        return getPluggedString(this.plugged);
    }

    public String getBatteryStatusString() {
        return getBatteryStatusString(this.status);
    }

    public String getBatteryHealthString() {
        return getBatteryHealthString(this.health);
    }

    private static String getPluggedString(int pluggedType) {

        switch (pluggedType) {

            case BATTERY_PLUGGED_USB:
                return "usb";

            case BATTERY_PLUGGED_AC:
                return "ac";

            case BATTERY_PLUGGED_WIRELESS:
                return "wireless";

            default:
                return "unknown";
        }
    }

    private static String getBatteryStatusString(int status) {

        switch (status) {

            case BatteryManager.BATTERY_STATUS_CHARGING:
                return "charging";

            case BatteryManager.BATTERY_STATUS_DISCHARGING:
                return "Unplugged";

            case BatteryManager.BATTERY_STATUS_FULL:
                return "full";

            case BatteryManager.BATTERY_STATUS_NOT_CHARGING:
                return "not Charging";

            case BatteryManager.BATTERY_STATUS_UNKNOWN:
                return "unknown";

            default:
                return "unsupported";
        }
    }

    private String getBatteryHealthString(int health) {

        switch (health) {

            case BatteryManager.BATTERY_HEALTH_COLD:
                return "cold";

            case BatteryManager.BATTERY_HEALTH_DEAD:
                return "dead";

            case BatteryManager.BATTERY_HEALTH_GOOD:
                return "good";

            case BatteryManager.BATTERY_HEALTH_OVERHEAT:
                return "over heat";

            case BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE:
                return "over voltage";

            case BatteryManager.BATTERY_HEALTH_UNKNOWN:
                return "unknown";

            case BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE:
                return "failure";

            default:
                return "unsupported";
        }
    }
}