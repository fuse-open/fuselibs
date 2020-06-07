using Uno;
using Uno.UX;

using Fuse;

namespace Fuse.Elements
{
	public abstract partial class Element
	{
		Size _width = Uno.UX.Size.Auto;
		/** The width of the `Element`.

			Used to ensure an element will have a specific width on-screen.

			See @Layout for more details.

			@default Auto
		*/
		public Size Width
		{
			get { return _width; }
			set
			{
				if (_width != value)
				{
					_width = value;
					InvalidateLayout();
				}
			}
		}

		Size _height = Uno.UX.Size.Auto;
		/** The height of the `Element`.

			Used to ensure an element will have a specific height on-screen.

			See @Layout for more details.

			@default Auto
		*/
		public Size Height
		{
			get { return _height; }
			set
			{
				if (_height != value)
				{
					_height = value;
					InvalidateLayout();
				}
			}
		}

		/** The combined `Width` and `Height` of the element.

			If using this property avoid using `Width` or `Height` as this is a combined alias for those properties. Choose the property that works easier for your desired binding, expressions and animations.

			See @Layout for more details.
		*/
		public Size2 Size
		{
			get { return new Size2(Width, Height); }
			set
			{
				Width = value.X;
				Height = value.Y;
			}
		}

		/** The minimum width of the `Element`.

			Used to ensure an element will have at least the given width on-screen.

			See @Layout for more details.

			@default Auto
		*/
		public Size MinWidth
		{
			get { return Get(FastProperty1.MinWidth, Uno.UX.Size.Auto); }
			set
			{
				if (MinWidth != value)
				{
					Set(FastProperty1.MinWidth, value, Uno.UX.Size.Auto);
					InvalidateLayout();
				}
			}
		}

		/** The minimum height of the `Element`.

			Used to ensure an element will have at least the given height on-screen.

			See @Layout for more details.

			@default Auto
		*/
		public Size MinHeight
		{
			get { return Get(FastProperty1.MinHeight, Uno.UX.Size.Auto); }
			set
			{
				if (MinHeight != value)
				{
					Set(FastProperty1.MinHeight, value, Uno.UX.Size.Auto);
					InvalidateLayout();
				}
			}
		}

		/** The maximum width of the `Element`.

			Used to ensure an element will have no greater than the given width on-screen.

			See @Layout for more details.

			@default Auto
		*/
		public Size MaxWidth
		{
			get { return Get(FastProperty1.MaxWidth, Uno.UX.Size.Auto); }
			set
			{
				if (MaxWidth != value)
				{
					Set(FastProperty1.MaxWidth, value, Uno.UX.Size.Auto);
					InvalidateLayout();
				}
			}
		}

		/** The maximum height of the `Element`.

			Used to ensure an element will have no greater than the given height on-screen.

			See @Layout for more details.

			@default Auto
		*/
		public Size MaxHeight
		{
			get { return Get(FastProperty1.MaxHeight, Uno.UX.Size.Auto); }
			set
			{
				if (MaxHeight != value)
				{
					Set(FastProperty1.MaxHeight, value, Uno.UX.Size.Auto);
					InvalidateLayout();
				}
			}
		}

		Alignment _alignment;
		/** The @Alignment of the `Element`.

			Used to position an `Element` within its available space if the `Element` doesn't simply fill that space.

			See @Layout for more details.
		*/
		public Alignment Alignment
		{
			get { return _alignment; }
			set
			{
				if (_alignment != value)
				{
					_alignment = value;
					InvalidateLayout();
				}
			}
		}

		Visibility _visibility = Visibility.Visible;
		/** The @Visibility of the `Element`.

			Used to determine if the `Element` is displayed on screen, and can also affect its layout.

			Possible values:
			- `Visible` - The element is displayed on-screen as usual.
			- `Hidden` - The element will not be displayed on-screen, but will still participate in and affect layout normally.
			- `Collapsed` - The element will not be displayed on-screen or participate in layout.

			## Example

			In the following example, only two of the rectangles are visible. The second Rectangle is collapsed,
			so it's not taking up any space at all. The third Rectangle is hidden, so it takes up space, but is not
			visible. The last Rectangle has no Visibility set, so it defaults to being visible as usual.

				<StackPanel>
					<Rectangle Visibility="Visible" Color="Red" Height="50"/>
					<Rectangle Visibility="Collapsed" Color="Green" Height="50"/>
					<Rectangle Visibility="Hidden" Color="Blue" Height="50"/>
					<Rectangle Color="Yellow" Height="50"/>
				</StackPanel>

			@default Visible
		*/
		[UXOriginSetter("SetVisibility")]
		public Visibility Visibility
		{
			get { return _visibility; }
			set { SetVisibility(value, this); }
		}

		public void SetVisibility(Visibility value, IPropertyListener origin)
		{
			var old = _visibility;
			_visibility = value;
			OnVisibilityChanged(old, origin);
		}

		static Selector _visibilityName = "Visibility";
		void OnVisibilityChanged(Visibility oldVisibility, IPropertyListener origin)
		{
			OnPropertyChanged(_visibilityName, origin);
			OnLocalVisibleChanged();

			if (oldVisibility == Visibility.Collapsed || Visibility == Visibility.Collapsed)
				InvalidateLayout();

			InvalidateVisualComposition();
		}

