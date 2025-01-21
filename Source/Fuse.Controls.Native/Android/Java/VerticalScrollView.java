package com.fuse.android.views;

import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.content.Context;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.animation.Interpolator;

import androidx.annotation.NonNull;

public class VerticalScrollView extends android.widget.ScrollView {

	private static final int MAX_Y_OVERSCROLL_DISTANCE = 50;
	private static final float DEFAULT_DAMPING_COEFFICIENT = 4.0f;
	private static final long DEFAULT_BOUNCE_DELAY = 400;

	private float mDamping;
	private boolean mIncrementalDamping;
	private long mBounceDelay;
	private boolean mDisableBounceStart;
	private boolean mDisableBounceEnd;

	private final Interpolator mInterpolator;
	private View mChildView;
	private float mStart;
	private int mOverScrolledDistance;
	private ObjectAnimator mAnimator;
	private FuseScrollView.OnOverScrollListener mOverScrollListener;
	private int mMaxYOverscrollDistance;

	public VerticalScrollView(Context context) {
		super(context);
		this.mDamping = DEFAULT_DAMPING_COEFFICIENT;
		this.mIncrementalDamping = true;
		this.mBounceDelay = DEFAULT_BOUNCE_DELAY;

		this.setVerticalScrollBarEnabled(false);
		this.setHorizontalScrollBarEnabled(false);
		this.setFillViewport(true);

		this.mInterpolator = new FuseScrollView.DefaultQuartOutInterpolator();
		initBounceScrollView(context);
	}

	private void initBounceScrollView(Context context) {
		final DisplayMetrics metrics = context.getResources().getDisplayMetrics();
		final float density = metrics.density;
		this.mMaxYOverscrollDistance = (int) (density * MAX_Y_OVERSCROLL_DISTANCE);
	}

	@Override
	protected boolean overScrollBy(int deltaX, int deltaY, int scrollX, int scrollY,
									int scrollRangeX, int scrollRangeY,
									int maxOverScrollX, int maxOverScrollY,
									boolean isTouchEvent) {
		int offset = mChildView.getMeasuredHeight() - getHeight();
		offset = Math.max(offset, 0);
		int overScrollDistance = mMaxYOverscrollDistance;
		if (deltaY < 0 && scrollY == 0 && mDisableBounceStart)
			overScrollDistance = 0;
		else if (deltaY > 0 && scrollY == offset && mDisableBounceEnd)
			overScrollDistance = 0;
		return super.overScrollBy(deltaX, deltaY, scrollX, scrollY,
									scrollRangeX, scrollRangeY,
									maxOverScrollX, overScrollDistance,
									isTouchEvent);
	}

	@Override
	public boolean onInterceptTouchEvent(MotionEvent ev) {
		if (this.mChildView == null && getChildCount() > 0 || mChildView != getChildAt(0)) {
			this.mChildView = getChildAt(0);
		}
		return super.onInterceptTouchEvent(ev);
	}

	@Override
	public boolean onTouchEvent(MotionEvent ev) {
		if (this.mChildView == null)
			return super.onTouchEvent(ev);

		switch (ev.getActionMasked()) {
			case MotionEvent.ACTION_DOWN:
				this.mStart = ev.getY();

				break;
			case MotionEvent.ACTION_MOVE:
				float now, delta;
				int dampingDelta;

				now = ev.getY();
				delta = mStart - now;
				dampingDelta = (int) (delta / calculateDamping());
				this.mStart = now;

				if (canMove(dampingDelta)) {
					this.mOverScrolledDistance += dampingDelta;
					this.mChildView.setTranslationY(-this.mOverScrolledDistance);
					if (this.mOverScrollListener != null) {
						this.mOverScrollListener.onOverScrolling(this.mOverScrolledDistance <= 0, Math.abs(this.mOverScrolledDistance));
					}
				}

				break;
			case MotionEvent.ACTION_UP:
			case MotionEvent.ACTION_CANCEL:
				this.mOverScrolledDistance = 0;

				cancelAnimator();
				this.mAnimator = ObjectAnimator.ofFloat(mChildView, View.TRANSLATION_Y, 0);
				this.mAnimator.setDuration(mBounceDelay).setInterpolator(mInterpolator);
				if (this.mOverScrollListener != null) {
					this.mAnimator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
						@Override
						public void onAnimationUpdate(@NonNull ValueAnimator animation) {
							float value = (float) animation.getAnimatedValue();
							mOverScrollListener.onOverScrolling(value <= 0, Math.abs((int) value));
						}
					});
				}
				this.mAnimator.start();

				break;
		}

		return super.onTouchEvent(ev);
	}

	private float calculateDamping() {
		float ratio;
		ratio = Math.abs(mChildView.getTranslationY()) / mChildView.getMeasuredHeight();
		ratio += 0.2F;
		if (this.mIncrementalDamping) {
			return this.mDamping / (1.0f - (float) Math.pow(ratio, 2));
		} else {
			return this.mDamping;
		}
	}

	private boolean canMove(int delta) {
		return delta < 0 ? canMoveFromStart() : canMoveFromEnd();
	}

	private boolean canMoveFromStart() {
		return getScrollY() == 0 && !isDisableBounceStart();
	}

	private boolean canMoveFromEnd() {
		int offset = mChildView.getMeasuredHeight() - getHeight();
		offset = Math.max(offset, 0);
		return getScrollY() == offset && !isDisableBounceEnd();
	}

	private void cancelAnimator() {
		if (this.mAnimator != null && this.mAnimator.isRunning()) {
			this.mAnimator.cancel();
		}
	}

	ScrollEventHandler _scrollEventHandler;

	public void setScrollEventHandler(ScrollEventHandler scrollEventhandler) {
		_scrollEventHandler = scrollEventhandler;
	}

	protected void onScrollChanged(int l, int t, int oldl, int oldt) {
		if (_scrollEventHandler != null) {
			_scrollEventHandler.onScrollChanged(l, t, oldl, oldt);
		}
		super.onScrollChanged(l, t, oldl, oldt);
	}

	public void draw(android.graphics.Canvas canvas)
	{
		boolean clipChildren = getClipChildren();
		if (clipChildren)
		{
			int x = getScrollX();
			int y = getScrollY();
			int w = getWidth() + x;
			int h = getHeight() + y;
			android.graphics.Rect rect = new android.graphics.Rect(x, y, w, h);
			canvas.clipRect(rect);
		}
		super.draw(canvas);
	}

	public boolean isDisableBounceStart() {
		return mDisableBounceStart;
	}

	public void setDisableBounceStart(boolean disableBounceStart) {
		this.mDisableBounceStart = disableBounceStart;
	}

	public boolean isDisableBounceEnd() {
		return mDisableBounceEnd;
	}

	public void setDisableBounceEnd(boolean disableBounceEnd) {
		this.mDisableBounceEnd = disableBounceEnd;
	}

}