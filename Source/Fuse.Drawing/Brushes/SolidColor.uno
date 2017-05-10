using Uno;
using Uno.Math;
using Uno.Graphics;
using Uno.UX;

namespace Fuse.Drawing
{
	public interface ISolidColor
	{
		float4 Color { get; }
	}

	public sealed class SolidColor: DynamicBrush, ISolidColor
	{
		static Selector _colorName = "Color";

		float4 _color;
		/**
			Sets the color used for drawing

		 	For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		[UXOriginSetter("SetColor")]
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

		public void SetColor(float4 c, IPropertyListener origin)
		{
			if (_color != c)
			{
				_color = c;
				OnPropertyChanged(_colorName, origin);
			}
		}

		// Needed for data binding
		internal void SetColor(float4 c)
		{
			Color = c;
		}

		public override bool IsCompletelyTransparent { get { return base.IsCompletelyTransparent || Color.W == 0; } }

		FinalColor : float4(Color.XYZ*Color.W, Color.W);

		public SolidColor()
		{
			_color = float4(1);
		}

		public SolidColor(float4 color)
		{
			_color = color;
		}
	}

	public sealed class StaticSolidColor: StaticBrush, ISolidColor
	{
		public override bool IsCompletelyTransparent { get { return base.IsCompletelyTransparent || Color.W == 0; } }

		float4 _color;
		public float4 Color
		{
			get { return _color; }
		}

		FinalColor : float4(Color.XYZ*Color.W, Color.W);

		[UXConstructor]
		public StaticSolidColor([UXParameter("Color")] float4 color)
		{
			_color = color;
		}
	}
}