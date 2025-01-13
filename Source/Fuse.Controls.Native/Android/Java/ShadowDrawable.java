package com.fuse.android.graphics;

import android.content.Context;
import android.graphics.BlurMaskFilter;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ColorFilter;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.drawable.Drawable;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


public class ShadowDrawable extends Drawable {

    private final Context context;
    private final Paint shadowPaint;
    private int shadowColor;
    private int offsetX;
    private int offsetY;
    private int size;
    private float[] cornerRadius =  {0,0,0,0,0,0,0,0};
    private boolean isCircle = false;

    public ShadowDrawable(Context context, int shadowColor, int offsetX, int offsetY, int size) {
        this.context = context;
        this.shadowColor = shadowColor;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
        this.size = size;
        shadowPaint = new Paint();
        shadowPaint.setColor(shadowColor);
        if (size > 0)
            shadowPaint.setMaskFilter(new BlurMaskFilter(convertDpToPx(this.size), BlurMaskFilter.Blur.NORMAL));
    }

    @Override
    public void draw(@NonNull Canvas canvas) {
        int count = canvas.save();
        drawShadow(canvas);
        canvas.restoreToCount(count);
    }

    @Override
    public void setAlpha(int alpha) {
        float result = ((alpha / 255f) * (Color.alpha(this.shadowColor) / 255f)) * 255f;
        shadowPaint.setAlpha((int)result);
        invalidateSelf();
    }

    @Override
    public void setColorFilter(@Nullable ColorFilter colorFilter) {
        shadowPaint.setColorFilter(colorFilter);
        invalidateSelf();
    }

    @Override
    public int getOpacity() {
        int alpha = shadowPaint.getAlpha();
        if (alpha == 255)
            return PixelFormat.OPAQUE;
        else if (alpha >= 1 && alpha <= 254)
            return PixelFormat.TRANSLUCENT;
        return PixelFormat.TRANSPARENT;
    }

    public void setColor(int color) {
        if (color != getColor()) {
            this.shadowColor = color;
            shadowPaint.setColor(color);
            invalidateSelf();
        }
    }

    public int getColor() {
        return this.shadowColor;
    }

    public void setSize(int size) {
        if (size != getSize()) {
            this.size = size;
            if (size > 0)
                shadowPaint.setMaskFilter(new BlurMaskFilter(convertDpToPx(this.size), BlurMaskFilter.Blur.NORMAL));
            invalidateSelf();
        }
    }

    public int getSize() {
        return this.size;
    }

    public void setOffsetX(int offsetX) {
        if (offsetX != getOffsetX()) {
            this.offsetX = offsetX;
            invalidateSelf();
        }
    }

    public int getOffsetX() {
        return this.offsetX;
    }

    public void setOffsetY(int offsetY) {
        if (offsetY != getOffsetY()) {
            this.offsetY = offsetY;
            invalidateSelf();
        }
    }

    public int getOffsetY() {
        return this.offsetY;
    }

    private void drawShadow(Canvas canvas) {
        Path shadowPath = new Path();
        if (this.isCircle) {
            Rect bounds= getBounds();
            float x = ((float) bounds.width() / 2) + this.offsetX;
            float y = ((float) bounds.width() / 2) + this.offsetY;
            float radius = ((float) bounds.width() / 2) + this.size;
            shadowPath.addCircle(x, y,  radius, Path.Direction.CW);
        } else {
            int spreadExtent = size;
            RectF shadowRect = new RectF(getBounds());
            shadowRect.inset(-spreadExtent, -spreadExtent);
            shadowRect.offset(offsetX, offsetY);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                RectF subpixelInsetBounds = new RectF(getBounds());
                subpixelInsetBounds.inset(0.4f, 0.4f);
                Path clipPath = new Path();
                clipPath.addRoundRect(subpixelInsetBounds, this.cornerRadius,
                        Path.Direction.CW);
                canvas.clipOutPath(clipPath);
            }
            shadowPath.addRoundRect(shadowRect, this.cornerRadius, Path.Direction.CW);
        }
        canvas.drawPath(shadowPath, shadowPaint);
    }

    private int convertDpToPx(int dp) {
        float density = context.getResources().getDisplayMetrics().density;
        return Math.round(dp * density);
    }

    public void setCircle(boolean circle) {
        this.isCircle = circle;
        invalidateSelf();
    }

    public void setCornerRadius(float[] cornerRadius) {
        this.cornerRadius[0] = cornerRadius[0] * context.getResources().getDisplayMetrics().density;
        this.cornerRadius[1] = cornerRadius[0] * context.getResources().getDisplayMetrics().density;
        this.cornerRadius[2] = cornerRadius[1] * context.getResources().getDisplayMetrics().density;
        this.cornerRadius[3] = cornerRadius[1] * context.getResources().getDisplayMetrics().density;
        this.cornerRadius[4] = cornerRadius[2] * context.getResources().getDisplayMetrics().density;
        this.cornerRadius[5] = cornerRadius[2] * context.getResources().getDisplayMetrics().density;
        this.cornerRadius[6] = cornerRadius[3] * context.getResources().getDisplayMetrics().density;
        this.cornerRadius[7] = cornerRadius[3] * context.getResources().getDisplayMetrics().density;
        invalidateSelf();
    }
}
