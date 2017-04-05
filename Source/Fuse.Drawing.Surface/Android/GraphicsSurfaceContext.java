package com.fusetools.drawing.surface;

import android.graphics.Canvas;
import android.graphics.Bitmap;

public class GraphicsSurfaceContext {

	public GraphicsSurfaceContext() {
		canvas = new Canvas(); //TODO: wasteful in NativeCase
	}

	//the current Canvas
	public Canvas canvas;

	// the underlying bitmap element that gets written to by the canvas
	public Bitmap bitmap;

	// dimensions of the framebuffer at any one point
	public int width;
	public int height;

	// the texture ID given by a framebuffer
	public int glTextureId;

}