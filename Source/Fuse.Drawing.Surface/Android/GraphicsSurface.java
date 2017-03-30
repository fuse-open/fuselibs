package com.fusetools.drawing.surface;

import android.graphics.Canvas;
import android.graphics.Bitmap;

public class GraphicsSurface implements ISurfaceContext {

	private Canvas canvas;

	public GraphicsSurface() {
		canvas = new Canvas();
	}

	public Canvas getCanvas() {
		return canvas;
	}

	public int width;
	public int height;

	public int glTextureId;

}