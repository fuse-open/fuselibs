package com.fuse.android.views;

public class VerticalScrollView extends android.widget.ScrollView {

	public VerticalScrollView(android.content.Context context) {
		super(context);
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

}