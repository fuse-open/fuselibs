using Uno;
using Uno.Collections;
using Uno.Collections.EnumerableExtensions;
using Uno.Graphics;
using Uno.UX;
using Fuse.Drawing;
using Fuse;

namespace Fuse.Drawing
{
	public sealed class DashedColor : DynamicBrush
	{
		static Selector _colorName = "Color";
		static Selector _dashedSizeName = "DashedSize";

		public DashedColor()
		{
			_color = float4(1);
		}

		public DashedColor(float4 color, float dashedSize)
		{
			_color = color;
			_dashedSize = dashedSize;
		}

		float4 _color;
		public float4 Color
		{
			get { return _color; }
			set
			{
				if (_color != value)
				{
					_color = value;
					OnPropertyChanged(_colorName);
				}
			}
		}

		float _dashedSize = 0;
		public float DashedSize
		{
			get { return _dashedSize; }
			set
			{
				if(_dashedSize != value)
				{
					_dashedSize = value;
					OnPropertyChanged(_dashedSizeName);
				}
			}
		}

		public override bool IsCompletelyTransparent { get { return base.IsCompletelyTransparent || Color.W == 0; } }

		static float Box(float2 p, float2 b)
		{
			float2 d = Math.Abs(p) - b;
			return Math.Min( Math.Max(d.X, d.Y), 0.0f) + Vector.Length(Math.Max(d, 0.0f));
		}

		static float2 Rep(float2 p, float2 c)
		{
			return Math.Mod(p, c) - 0.5f * c;
		}

		float2 p: req(TexCoord as float2) pixel TexCoord.XY * CanvasSize.XY;
		float t:
		{
			float2 nRep = CanvasSize.XY / DashedSize;
			int2 iRep = (int2)nRep;
			if(Math.Mod(iRep.X, 2) == 0)
				++iRep.X;
			if(Math.Mod(iRep.Y, 2) == 0)
				++iRep.Y;

			nRep = CanvasSize.XY / (float2)iRep;
			float t = Box( Rep(p, nRep * 2) + float2(DashedSize), float2(DashedSize) );
			return -Math.Floor(t);
		};
		FinalColor: Math.Lerp(float4(0), Color, Math.Clamp(t, 0.f, 1.f));
	}
}