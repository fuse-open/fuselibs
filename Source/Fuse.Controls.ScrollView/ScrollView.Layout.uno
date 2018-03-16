using Uno;
using Uno.UX;

using Fuse.Elements;

namespace Fuse.Controls
{
	/**
		How is the ScrollPosition of a ScrollView modified when the layout changes.
	*/
	public enum ScrollViewLayoutMode
	{
		/** The value of ScrollPosition does not change, this may result in different visual position */
		PreserveScrollPosition,
		/** 
			The ScrollPosition is modified so that the element closest to the center visually remains visually in the same position.
		*/
		PreserveVisual,
	}
	
	public partial class ScrollViewBase
	{
		ScrollViewLayoutMode _layoutMode = ScrollViewLayoutMode.PreserveScrollPosition;
		/**
			Specifies how ScrollPosition is modified when the control gets a new layout.
			
			@experimental The specific layout behaviour may be changed in upcoming releases as we further understand how this works in various use-cases.
		*/
		public ScrollViewLayoutMode LayoutMode
		{
			get { return _layoutMode; }
			set { _layoutMode = value; }
		}
		
		bool _hasPrevArrange;
		Element _placeAnchor;
		float2 _oldMinScroll, _oldMaxScroll, _placePosition, _oldScrollPosition, _oldActualSize;
		
		protected override void ArrangePaddingBox(LayoutParams lp)
		{
			if (Element == null)
			{
				_contentMarginSize = float2(0);
				_placeAnchor = null;
			}
			else
			{
				_placeAnchor = (!_hasPrevArrange || LayoutMode == ScrollViewLayoutMode.PreserveScrollPosition) ? 
					null : FindAnchorElement();
				if (_placeAnchor != null)
				{
					_oldMinScroll = MinScroll;
					_oldMaxScroll = MaxScroll;
					_oldScrollPosition = ScrollPosition;
					_oldActualSize = ActualSize;
					_placePosition = _placeAnchor.ActualPosition + Content.ActualPosition;
				}
				
				ArrangeContent(lp);
				
				_hasPrevArrange = true;
			}
			UpdateManager.AddDeferredAction(UpdateScrollPosition, LayoutPriority.Later);
		}
		
		internal static Selector SizingChanged = "SizingChanged";
		
		void UpdateScrollPosition()
		{
			if (_placeAnchor != null)
			{
				var relAnchor = AlignmentHelpers.GetAnchor(_contentAlignment);
					
				//if possible keep the previous element in the same position
				var oldAnchor = relAnchor * _oldActualSize;
				var oldOffset = _placePosition - oldAnchor;
					
				var newAnchor = relAnchor * ActualSize; 
				var newOffset = Content.ActualPosition + _placeAnchor.ActualPosition - newAnchor;
					
				var diff = newOffset - oldOffset;
				//gestures need the "diff" to offset their scrolling interaction
				//don't exceed min/max though as to not trigger any ends animation
				//https://github.com/fusetools/fuselibs-private/issues/2891
				//var nsp = Math.Min( MaxScroll, Math.Max( MinScroll, ScrollPosition + diff ) );
				var nsp = ScrollPosition + diff;
				var ndiff = nsp - ScrollPosition;
				SetScrollPosition( nsp, ndiff, this );
			}
			
			//constrain to new ends (use scroller if possible to allow for animation and interplay with pointer)
			if (_scroller != null && IsRootingCompleted)
			{
				UpdateManager.AddDeferredAction(_scroller.CheckLimits, LayoutPriority.Later);
			}
			else
			{
				ScrollPosition = Math.Min( MaxScroll, Math.Max( MinScroll, ScrollPosition ) );
				//force messages since relative position always changes
				OnScrollPositionChanged(float2(0), false, this);
			}
			
			OnPropertyChanged(SizingChanged);
		}
		
		 
		/**
			Find a good element that is currently in view to use as an anchor for layout changes.
			
			This finds the element who's center is nearest to the center of the visual display.
		*/
		Element FindAnchorElement()
		{
			Element cur = null;
			float curDist = 0;

			var relAnchor = AlignmentHelpers.GetAnchor(_contentAlignment);
			var anchor = relAnchor * ActualSize;
			
			for (var c = Element.FirstChild<Element>(); c != null; c = c.NextSibling<Element>())
			{
				if (!c.HasMarginBox || c.LayoutRole != LayoutRole.Standard)
					continue;
					
				var cAnchor = Content.ActualPosition - ScrollPosition + c.ActualPosition + c.ActualSize * relAnchor;
				var dist = Vector.Length(cAnchor - anchor);
				if (dist < curDist || cur == null)
				{
					cur = c;
					curDist = dist;
				}
			}
			
			return cur;
		}
		
