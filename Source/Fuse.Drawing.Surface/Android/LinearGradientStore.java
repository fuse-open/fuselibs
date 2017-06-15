package com.fusetools.drawing.surface;

// since we need to provide the linear gradient with
// different stops based on the rotation of the phone
// this class is used as a holder for all that until the
// gradient is actually drawn
public class LinearGradientStore
{
	public int[] colors;
	public float[] stops;

	public String toString()
	{
		return (" " + colors
			+ " " + stops);
	}
}