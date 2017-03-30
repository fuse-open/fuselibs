package com.fusetools.drawing.surface;

import android.graphics.Canvas;
import android.graphics.Bitmap;

public class GraphicsSurfaceContext implements ISurfaceContext {

	private Canvas canvas;

	public GraphicsSurfaceContext() {
		canvas = new Canvas();
	}

	public Canvas getCanvas() {
		return canvas;
	}

	// the underlying bitmap element that gets written to by the canvas
	public Bitmap bitmap;

	// dimensions of the framebuffer at any one point
	public int width;
	public int height;

	// the texture ID given by a framebuffer
	public int glTextureId;

}