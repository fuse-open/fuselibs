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

	<ClientPanel>
		<Panel Width="150" Height="70" Alignment="Center">
			<Glass Radius="10" />
		</Panel>
		<Image ux:Name="image" Alignment="Center" Margin="20" Background="Purple" Url="https://fuseopen.com/assets/white-logo.png" />
	</ClientPanel>

	We need to set the `Background` property of the `Glass` behavior to the Element that will act as a background so it will get blurred out.
	If we don't set it, The `Glass` behavior will try to find the background from the sibling element where `Glass` behavior is attached

	*/
	public class Glass : Behavior
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

		float3 _lumaAdd;
		public float3 LumaAdd
		{
			get
			{
				return _lumaAdd;
			}
			set
			{
				if (_lumaAdd != value)
				{
					_lumaAdd = value;
					if (_frostedGlass != null)
						_frostedGlass.LumaAdd = _lumaAdd;
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
			_element = new Rectangle
			{
				Width = new Size(100, Unit.Percent),
				Height = new Size(100, Unit.Percent),
				Color = Uno.Color.FromRgba(0xFFFFFFFF),
				Layer = Layer.Underlay
			};

			_frostedGlass = new FrostedGlass
			{
				Background = Background,
				Radius = Radius,
				LumaAdd = LumaAdd,
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

			_elementParent.WorldTransformInvalidated -= OnTransform;
			_elementParent = null;

			base.OnUnrooted();
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
		public float3 LumaRange { get; set; }
		public float3 LumaAdd { get; set; }

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

			var original = bg.CaptureRegion(dc, paddedRect, int2(0));
			if (original == null)
				return;

			var blur = EffectHelpers.Instance.Blur(original.ColorBuffer, dc, Sigma * bg.AbsoluteZoom);
			FramebufferPool.Release(original);

			draw Fuse.Drawing.Planar.Image
			{
				DrawContext: dc;
				Visual: Element;
				Position: elementRect.Minimum;
				Invert: true;
				Size: paddedRect.Size;
				Texture: blur.ColorBuffer;

				apply Fuse.Drawing.PreMultipliedAlphaCompositing;
				DepthTestEnabled: false;
				PixelColor: prev * float4(LumaRange, 1) + float4(LumaAdd,0);
			};

			FramebufferPool.Release(blur);
		}
	}
}