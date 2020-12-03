package com.fuse.android.widget;

import android.content.Context;
import android.widget.TimePicker;
import android.app.TimePickerDialog;
import java.lang.reflect.Field;
import android.app.TimePickerDialog.OnTimeSetListener;

public class FuseTimePickerDialog extends TimePickerDialog {

    TimePicker mTimePicker;
    public FuseTimePickerDialog(Context context, OnTimeSetListener listener, int hourOfDay, int minute, boolean is24HourView) {

        super(context, listener, hourOfDay, minute, is24HourView);
        try {
            Class<?> superClass = getClass().getSuperclass();
            Field TimePickerField = superClass.getDeclaredField("mTimePicker");
            TimePickerField.setAccessible(true);
            mTimePicker = (TimePicker) TimePickerField.get(this);
        } catch (NoSuchFieldException | IllegalAccessException e) {
            e.printStackTrace();
        }
    }

    public TimePicker getTimePicker() {
        return mTimePicker;
    }
}