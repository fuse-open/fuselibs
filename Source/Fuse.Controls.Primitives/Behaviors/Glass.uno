using Uno;
using Uno.Graphics;
using Uno.UX;
using Fuse.Common;
using Fuse.Elements;
using Fuse.Controls;

namespace Fuse.Effects
{
	/** Applies a glass backdrop effect to an @Element.

	The following example displays a glass effect.
	```xml
		<ClientPanel>
			<Panel Width="150" Height="70" Alignment="Center">
				<Glass Radius="10" />
			</Panel>
			<Image ux:Name="image" Alignment="Center" Margin="20" Background="Purple" Url="https://fuseopen.com/assets/white-logo.png" />
		</ClientPanel>
	```
	We need to set the `Background` property of the `Glass` behavior to the Element that will act as a background so it will get blurred out.
	If we don't set it, The `Glass` behavior will try to find the background from the sibling element where `Glass` behavior is attached

	*/
	public class Glass : Behavior, IPropertyListener
	{
		Element _elementParent;
		Element _element;
		FrostedGlass _frostedGlass;

		/** The Element as a background that will be blurred out */
		public Element Background
		{
			get; set;
		}

		float3 _lumaRange = float3(1,1,1);
		public float3 LumaRange
		{
			get
			{
				return _lumaRange;
			}
			set
			{
				if (_lumaRange != value)
				{
					_lumaRange = value;
					if (_frostedGlass != null)
						_frostedGlass.LumaRange = _lumaRange;
				}
			}
		}

		float _radius = 3;
		/** The radius/size of the blur */
		public float Radius
		{
			get
			{
				return _radius;
			}
			set
			{
				if (_radius != value)
				{
					_radius = value;
					if (_frostedGlass != null)
						_frostedGlass.Radius = _radius;
				}
			}
		}

		void AddDecoration()
		{
			if (_elementParent is Circle)
			{
				_element = new Circle
				{
					Color = Uno.Color.FromRgba(0xFFFFFFFF)
				};
			}
			else
			{
				var rectParent = _elementParent as Rectangle;
				var cornerRadius = float4(0);
				if (rectParent != null)
					cornerRadius = rectParent.CornerRadius;

				_element = new Rectangle
				{
					CornerRadius = cornerRadius,
					Color = Uno.Color.FromRgba(0xFFFFFFFF)
				};
			}
			_element.Width = new Size(100, Unit.Percent);
			_element.Height = new Size(100, Unit.Percent);
			_element.Layer = Layer.Underlay;

			_frostedGlass = new FrostedGlass
			{
				Background = Background,
				Radius = Radius,
				LumaRange = LumaRange,
			};

			_element.Children.Add(_frostedGlass);
			_elementParent.InsertAfter(this, _element);
		}

		void RemoveDecoration()
		{
			if (_element == null)
				throw new Exception("Invalid rectangle-state");

			_element.Children.Remove(_frostedGlass);
			_frostedGlass = null;
			_element = null;
		}

		Element FindBackground(Visual visual)
		{
			if (visual == null)
				return visual as Element;
			return visual.NextSibling<Element>() ?? visual.PreviousSibling<Element>() ?? FindBackground(visual.Parent);
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			_elementParent = Parent as Element;
			if (_elementParent == null)
				throw new Exception("Invalid parent for Effect: " + Parent);
			_elementParent.AddPropertyListener(this);

			Background = Background ?? FindBackground(_elementParent as Visual);
			if (Background == null)
				throw new Exception("Background property value is missing");

			AddDecoration();

			// listen to the tranformation changes of the background element or the element where the Glass effect has been installed
			_elementParent.WorldTransformInvalidated += OnTransform;
			Background.WorldTransformInvalidated += OnTransform;
		}

		protected override void OnUnrooted()
		{
			RemoveDecoration();

			Background.WorldTransformInvalidated -= OnTransform;
			Background = null;

			_elementParent.RemovePropertyListener(this);
			_elementParent.WorldTransformInvalidated -= OnTransform;
			_elementParent = null;

			base.OnUnrooted();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject sender, Selector property)
		{
			if (_element != null)
			{
				if (property == Rectangle.CornerRadiusPropertyName)
				{
					var rect = _element as Rectangle;
					var rectParent =  _elementParent as Rectangle;
					rect.CornerRadius = rectParent.CornerRadius;
					_element.InvalidateVisual();
				}
			}
		}

		void OnTransform(object sender, EventArgs args)
		{
			_element.InvalidateVisual();
		}

	}

	internal sealed class FrostedGlass : BasicEffect
	{
		public FrostedGlass() :
			base(EffectType.Composition)
		{
			Radius = 3;
			LumaRange = float3(1,1,1);
		}

		public Element Background
		{
			get; set;
		}

		float3 _lumaRange;
		public float3 LumaRange
		{
			get { return _lumaRange; }
			set
			{
				if (_lumaRange != value)
				{
					_lumaRange = value;

					OnRenderingChanged();
					OnRenderBoundsChanged();
				}
			}
		}

		float _radius;
		public float Radius
		{
			get { return _radius; }
			set
			{
				if (_radius != value)
				{
					_radius = value;

					OnRenderingChanged();
					OnRenderBoundsChanged();
				}
			}
		}

		public override bool Active { get { return Radius > 0; } }

		public override VisualBounds ModifyRenderBounds( VisualBounds inBounds )
		{
			return inBounds.InflateXY(Padding);
		}

		internal float Sigma { get { return Math.Max(Radius, 1e-5f); } }
		internal float Padding { get { return 0; } }

		protected override void OnRender(DrawContext dc, Rect elementRect)
		{
			var bg = Background;
			var paddedRect = elementRect;

			var pe = Element.WorldPosition;
			var pb = bg.WorldPosition;
			var left = paddedRect.Left + pe.X - pb.X;
			var top = paddedRect.Top + pe.Y - pb.Y;
			var bottom = top + paddedRect.Height;
			var right = left + paddedRect.Width;

			paddedRect = new Rect(left, top, right, bottom);

			var blurRegion = bg.CaptureRegion(dc, paddedRect, int2(0));
			if (blurRegion == null)
				return;

			var original = Element.CaptureRegion(dc, elementRect, float2(0));
			if (original == null)
				return;

			var blur = EffectHelpers.Instance.Blur(blurRegion.ColorBuffer, dc, Sigma * bg.AbsoluteZoom);
			FramebufferPool.Release(blurRegion);

			draw Fuse.Drawing.Planar.Image
			{
				DrawContext: dc;
				Visual: Element;
				Position: elementRect.Minimum;
				Invert: true;
				Size: elementRect.Size;
				Texture: original.ColorBuffer;

				float4 m: sample(blur.ColorBuffer, TexCoord, Uno.Graphics.SamplerState.LinearClamp);
				PixelColor: TextureColor * float4(m.XYZ * m.W, m.W) * float4(LumaRange, 1);

				apply Fuse.Drawing.PreMultipliedAlphaCompositing;
				DepthTestEnabled: false;
			};

			FramebufferPool.Release(original);
			FramebufferPool.Release(blurRegion);
			FramebufferPool.Release(blur);

			original = null;
			blurRegion = null;
			blur = null;
		}
	}
}