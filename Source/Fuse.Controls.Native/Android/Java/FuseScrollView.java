package com.fuse.android.views;

import android.widget.FrameLayout;
import android.view.View;
import android.view.ViewGroup;
import android.view.MotionEvent;

public class FuseScrollView extends FrameLayout implements ScrollEventHandler {

	private VerticalScrollView _verticalScrollView = null;
	private HorizontalScrollView _horizontalScrollView = null;
	private ViewGroup _currentScrollView = null;
	private boolean _isHorizontal = false;
	private boolean isScrolling = true;

	public FuseScrollView(android.content.Context context) {
		super(context);
		_currentScrollView = _verticalScrollView = new VerticalScrollView(context);
		_currentScrollView.setClipChildren(false);
		_currentScrollView.setClipToPadding(false);
		_verticalScrollView.setScrollEventHandler(this);
		addView(_currentScrollView);
	}

	public void onScrollChanged(int x, int y, int oldX, int oldY) {
		if (_scrollEventHandler != null)
			_scrollEventHandler.onScrollChanged(x, y, oldX, oldY);
	}

	ScrollEventHandler _scrollEventHandler;

	public void setScrollEventHandler(ScrollEventHandler scrollEventHandler) {
		_scrollEventHandler = scrollEventHandler;
	}

	ScrollInteractionEventHandler _scrollInteractionHandler;

	public void setScrollInteractionEventHandler(ScrollInteractionEventHandler scrollInteractionHandler) {
		_scrollInteractionHandler = scrollInteractionHandler;
	}

	public void setIsHorizontal(boolean isHorizontal) {
		if (_isHorizontal == isHorizontal)
			return;

		_isHorizontal = isHorizontal;

		removeView(_currentScrollView);

		View[] content = getContent();
		if (_isHorizontal) {
			if (_horizontalScrollView == null) {
				_horizontalScrollView = new HorizontalScrollView(getContext());
				_horizontalScrollView.setScrollEventHandler(this);
				_horizontalScrollView.setClipChildren(false);
				_horizontalScrollView.setClipToPadding(false);
			}
			_currentScrollView = _horizontalScrollView;
		} else {
			_currentScrollView = _verticalScrollView;
		}

		addView(_currentScrollView);
		setContent(content);
	}

	View[] getContent() {
		int childCount = _currentScrollView.getChildCount();
		View[] content = new View[childCount];
		for (int i = 0; i < childCount; i++) {
			content[i] = _currentScrollView.getChildAt(i);
		}
		_currentScrollView.removeAllViews();
		return content;
	}

	void setContent(View[] content) {
		for (View view : content) {
			_currentScrollView.addView(view);
		}
	}

	@Override
	public void addView(View child, ViewGroup.LayoutParams params) {
		if (child == _currentScrollView) {
			super.addView(child, params);
		} else {
			_currentScrollView.addView(child, params);
		}
	}

	@Override
	public void addView(View child, int index) {
		if (_currentScrollView == child) {
			super.addView(child, index);
		} else {
			_currentScrollView.addView(child, index);
		}

	}

	@Override
	public void addView(View child) {
		if (child == _currentScrollView) {
			super.addView(child);
		} else {
			_currentScrollView.addView(child);
		}
	}

	@Override
	public void addView(View child, int width, int height) {
		if (_currentScrollView == child) {
			super.addView(child, width, height);
		} else {
			_currentScrollView.addView(child, width, height);
		}
	}

	@Override
	public void removeView(View view) {
		if (_currentScrollView == view) {
			super.removeView(view);
		} else {
			_currentScrollView.removeView(view);
		}
	}

	/*@Override
	public void removeViewAt(int index) {
		_currentScrollView.removeViewAt(index);
	}*/

	@Override
	public void setScrollX(int value) {
		_currentScrollView.setScrollX(value);
	}

	@Override
	public void setScrollY(int value) {
		_currentScrollView.setScrollY(value);
	}

	@Override
	public void setLayoutParams(ViewGroup.LayoutParams params) {
		super.setLayoutParams(params);
		//_currentScrollView.setLayoutParams(new ViewGroup.LayoutParams(params));
	}

	@Override
	public boolean onInterceptTouchEvent(MotionEvent ev) {
		_currentScrollView.onInterceptTouchEvent(ev);
		return true;
	}

	@Override
	public boolean dispatchTouchEvent(MotionEvent ev) {
		_currentScrollView.dispatchTouchEvent(ev);
		return super.dispatchTouchEvent(ev);
	}

	@Override
	public boolean onTouchEvent(MotionEvent ev) {
		if (this.isScrolling) {
			if (_scrollInteractionHandler != null) {
				if (ev.getAction() == MotionEvent.ACTION_DOWN)
					_scrollInteractionHandler.onInteractionChanged(true);
				else if (ev.getAction() == MotionEvent.ACTION_UP || ev.getAction() == MotionEvent.ACTION_CANCEL)
					_scrollInteractionHandler.onInteractionChanged(false);
			}
			return _currentScrollView.onTouchEvent(ev);
		} else {
			return super.onTouchEvent(ev);
		}
	}

	public void smoothScrollTo(int x, int y) {
		if (_currentScrollView instanceof VerticalScrollView)
			((VerticalScrollView)_currentScrollView).smoothScrollTo(x, y);
		else
			((HorizontalScrollView)_currentScrollView).smoothScrollTo(x, y);
	}

	public void setScrolling(boolean isScrolling) {
        this.isScrolling = isScrolling;
    }
}