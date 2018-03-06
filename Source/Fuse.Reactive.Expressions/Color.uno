using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	//reference: http://www.easyrgb.com/en/math.php
	static class ColorModel
	{
		static public float4 RgbaToHsla( float4 v ) 
		{
			var r = v[0];
			var g = v[1];
			var b = v[2];

			var min = Math.Min( r, Math.Min( g, b) ); //Min. value of RGB
			var max = Math.Max( r, Math.Max( g, b ) ); //Max. value of RGB
			var del_max = max - min; //Delta RGB value

			var l = ( max + min )/ 2;

			float h = 0;
			float s = 0;
			if ( del_max < 1e-4 ) //This is a gray, no chroma...
			{
				h = 0;
				s = 0;
			}
			else //Chromatic data...
			{
				if ( l < 0.5 ) 
					s = del_max / ( max + min );
				else           
					s = del_max / ( 2 - max - min );

				var del_r = ( ( ( max - r ) / 6 ) + ( del_max / 2 ) ) / del_max;
				var del_g = ( ( ( max - g ) / 6 ) + ( del_max / 2 ) ) / del_max;
				var del_b = ( ( ( max - b ) / 6 ) + ( del_max / 2 ) ) / del_max;

				if (r > g && r > b) //r == max
					h = del_b - del_g;
				else if (g > b) //g == max
					h = ( 1 / 3.0f ) + del_r - del_b;
				else //b == max
					h = ( 2 / 3.0f ) + del_g - del_r;

				if ( h < 0 ) 
					h += 1;
				if ( h > 1 ) 
					h -= 1;
			}
			
			return float4(h,s,l,v[3]);
		}
		
		static public float4 HslaToRgba( float4 v )
		{
			var h = v[0];
			var s = v[1];
			var l = v[2];
			
			float var_2;
			if ( l < 0.5f ) 
				var_2 = l * ( 1.0f + s );
			else           
				var_2 = ( l + s ) - ( s * l );

			var var_1 = 2 * l - var_2;

			var r = Hue_2_RGB( var_1, var_2, h + ( 1.0f / 3.0f ) );
			var g = Hue_2_RGB( var_1, var_2, h );
			var b = Hue_2_RGB( var_1, var_2, h - ( 1.0f / 3.0f ) );
			
			return float4(r,g,b, v[3]);
		}

		static float Hue_2_RGB( float v1, float v2, float vH )
		{
			if ( vH < 0 ) vH += 1;
			if( vH > 1 ) vH -= 1;
			if ( ( 6 * vH ) < 1 ) return ( v1 + ( v2 - v1 ) * 6 * vH );
			if ( ( 2 * vH ) < 1 ) return ( v2 );
			if ( ( 3 * vH ) < 2 ) return ( v1 + ( v2 - v1 ) * ( ( 2 / 3.0f ) - vH ) * 6 );
			return ( v1 );
		}
	}

	/**
		Functions for modifying color values.
		
		Colors in Fuse are represented as RGBA values. A `float3` converts to a `float4` by having a `1` implicitly added as the alpha value. Hex strings can also convert to color values.
		
		Most of the operations are calculated in HSL color space, first by converting the RGB value to HSL, performing the operation, and converting back to RGB.  The alpha value is not modified by RGB <=> HSL conversions.
		
		Clamping is, in general, not done on the inputs, intermediaries, or outputs. This means you may end up with RGB values outside of the 0..1 range. This ensures that color information is not prematurely lost when performing multiplate operations.
		
		[subclass Fuse.Reactive.BinaryColorFunction]
		
		To work directly with HSL values you can use the `hslaToRgba` and `rgbaToHsla` functions.
	*/
	public abstract class BinaryColorFunction : BinaryOperator
	{
		internal BinaryColorFunction(Expression color, Expression value, String name): 
			base(color, value, name) {}
			
		protected override bool TryCompute(object color_, object value_, out object result)
		{
			result = null;
			
			float4 color = float4(0);
			float value = 0;
			if (!Marshal.TryToColorFloat4( color_, out color ) ||
				!Marshal.TryToType<float>( value_, out value ))
				return false;
				
			result = ColorCompute(color, value);
			return true;
		}
		
		internal abstract float4 ColorCompute(float4 color, float value);
	}
	
	/**
		Reduces the lightness of a color.
		
		This subtracts the lightness value in HSL color space.
		
		The result is not clamped; refer to @BinaryColorFunction.
	*/
	[UXFunction("darken")]
	public sealed class DarkenFunction : BinaryColorFunction
	{
		[UXConstructor]
		public DarkenFunction([UXParameter("Color")] Expression color,
			[UXParameter("Lightness")] Expression lightness) : 
			base(color, lightness, "darken") {}
			
		internal override float4 ColorCompute(float4 color, float value)
		{
			var h = ColorModel.RgbaToHsla(color);
			h[2] -= value;
			return ColorModel.HslaToRgba(h);
		}
	}
	
	/**
		Increases the lightness of a color.
		
		This adds the lightness value in HSL color space.
		
		The result is not clamped; refer to @BinaryColorFunction.
	*/
	[UXFunction("lighten")]
	public sealed class LightenFunction : BinaryColorFunction
	{
		[UXConstructor]
		public LightenFunction([UXParameter("Color")] Expression color, 
			[UXParameter("Lightness")] Expression lightness) : 
			base(color, lightness, "lighten") {}
			
		internal override float4 ColorCompute(float4 color, float value)
		{
			var h = ColorModel.RgbaToHsla(color);
			h[2] += value;
			return ColorModel.HslaToRgba(h);
		}
	}

	/**
		Decreases the saturation of a color.
		
		This subtracts the saturation value in HSL color space.
		
		The result is not clamped; refer to @BinaryColorFunction.
	*/
	[UXFunction("desaturate")]
	public sealed class DesaturateFunction : BinaryColorFunction
	{
		[UXConstructor]
		public DesaturateFunction([UXParameter("Color")] Expression color, 
			[UXParameter("Saturation")] Expression saturation) : 
			base(color, saturation, "desaturate") {}
			
		internal override float4 ColorCompute(float4 color, float value)
		{
			var h = ColorModel.RgbaToHsla(color);
			h[1] -= value;
			return ColorModel.HslaToRgba(h);
		}
	}

	/**
		Increases the saturation of a color.
		
		This adds the saturation value in HSL color space.
		
		The result is not clamped; refer to @BinaryColorFunction.
	*/
	[UXFunction("saturate")]
	public sealed class SaturateFunction : BinaryColorFunction
	{
		[UXConstructor]
		public SaturateFunction([UXParameter("Color")] Expression color, 
			[UXParameter("Saturation")] Expression saturation) :
			base(color, saturation, "saturate") {}
			
		internal override float4 ColorCompute(float4 color, float value)
		{
			var h = ColorModel.RgbaToHsla(color);
			h[1] += value;
			return ColorModel.HslaToRgba(h);
		}
	}
	
	/**
		Scales the saturation of the color towards full or none.
		
		Positive values from 0..1 lerp between the current saturation and `1`.
		Negative values from 0..1 lerp between the current saturation and `0`.
		
		The scaling is done in HSL color space.
	*/
	[UXFunction("scaleSaturation")]
	public sealed class ScaleSaturationFunction : BinaryColorFunction
	{
		[UXConstructor]
		public ScaleSaturationFunction([UXParameter("Color")] Expression color, 
			[UXParameter("Factor")] Expression factor) : 
			base(color, factor, "scaleSaturation") {}
			
		internal override float4 ColorCompute(float4 color, float value)
		{
			var h = ColorModel.RgbaToHsla(color);
			h[1] = value < 0 ? Math.Lerp(h[1],0.0f,-value) : Math.Lerp(h[1],1.0f,value);
			return ColorModel.HslaToRgba(h);
		}
	}
	
	/**
		Scales the lightness of the color towards white or black.
		
		Positive values from 0..1 lerp between the current lightness and `1`.
		Negative values from 0..1 lerp between the current ligthness and `0`.
		
		The scaling is done in HSL color space.
	*/
	[UXFunction("scaleLightness")]
	public sealed class ScaleLightnessFunction : BinaryColorFunction
	{
		[UXConstructor]
		public ScaleLightnessFunction([UXParameter("Color")] Expression color, 
			[UXParameter("Factor")] Expression factor) :
			base(color, factor, "scaleLightness") {}
			
		internal override float4 ColorCompute(float4 color, float value)
		{
			var h = ColorModel.RgbaToHsla(color);
			h[2] = value < 0 ? Math.Lerp(h[2],0.0f,-value) : Math.Lerp(h[2],1.0f,value);
			return ColorModel.HslaToRgba(h);
		}
	}
	
	/**
		Adjusts the hue of the color.
		
		This adds the hue value to the hue in HSL color space. It is wrapped around to remain in the range 0..1.
	*/
	[UXFunction("adjustHue")]
	public sealed class AdjustHueFunction : BinaryColorFunction
	{
		[UXConstructor]
		public AdjustHueFunction([UXParameter("Color")] Expression color, 
			[UXParameter("Hue")] Expression hue) : 
			base(color, hue, "adjustHue" ) { }
			
		internal override float4 ColorCompute(float4 color, float value)
		{
			var h = ColorModel.RgbaToHsla(color);
			h[0] = Math.Mod( h[0] + value, 1 );
			return ColorModel.HslaToRgba(h);
		}
	}

	/**
		Converts a color from RGBA to HSLA color space.
		
		The result is a float4 with this format:
		
			float4( hue, saturation, lightness, alpha )
		
		Values in HSL are normalized just like in RGB. Hue is 0..1, covering the range 0° to 360°. Saturation and lightness are 0..1. Alpha is 0..1 is copied from the input RGBA value.
	*/
	[UXFunction("rgbaToHsla")]
	public sealed class RgbaToHslaFunction : UnaryOperator
	{
		[UXConstructor]
		public RgbaToHslaFunction([UXParameter("RGBA")] Expression color): 
			base(color, "rgbaToHsla") {}
			
		protected override bool TryCompute(object color_, out object result)
		{
			result = null;
			
			float4 color = float4(0);
			if (!Marshal.TryToColorFloat4( color_, out color ))
				return false;
				
			result = ColorModel.RgbaToHsla(color);
			return true;
		}
	}
	
	/**
		Converts a color from HSLA to RGBA.
		
		See @RgbaToHslaFunction for notes on the format.
	*/
	[UXFunction("hslaToRgba")]
	public sealed class HslaToRgbaFunction : UnaryOperator
	{
		[UXConstructor]
		public HslaToRgbaFunction([UXParameter("HSLA")] Expression color): 
			base(color, "hslaToRgba") {}
			
		protected override bool TryCompute(object color_, out object result)
		{
			result = null;
			
			float4 color = float4(0);
			if (!Marshal.TryToColorFloat4( color_, out color ))
				return false;
				
			result = ColorModel.HslaToRgba(color);
			return true;
		}
	}
}