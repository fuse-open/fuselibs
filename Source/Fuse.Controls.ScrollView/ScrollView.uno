using Uno;
using Uno.UX;

using Fuse.Controls.Native;
using Fuse.Elements;
using Fuse.Gestures;
using Fuse.Input;
using Fuse.Motion;
using Fuse.Scripting;

namespace Fuse.Controls
{
	public class ScrollPositionChangedArgs : ValueChangedArgs<float2>, IScriptEvent
	{
		public bool IsAdjustment { get; private set; }
		//this much was adjusted due to layout change, not "scrolling"
		public float2 ArrangeOffset { get; private set; }

		public IPropertyListener Origin { get; private set; }

		public float2 RelativeScrollPosition { get; private set; }

		public ScrollPositionChangedArgs( float2 scrollPos, float2 arrangeOffset, bool isAdjustment,
			IPropertyListener origin, float2 relativeScrollPos)
			: base(scrollPos)
		{
			this.ArrangeOffset = arrangeOffset;
			this.Origin = origin;
			this.IsAdjustment = isAdjustment;
			this.RelativeScrollPosition = relativeScrollPos;
		}

		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddObject("value", Value);
			s.AddObject("relativePosition", RelativeScrollPosition);
		}
	}

	public delegate void ScrollPositionChangedHandler(object sender, ScrollPositionChangedArgs args);

	/**
		A `ScrollView` is a control that allows scrolling over the content.
		It only accepts a single child, from which the size of the scrollable area is calculated.
		That child can be a single element or a UX tree of controls.

		By default, ScrollView tries to take up the same amount of space as its content in the scrollable direction.
		However, when placed in a @Panel (or @DockPanel, @Grid, etc.), the size of the ScrollView itself will be limited to the size of its parent.

		> *Note*
		>
		> @StackPanel does not limit the size of its children, but rather lets them extend to whatever size they want to take up.
		> This is a problem with ScrollView, since it by default inherits the size of its content.
		> If we were to place a ScrollView inside a StackPanel, the size of the ScrollView could extend beyond the bounds of the screen.
		> What we want instead is that only the ScrollView's *content* should extend to whatever size it needs, while the ScrollView itself is contained within the bounds of the screen.
		>
		> This means that **a ScrollView inside a @StackPanel probably won't behave as you expect it to**.
		> We recommend using a different type of @Panel (e.g. a @DockPanel) as the parent of the ScrollView or setting the ScrollView's height explicitly.

		The `Alignment` of the child content influences the `MinScroll` and `MaxScroll` values as well as the starting `ScrollPosition`.
		For example a `Bottom` aligned element will start with the bottom of the content visible (aligned to the bottom of the `ScrollView`) and `MinScroll` will be negative, as the overflow is to the top of the `ScrollView`.

		## LayoutMode

		By default a `ScrollView` keeps a consistent `ScrollPosition` when the layout changes. This may result in jumping when content is added/removed.

		An alternate mode `LayoutMode="PreserveVisual"` instead attempts to maintain visual consistency when its children or parent layout is changed. It assumes it's immediate content is a container and looks at that container's children.  For example, a layout like this:

			<ScrollView>
				<StackPanel>
					<Panel/>
					<Panel/>
				<StackPanel>
			</ScrollView>

		Visuals without `LayoutRole=Standard` are not considered when retaining the visual consistency. The `LayoutMode` property can be used to adjust this behavior.
	*/
	public partial class ScrollViewBase: ContentControl, IScrollViewHost
	{
		Element Element { get { return Content as Element; } }
		const float _zeroTolerance = 1e-05f;

		internal static Selector UserScrollName = "UserScroll";
		bool _userScroll = true;
		/**
			Enables/disables the ability for the user to scroll the control. When `false` the user cannot interact with the control but it can still be scrolled programmatically.
		*/
		public bool UserScroll
		{
			get { return _userScroll; }
			set
			{
				if (_userScroll == value)
					return;

				_userScroll = value;
				OnScrollPropertyChanged(UserScrollName, this);
			}
		}

		internal static Selector GesturePriorityName = "GesturePriority";
		GesturePriority _gesturePriority = GesturePriority.Low;
		/**
			The priority of the scrolling gestures.

			The default is Lower.

			@advanced
			@experimental
		*/
		public GesturePriority GesturePriority
		{
			get { return _gesturePriority; }
			set
			{
				if (_gesturePriority == value)
					return;

				_gesturePriority = value;
				OnScrollPropertyChanged(GesturePriorityName, this);
			}
		}


		bool _snapMinTransform = true;
		/**
			If set to `false` the contents will not visually scroll into the minimum snapping region (when the user scrolls beyond the top of the content). This region however still exists and can be used in ScrollingAnimation still.
		*/
		public bool SnapMinTransform
		{
			get { return _snapMinTransform; }
			set { _snapMinTransform = value; }
		}

		bool _snapMaxTransform = true;
		/**
			If set to `false` the contents will not visually scroll into the maximum snapping region (when the user scrolls beyond the bottom of the content). This region however still exists and can be used in ScrollingAnimation still.
		*/
		public bool SnapMaxTransform
		{
			get { return _snapMaxTransform; }
			set { _snapMaxTransform = value; }
		}

		Visual _currentContent;
		protected override void OnContentChanged()
		{
			base.OnContentChanged();

			if (Content != null && !(Content is Element)) throw new Exception("Visual content of ScrollView must be of type Element");

			if (_currentContent != null) _currentContent.Children.Remove(_scrollTranslation);
			_currentContent = Content;
			if (_currentContent != null) _currentContent.Children.Add(_scrollTranslation);
			_hasPrevArrange = false;
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_hasPrevArrange = false;
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
		}

		public ScrollViewBase()
		{
			ClipToBounds = true;
			HitTestMode = HitTestMode.LocalBounds | HitTestMode.Children;
		}

		internal Scroller _scroller; //internal for Scroller to set
		internal Scroller TestScroller { get { return _scroller; } }

		/**
			@advanced
			@deprecated 2017-03-04
		*/
		[Obsolete]
		public Scroller Scroller
		{
			get { return _scroller; }
		}

		MotionConfig _motion;
		[UXContent]
		/**
			The animation and scrolling behavior of a `ScrollView` can be configured using @ScrollViewMotion.

				<ScrollView>
					<ScrollViewMotion GotoEasing="Linear" GotoDuration="0.5"/>
					<Panel>...content...</Panel>
				</ScrollView>
		*/
		public MotionConfig Motion
		{
			get
			{
				if (_motion == null)
					_motion = new ScrollViewMotion();
				return _motion;
			}
			set
			{
				_motion = value;
				if (IsRootingCompleted)
					Fuse.Diagnostics.UserError( "Motion should not be changed post-rooting", this );
			}
		}

		static Selector _keepFocusInViewName = "KeepFocusInView";
		bool _keepFocusInView = true;
		/**
			By default a child with focus will be scrolled into view. Set `KeepFocusInView` to `false` to disable this behavior.
		*/
		public bool KeepFocusInView
		{
			get { return _keepFocusInView; }
			set
			{
				if (_keepFocusInView != value)
				{
					_keepFocusInView = value;
					OnScrollPropertyChanged(_keepFocusInViewName,this);
				}
			}
		}

		static Selector _allowedScrollDirectionsName = "AllowedScrollDirections";
		ScrollDirections _allowedScrollDirections = ScrollDirections.Vertical;
		/**
			Specifies in which directions the `ScrollView` scrolls. The default is `Vertical`.

			This also affects how layout is done of the content, which the scroll direction considered the "open" axis. It's important to have content that matches the direction. For example a @StackPanel must be marked as `Horizontal` for horizontal scrolling.

				<ScrollView AllowedScrollDirections="Horizontal">
					<StackPanel Orientation="Horizontal">
						...
					</StackPanel>
				</ScrollView>

			Only `Horizontal`, `Vertical`, and `Both` are supported.
		*/
		public ScrollDirections AllowedScrollDirections
		{
			get { return _allowedScrollDirections; }
			set
			{
				if (_allowedScrollDirections != value)
				{
					_allowedScrollDirections = value;
					OnScrollPropertyChanged(_allowedScrollDirectionsName, this);
					var s = NativeScrollView;
					if (s != null)
					{
						s.AllowedScrollDirections = _allowedScrollDirections;
					}
				}
			}
		}

		void OnScrollPropertyChanged(Selector name, IPropertyListener origin)
		{
			InvalidateLayout();
			OnPropertyChanged(name, origin);
		}

		float2 _scrollPosition;
		Translation _scrollTranslation = new Translation();
		/**
			The current scroll position in points.

			Setting this value will jump to the target location (no animation).
		*/
		public float2 ScrollPosition
		{
			get { return _scrollPosition; }
			set { SetScrollPosition(value, this); }
		}

		//this must be stored so we are aware of relative changes due to layout
		float2 _previousRelative = float2(Float.PositiveInfinity);

		public void SetScrollPosition(float2 position, IPropertyListener origin)
		{
			SetScrollPositionImpl(position, float2(0), false, origin);
		}

		void SetScrollPosition(float2 position, float2 arrangeOffset, IPropertyListener origin)
		{
			SetScrollPositionImpl(position, arrangeOffset, true, origin);
		}

		void SetScrollPositionImpl(float2 position, float2 arrangeOffset, bool adjustment, IPropertyListener origin)
		{
			bool changed = false;

			position = Constrain(position);
			//TODO: It's uncertain why this check is needed, it may not be anymore
			if (Vector.LengthSquared(position - _scrollPosition) > _zeroTolerance)
			{
				_scrollPosition = position;
				changed = true;
			}

			if (!SnapMinTransform)
				position = Math.Max( MinScroll, position );
			if (!SnapMaxTransform)
				position = Math.Min( MaxScroll, position );
			var nv = float3(-position,0);
			if (Vector.LengthSquared(nv - _scrollTranslation.Vector) > _zeroTolerance)
			{
				_scrollTranslation.Vector = nv;
				//assume something might watch this as well
				changed = true;
			}

			//need to emit on relative changed, even if absolute position did not
			var nRel = RelativeScrollPosition;
			if (Vector.LengthSquared(nRel - _previousRelative) > _zeroTolerance)
			{
				_previousRelative = nRel;
				changed = true;
			}

			if (origin != null)
			{
				var sv = NativeScrollView;
				if (sv != null)
				{
					sv.ScrollPosition = position;
				}
			}

			if (changed)
				OnScrollPositionChanged(arrangeOffset, adjustment, origin);
		}

		/**
			Obtain scroll position needed to scroll to the center of the @Visual.
		*/
		public float2 GetVisualScrollPosition( Visual n )
		{
			if (n == null || Element == null)
				return float2(0);

			var trans = n.GetTransformTo(Element);
			var local = Vector.Transform(float3(0),trans);

			var elm = n as Element;
			if (elm == null)
				return local.XY;

			//center the element
			return MinScroll + local.XY + elm.ActualSize/2 - ActualSize/2;
		}

		/**
			Scrolls to absolute target position in points.

			This uses the `Motion.Goto...` settings.
		*/
		public void Goto( float2 position )
		{
			if (_scroller == null)
				ScrollPosition = Math.Min( MaxScroll, Math.Max( MinScroll, ScrollPosition ) );
			else
				_scroller.Goto(position);
		}

		/**
			Scrolls to a relative target position.

			@see RelativeScrollPosition
		*/
		public void GotoRelative( float2 position )
		{
			Goto( RelativeToAbsolutePosition(position) );
		}

		internal float2 RelativeToAbsolutePosition( float2 pos )
		{
			return MinScroll + (MaxScroll - MinScroll) * pos;
		}

		float2 FromScalarPosition( float value )
		{
			if (AllowedScrollDirections == ScrollDirections.Horizontal)
				return float2(value,0);
			else if (AllowedScrollDirections == ScrollDirections.Vertical)
				return float2(0,value);
			return float2(value);
		}

		internal float ToScalarPosition( float2 value )
		{
			if (AllowedScrollDirections == ScrollDirections.Horizontal)
				return value.X;
			else if (AllowedScrollDirections == ScrollDirections.Vertical)
				return value.Y;
			return (value.X + value.Y) /2;
		}

		/**
			The relative position of the `ScrollView`, from 0 at `MinScroll`, to 1 at `MaxScroll`.
		*/
		public float2 RelativeScrollPosition
		{
			get
			{
				var r = MaxScroll - MinScroll;
				var q = (ScrollPosition - MinScroll) / (MaxScroll - MinScroll);
				//if not yet arranged, or zero-range, report position based on alignment (so animators can start in "correct" location)
				if (r.X < _zeroTolerance)
					q.X = Element == null ? 0.5f : AlignmentHelpers.GetAnchor(Element.Alignment).X;
				if (r.Y < _zeroTolerance)
					q.Y = Element == null ? 0.5f : AlignmentHelpers.GetAnchor(Element.Alignment).Y;

				return q;
			}
			set
			{
				ScrollPosition = (value * (MaxScroll - MinScroll)) + MinScroll;
			}
		}

		/**
			Raised whenever the scroll position changes. This includes the aboslute position, the relative position and overflow/snapping position changes.
		*/
		public event ScrollPositionChangedHandler ScrollPositionChanged;

		internal static Selector ScrollPositionName = "ScrollPosition";
		void OnScrollPositionChanged(float2 arrangeOffset, bool adjustment, IPropertyListener origin)
		{
			OnPropertyChanged(ScrollPositionName, origin);

			var handler = ScrollPositionChanged;
			if (handler != null)
				handler(this, new ScrollPositionChangedArgs(ScrollPosition,arrangeOffset,
					adjustment, origin, RelativeScrollPosition));
		}

		/**
			The maximum scroll position in points.
		*/
		public float2 MaxScroll
		{
			get
			{
				if (Element == null)
					return float2(0);

				return ConstrainUp( Math.Max(ContentMarginSize + Element.ActualPosition +
					Padding.XY + Padding.ZW - ActualSize, float2(0)) );
			}
		}

		/**
			The extent of the maximum overflow (snapping) region. This is used only by gesture controls and will likely be deprecated as a public property.
		*/
		public float2 MaxOverflow
		{
			get
			{
				return MaxScroll + ConstrainUp(_scroller == null ? float2(0) : _scroller.OverflowExtent);
			}
		}

		/**
			The minimum scroll position in points.
		*/
		public float2 MinScroll
		{
			get
			{
				if (Element == null) return float2(0);

				return ConstrainDown( Math.Min( float2(0), Element.ActualPosition - Padding.XY ) );
			}
		}

		/**
			The extent of the minimum overflow (snapping) region. This is used only by gesture controls and will likely be deprecated as a public property.
		*/
		public float2 MinOverflow
		{
			get
			{
				return MinScroll - ConstrainDown(_scroller == null ? float2(0) : _scroller.OverflowExtent);
			}
		}

		internal float2 ConstrainExtents( float2 t )
		{
			if (AllowedScrollDirections == ScrollDirections.Horizontal)
				t.Y = 0;
			else if (AllowedScrollDirections == ScrollDirections.Vertical)
				t.X = 0;
			return t;
		}

		internal float2 Constrain( float2 t )
		{
			return IfSnap(ConstrainExtents(t));
		}

		float2 ConstrainUp( float2 t )
		{
			return IfSnapUp(ConstrainExtents(t));
		}

		float2 ConstrainDown( float2 t )
		{
			return IfSnapDown(ConstrainExtents(t));
		}
	}
}
