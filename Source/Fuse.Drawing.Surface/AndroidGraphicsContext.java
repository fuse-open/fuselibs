package com.fusetools.drawing.surface;

import android.graphics.Canvas;
import android.graphics.Matrix;

import android.graphics.Bitmap;

public class AndroidGraphicsContext {
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

	// since we need to provide the linear gradient with
	// different stops based on the rotation of the phone
	// this class is used as a holder for all that until the 
	// gradient is actually drawn
	public static class LinearGradientStore
	{
		public int[] colors;
		public float[] stops;


		public String toString()
		{
			return (" " + colors
				+ " " + stops);
		}
	}
}


