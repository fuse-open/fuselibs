using Uno;
using Uno.UX;

using Fuse;
using Fuse.Drawing;
using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.Controls.Primitives
{
	class ShadowElement : Element, IPropertyListener
	{
		float _minSmoothness;
		Rectangle _rectangleParent;
		Circle _circleParent;

		protected override void OnRooted()
		{
			base.OnRooted();

			_rectangleParent = Parent as Rectangle;
			if (_rectangleParent != null)
				_rectangleParent.AddPropertyListener(this);

			_circleParent = Parent as Circle;

			_minSmoothness = 1.5f / Viewport.PixelsPerPoint;
		}

		protected override void OnUnrooted()
		{
			_minSmoothness = 0;

			if (_rectangleParent != null)
				_rectangleParent.RemovePropertyListener(this);
			_rectangleParent = null;

			_circleParent = null;

			base.OnUnrooted();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (_rectangleParent != null)
			{
				if (prop == Rectangle.CornerRadiusPropertyName)
					InvalidateVisual();
			}
		}

		float _size;
		public float ShadowSize
		{
			get { return _size; }
			set
			{
				if (_size != value)
				{
					_size = value;
					InvalidateVisual();
					InvalidateRenderBounds();
				}
			}
		}

		float4 CornerRadius
		{
			get
			{
				float size = _size;
				if (_rectangleParent != null)
					// This is just a hack that tries to somehow treat these so the most dominant one "wins" through, without simply having a sum. It's not perfect, but works OK.
					return Math.Sqrt(size * size + _rectangleParent.CornerRadius * _rectangleParent.CornerRadius);
				else if (_circleParent != null)
					return float4(_circleParent.Radius + size);
				else
					return float4(size);
			}
		}

		float MaxSize { get { return Math.Min(ActualSize.X, ActualSize.Y); } }

		float Smoothness
		{
			get
			{
				float size = _size + Math.Max(0, _size - MaxSize);
				return Math.Max(size * 2.5f, _minSmoothness);
			}
		}

		float4 _color;

		/**
			Sets the color of the shadow

		 	For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		public float4 Color
		{
			get { return _color; }
			set
			{
				if (_color != value)
				{
					_color = value;
					InvalidateVisual();
				}
			}
		}

		protected override VisualBounds CalcRenderBounds()
		{
			var r = base.CalcRenderBounds();
			r = r.AddRect(float2(0), ActualSize);
			return r.InflateXY(Smoothness - 1);
		}

		SolidColor _fill = new SolidColor();
		protected override void OnDraw(DrawContext dc)
		{
			var alphaFade = 1.0f;

			if (_size > MaxSize)
				alphaFade = MaxSize / _size;

			_fill.Color = float4(_color.XYZ, _color.W * alphaFade);

			var size = ActualSize;
			var offset = float2(0);
			if (_circleParent != null)
			{
				size = float2(_circleParent.Radius * 2, _circleParent.Radius * 2);
				offset = ActualSize / 2 - _circleParent.Radius;
			}

			Fuse.Drawing.Primitives.Rectangle.Singleton.Shadow(dc, this, size, CornerRadius, _fill, offset, Smoothness * Viewport.PixelsPerPoint);
		}
	}
}
