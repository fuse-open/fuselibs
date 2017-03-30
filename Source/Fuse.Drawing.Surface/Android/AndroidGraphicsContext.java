package com.fusetools.drawing.surface;

import android.graphics.Canvas;
import android.graphics.Matrix;

import android.graphics.Bitmap;

public class AndroidGraphicsContext implements ISurfaceContext {
	// the actual canvas we use to draw to
	public Canvas canvas;

	// the underlying bitmap element that gets written to by the canvas
	public Bitmap bitmap;

	// dimensions of the framebuffer at any one point
	public int width;
	public int height;

	// the texture ID given by a framebuffer
	public int glTextureId;

	public void saveCurrentMatrix()
	{
		canvas.save();
	}

	public void restoreCurrentMatrix()
	{
		canvas.restore();
	}

	public Canvas getCanvas() {
		return canvas;
	}
}


