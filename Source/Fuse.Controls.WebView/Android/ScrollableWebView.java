package com.fusetools.webview;

import android.webkit.WebView;
import android.content.Context;

public class ScrollableWebView extends WebView
{
    private boolean allowScroll = true;

    public ScrollableWebView(Context context)
    {
        super(context);
    }

    @Override
    protected boolean overScrollBy(int deltaX, int deltaY, int scrollX, int scrollY,
                                   int scrollRangeX, int scrollRangeY, int maxOverScrollX,
                                   int maxOverScrollY, boolean isTouchEvent) {
        if (allowScroll)
            return super.overScrollBy(deltaX, deltaY, scrollX, scrollY,
                    scrollRangeX, scrollRangeY, maxOverScrollX, maxOverScrollY, isTouchEvent);
        return false;
    }

    public void setAllowScroll(boolean allowScroll)
    {
        this.allowScroll = allowScroll;
        setHorizontalScrollBarEnabled(allowScroll);
        setVerticalScrollBarEnabled(allowScroll);
    }

    @Override
    public void flingScroll(int vx, int vy)
    {
        if (allowScroll)
            super.flingScroll(vx,vy);
    }

    @Override
    protected void onScrollChanged(int l, int t, int oldl, int oldt)
    {
        if (allowScroll)
            super.onScrollChanged(l, t, oldl, oldt);
    }

    @Override
    public void scrollTo(int x, int y)
    {
        if (allowScroll)
            super.scrollTo(x,y);
    }

    @Override
    public void scrollBy(int x, int y)
    {
        if (allowScroll)
            super.scrollBy(x,y);
    }

    @Override
    public void computeScroll()
    {
        if (allowScroll)
            super.computeScroll();
    }
}