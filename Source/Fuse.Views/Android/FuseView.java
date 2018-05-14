package com.fuse.views.internal;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

public class FuseView extends FrameLayout {

    private IFuseView _fuseView;

    public FuseView(Context context, IFuseView fuseView) {
        super(context);
        _fuseView = fuseView;
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        int[] result = new int[2];
        _fuseView.onMeasure(widthMeasureSpec, heightMeasureSpec, result);
        setMeasuredDimension(result[0], result[1]);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        _fuseView.onSizeChanged(w, h, oldw, oldh);
    }

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        super.onLayout(changed, left, top, right, bottom);
        _fuseView.onLayout(changed, left, top, right, bottom);
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        _fuseView.onAttachedToWindow();
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        _fuseView.onDetachedFromWindow();
    }

    public void setDataJson(String json) {
        _fuseView.setDataJson(json);
    }

    public void setDataString(String key, String value) {
        _fuseView.setDataString(key, value);
    }

    public void setCallback(String key, com.fuse.views.ICallback callback) {
        _fuseView.setCallback(key, callback);
    }

}
