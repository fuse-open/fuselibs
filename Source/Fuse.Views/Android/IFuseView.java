package com.fuse.views.internal;

public interface IFuseView {
    void onMeasure(int widthMeasureSpec, int heightMeasureSpec, int[] result);
    void onSizeChanged(int w, int h, int oldw, int oldh);
    void onLayout(boolean changed, int left, int top, int right, int bottom);
    void onAttachedToWindow();
    void onDetachedFromWindow();
    void setDataJson(String json);
    void setDataString(String key, String value);
    void setCallback(String key, com.fuse.views.ICallback callback);
}