		//track the result of `ArrangeContent`
		Alignment _contentAlignment;
		float2 _contentMarginSize;
		
		internal float2 ContentMarginSize { get { return _contentMarginSize; } }
		
		void ArrangeContent(LayoutParams lp)
		{
			var nlp = lp.CloneAndDerive();
			nlp.RemoveSize(Padding.XY + Padding.ZW);
			nlp.SetRelativeSize(lp.GetAvailableSize(),true,true);
				
			Alignment align = Alignment.Default;
			var setWidth = false;
			var setHeight = false;
			
			if (AllowedScrollDirections == ScrollDirections.Both)
			{
				align = Alignment.TopLeft;
				setWidth = true;
				setHeight = true;
			} 
			else if (AllowedScrollDirections == ScrollDirections.Horizontal)
			{
				align = Alignment.Left;
				setWidth = true;
			}
			else if (AllowedScrollDirections == ScrollDirections.Vertical)
			{
				align = Alignment.Top;
				setHeight = true;
			}
			else
			{
				Fuse.Diagnostics.UserError( "AllowedScrollDirections is not valid: " + AllowedScrollDirections, this );
			}

			//set default alignment on content
			var hAlign = Alignment.Default;
			if (setWidth)
			{	
				hAlign = AlignmentHelpers.GetHorizontalAlign(Content.Alignment);
				if (hAlign == Alignment.Default)
					hAlign = AlignmentHelpers.GetHorizontalAlign(align);
			}
			var vAlign = Alignment.Default;
			if (setHeight)
			{
				vAlign = AlignmentHelpers.GetVerticalAlign(Content.Alignment);
				if (vAlign == Alignment.Default)
					vAlign = AlignmentHelpers.GetVerticalAlign(align);
			}
			align = hAlign | vAlign;
			
			nlp.RetainAxesXY(!setWidth, !setHeight);
				
			var sz = Content.ArrangeMarginBox(Padding.XY, nlp);
			Layouts.Layout.AdjustAlignBox(Content, sz, float4(Padding.XY,lp.Size-Padding.ZW),
				align);
				
			_contentMarginSize = sz;
			_contentAlignment = align;
		}
		
		protected override LayoutDependent IsMarginBoxDependent( Visual child )
		{
			//require a rearrange if the child margin change since the scroll range must change
			return LayoutDependent.MaybeArrange;
		}
		
		protected override float2 GetContentSize(LayoutParams lp)
		{
			if (Element != null)
			{
				var nlp = lp.CloneAndDerive();
				nlp.RemoveSize(Padding.XY+Padding.ZW);
				var r = Element.GetMarginSize(nlp);
				return r;
			}
			return float2(0);
		}
		
		/**
			The distance to the visible view area for the provided rectangle.
		*/
		internal float4 DistanceToView(float2 min, float2 max)
		{
			float2 fromStart = DistanceFromView(min, DistanceFromViewTarget.Start);
			float2 fromEnd = DistanceFromView(max, DistanceFromViewTarget.End);
			return float4(fromStart.X, fromStart.Y, fromEnd.X, fromEnd.Y);
		}

		/**
			Used to specify the target for measuring distance from in `DistanceFromView` method. Can be either `Start` or `End`.
		*/
		internal enum DistanceFromViewTarget
		{
			/**
				Measures the distance from the view start.
			*/
			Start,
			/**
				Measures the distance from the view end.
			*/
			End,
		}
		/**
			The distance from the visible view area start or end for the provided position.
		*/
		internal float2 DistanceFromView(float2 position, DistanceFromViewTarget target)
		{
			float x = 0;
			float y = 0;
			switch (target)
			{
				case DistanceFromViewTarget.Start:
					x = position.X - ScrollPosition.X;
					y = position.Y - ScrollPosition.Y;
					break;
				case DistanceFromViewTarget.End:
					x = (ScrollPosition.X + ActualSize.X) - position.X;
					y = (ScrollPosition.Y + ActualSize.Y) - position.Y;
					break;
			}
			return float2(x,y);
		}
	}
}
