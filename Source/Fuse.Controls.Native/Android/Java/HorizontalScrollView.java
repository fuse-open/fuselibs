package com.fuse.android.views;

public class HorizontalScrollView extends android.widget.HorizontalScrollView {
	
	public HorizontalScrollView(android.content.Context context)
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
}
