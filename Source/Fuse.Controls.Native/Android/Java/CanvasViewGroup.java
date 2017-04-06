package com.fuse.android.views;

public class CanvasViewGroup extends ViewGroup {

	public interface DrawListener {
		void onDraw(android.graphics.Canvas canvas);
	}

	public CanvasViewGroup(android.content.Context context) {
		super(context);
	}

	DrawListener _drawListener;

	public void setDrawListener(DrawListener drawListener) {
		_drawListener = drawListener;
	}

	@Override
	protected void onDraw(android.graphics.Canvas canvas) {
		if (_drawListener != null) {
			_drawListener.onDraw(canvas);
		}
	}
}
