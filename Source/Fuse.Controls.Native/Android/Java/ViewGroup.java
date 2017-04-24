package com.fuse.android.views;

public class ViewGroup extends android.widget.FrameLayout {
	
	public boolean HitTestEnabled;

	public ViewGroup(android.content.Context context)
	{
		super(context);
		HitTestEnabled = true;
	}

	public boolean onInterceptTouchEvent(android.view.MotionEvent ev) {
		return !HitTestEnabled;
	}

	public static void UpdateChildRect(android.view.View view, int x, int y, int w, int h) {
		android.widget.FrameLayout.LayoutParams lp = new android.widget.FrameLayout.LayoutParams(w, h);
		lp.setMargins(x, y, 0, 0);
		view.setLayoutParams(lp);
	}

}
