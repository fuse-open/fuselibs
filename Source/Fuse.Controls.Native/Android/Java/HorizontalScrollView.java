package com.fuse.android.views;

public class HorizontalScrollView extends android.widget.HorizontalScrollView {

	public HorizontalScrollView(android.content.Context context) {
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
}
