using Uno;
using Uno.UX;
using Fuse;
using Fuse.Controls;
using Fuse.Animations;
using Fuse.Input;
using Fuse.Elements;
using Fuse.Gestures;

namespace Fuse.Triggers
{
	public enum ScrollingAnimationRange
	{
		Standard,
		SnapStart,
		SnapEnd,
		Explicit,
		
		SnapMin = SnapStart,
		SnapMax = SnapEnd,
	}


	/** Animates over a given scroll range.

		This trigger allows you to animate properties based on the absolute position of a @ScrollView.

		In this example, we remove a top ledge as a ScrollView scrolls down:

			<Panel>
				<Panel Alignment="Top" Height="50" ux:Name="ledge">
					<Text Alignment="Center" TextAlignment="Center" Color="#fff" Value="TopLedge" />
					<Rectangle  Fill="#000" />
				</Panel>
				<ScrollView>
					<ScrollingAnimation From="0" To="50">
						<Change ledge.Opacity="0" />
					</ScrollingAnimation>
					<StackPanel>
						<!-- Block out the top ledge in the scrollview -->
						<Panel Height="50" />
						<!-- ... Content ... -->
					</StackPanel>
				</ScrollView>
			</Panel>
	*/
	public class ScrollingAnimation : Trigger, IPropertyListener
	{
		bool _hasScrollDirections; //if false then use the single axis default of Scrollview (or Vertical if 2-axis)

		ScrollDirections _scrollDirections = ScrollDirections.Vertical;
		//only Vertical or Horizontal are supported
		public ScrollDirections ScrollDirections 
		{ 
			get
			{
				if (_hasScrollDirections || _scrollable == null)
					return _scrollDirections;
				var d = _scrollable.AllowedScrollDirections;
				if (d == ScrollDirections.Horizontal)
					return ScrollDirections.Horizontal;
				return ScrollDirections.Vertical;
			}
			set
			{
				_hasScrollDirections = true;
				_scrollDirections = value;
			}
		}

		bool _hasRange = false;
		ScrollingAnimationRange _range = ScrollingAnimationRange.Standard;
		public ScrollingAnimationRange Range
		{
			get { return _range; }
			set
			{
				_range = value;
				_hasRange = true;
			}
		}

		public bool Inverse { get; set; }

		float _from, _to;
		bool _hasFrom, _hasTo;
		public float From
		{
			get { return _from; }
			set
			{
				_from = value;
				_hasFrom = true;
				if (!_hasRange)
					_range = ScrollingAnimationRange.Explicit;

				if (_scrollable != null)
					BypassSeek(OffsetScrollProgress);
			}
		}

		public float To
		{
			get { return _to; }
			set
			{
				_to = value;
				_hasTo = true;
				if (!_hasRange)
					_range = ScrollingAnimationRange.Explicit;

				if (_scrollable != null)
					BypassSeek(OffsetScrollProgress);
			}
		}
		
		ScrollView _scrollable;

		double OffsetScrollProgress
		{
			get
			{
				float2 from, to;
				if (Range == ScrollingAnimationRange.SnapStart)
				{
					from = _scrollable.MinScroll;
					to = _scrollable.MinOverflow;
				}
				else if (Range == ScrollingAnimationRange.SnapEnd)
				{
					from = _scrollable.MaxScroll;
					to = _scrollable.MaxOverflow;
				}
				else
				{
					from = _hasFrom ? float2(From) : _scrollable.MinScroll;
					to = _hasTo ? float2(To) : _scrollable.MaxScroll;
				}
				var range2 = to - from;

				float at = _scrollable.ToScalarPosition(_scrollable.ScrollPosition - from);
				float range = _scrollable.ToScalarPosition(range2);

				const float zeroTolerance = 1e-05f;
				if (Math.Abs(range) < zeroTolerance)
					return 0;

				var p = Math.Clamp( at / range, 0, 1 );
				return Inverse ? 1-p : p;
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			_scrollable = Parent.FindByType<ScrollView>();

			if (_scrollable != null)
			{
				_scrollable.AddPropertyListener(this);
				BypassSeek(OffsetScrollProgress);
			}
		}

		protected override void OnUnrooted()
		{
			if (_scrollable != null)
			{
				_scrollable.RemovePropertyListener(this);
				_scrollable = null;
			}
			base.OnUnrooted();
		}

		static Selector _scrollPositionName = "ScrollPosition";

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj == _scrollable && prop == _scrollPositionName)
				Seek(OffsetScrollProgress);
		}
	}

	/**
		Active when a @ScrollView can be scrolled.

		Use the `ScrollDirections` property to filter the activation
		based on which direction you're interested in.

		# Example

		In the following example, our background changes color when we reach the bottom of our @(ScrollView):

			<ScrollViewer>
				<SolidColor ux:Name="color" Color="#000"/>
				<StackPanel Margin="10">
					<Each Count="10">
						<Panel Height="200" Background="Red" Margin="2"/>
					</Each>
				</StackPanel>
				<WhileScrollable ScrollDirections="Down">
					<Change color.Color="#ddd" Duration="0.4"/>
				</WhileScrollable>
			</ScrollViewer>

		@example Docs/WhileScrollable.md

	*/
	public class WhileScrollable : WhileTrigger, IPropertyListener
	{
		/** The direction to filter on. */
		public ScrollDirections ScrollDirections { get; set; }
		ScrollView _scrollable;

		ScrollView _source;
		public ScrollView ScrollView
		{
			get { return _source ?? Parent as ScrollView; }
			set { _source = value; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_scrollable = ScrollView;
			if (_scrollable != null)
			{
				_scrollable.AddPropertyListener(this);
				SetActive(IsOn);
			}
		}

		protected override void OnUnrooted()
		{
			if (_scrollable != null)
			{
				_scrollable.RemovePropertyListener(this);
				_scrollable = null;
			}
			base.OnUnrooted();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj == _scrollable) SetActive(IsOn);
		}

		void OnScrollPositionChanged(object sender, Uno.EventArgs args)
		{
			SetActive(IsOn);
		}

		bool IsOn
		{
			get
			{
				var p = _scrollable.ScrollPosition;
				var mx = _scrollable.MaxScroll;
				var mn = _scrollable.MinScroll;

				const float zeroTolerance = 1e-05f;
				var isOn = (ScrollDirections.HasFlag(ScrollDirections.Left) && (p.X-zeroTolerance) > mn.X) ||
					(ScrollDirections.HasFlag(ScrollDirections.Right) && (p.X+zeroTolerance) < mx.X) ||
					(ScrollDirections.HasFlag(ScrollDirections.Up) && (p.Y-zeroTolerance) > mn.Y) ||
					(ScrollDirections.HasFlag(ScrollDirections.Down) && (p.Y+zeroTolerance) < mx.Y);
				return isOn;
			}
		}
	}

}
