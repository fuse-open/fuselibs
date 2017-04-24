package com.fuse.android.views;

public class VerticalScrollView extends android.widget.ScrollView {
	
	public VerticalScrollView(android.content.Context context)
	{
		super(context);
		_scroll = new java.util.ArrayList<IScroll>();
	}

	public void SetIScroll(IScroll scroll)
	{
		_scroll.add(scroll);
	}

	public  void RemoveIScroll(IScroll scroll)
	{
		_scroll.remove(scroll);
	}

	java.util.ArrayList<IScroll> _scroll;

	protected void onScrollChanged(int l, int t, int oldl, int oldt)
	{
		for (int i = 0; i < _scroll.size(); i++)
		{
			_scroll.get(i).OnScrollChanged(l, t, oldl, oldt);
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