		/** The margin of the `Element` in points.

			`Margin` controls the distance from the edges of an element to the corresponding edges of its container.

			`Margin` is made up of 4 values; one for each edge of the element. In order, they are left, top, right, and bottom. In UX, they are specified as a comma-separated list:

				<Panel Margin="10,20,30,40" />

			They can also be specified in a shortened form:

				<Panel Margin="10" /> <!-- is expanded to "10,10,10,10" -->
				<Panel Margin="10,20" /> <!-- is expanded to "10,20,10,20" -->

			See @Layout for more details.

			@default 0,0,0,0
		*/
		public float4 Margin
		{
			get { return Get(FastProperty1.Margin, float4(0)); }
			set
			{
				if (Margin != value)
				{
					Set(FastProperty1.Margin, value, float4(0));
					InvalidateLayout();
				}
			}
		}

		/** The padding of the `Element` in points.

			`Padding` controls the distance from the edges of an element to the edges of the elements inside it. It's very similar to @Margin, except that it works "inwards".

			`Padding` is made up of 4 values; one for each edge of the element. In order, they are left, top, right, and bottom. In UX, they are specified as a comma-separated list:

				<Panel Padding="10,20,30,40" />

			They can also be specified in a shortened form:

				<Panel Padding="10" /> <!-- is expanded to "10,10,10,10" -->
				<Panel Padding="10,20" /> <!-- is expanded to "10,20,10,20" -->

			See @Layout for more details.

			@default 0,0,0,0
		*/
		public float4 Padding
		{
			get { return Get(FastProperty1.Padding, float4(0)); }
			set
			{
				if (Padding != value)
				{
					Set(FastProperty1.Padding, value, float4(0));
					InvalidateLayout();
				}
			}
		}

		/** Offets the position of the element after all other layout has been applied.

			For example, `<StackPanel Alignment="TopCenter" Offset="0,10">` would position the `StackPanel` 10 points down from the top its parent, after all other layout has been applied (@Margin, @Padding, etc).
		*/
		public Size2 Offset
		{
			get { return Get(FastProperty1.Offset, Size2.Auto); }
			set
			{
				if (Offset != value)
				{
					Set(FastProperty1.Offset, value, Size2.Auto);
					InvalidateLayout();
				}
			}
		}

		/** A point within the element to treat as its "epicenter".

			The `Anchor` partially specifies how an element is aligned within it's parent. Properties like `Alignment`
			and `X`, `Y` define a location in the parent to place the child, and `Anchor` specifies what child point is
			aligned there.

			For example, `<Panel X="50" Y="100" Anchor="25%,25%">` positions the middle of the top-left quarter (25%,25%) of the panel at point 50,100 in the parent.

			`Alignment` implies a coordinate and anchor point, for example `<Panel Alignment="BottomRight">` is that same as `<Panel X="100%" Y="100%" Anchor="100%,100%">`. You can use `alignment` and override the anchor, for examlpe `<Panel Alignment="BottomRight" Anchor="50%,50%">` centers the panel at the bottom right point of the parent.
		*/
		public Size2 Anchor
		{
			get { return Get(FastProperty1.Anchor, Size2.Auto); }
			set
			{
				if (Anchor != value)
				{
					Set(FastProperty1.Anchor, value, Size2.Auto);
					InvalidateLayout();
				}
			}
		}

		/** The `X` location of the `Element`.

			This implies `Alignment=TopLeft`, thus by default measures from the top left corner of the parent.
		*/
		public Size X
		{
			get { return Get(FastProperty1.X, Uno.UX.Size.Auto); }
			set
			{
				if (X != value)
				{
					Set(FastProperty1.X, value, Uno.UX.Size.Auto);
					InvalidateLayout();
				}
			}
		}

		/** The `Y` location of the `Element`.

			This implies `Alignment=TopLeft`, thus by default measures from the top left corner of the parent.
		*/
		public Size Y
		{
			get { return Get(FastProperty1.Y, Uno.UX.Size.Auto); }
			set
			{
				if (Y != value)
				{
					Set(FastProperty1.Y, value, Uno.UX.Size.Auto);
					InvalidateLayout();
				}
			}
		}

		/** The combined `X` and `Y` position of the element.

			If using this property avoid using `X` or `Y` properties, as this is an combined alias for those properties. Choose the property that works easier for your desired bindined, expressions and animations.
		*/
		public Size2 Position
		{
			get { return new Size2(X, Y); }
			set
			{
				X = value.X;
				Y = value.Y;
			}
		}

		static readonly Selector _clipToBoundsName = "ClipToBounds";

		/** Clips the child elements to the bounds of this element visually.
		*/
		public bool ClipToBounds
		{
			get { return HasBit(FastProperty1.ClipToBounds); }
			set
			{
				if (ClipToBounds != value)
				{
					SetBit(FastProperty1.ClipToBounds, value);
					InvalidateVisual();
					InvalidateHitTestBounds();
					OnPropertyChanged(_clipToBoundsName);
				}
			}
		}
	}
}
