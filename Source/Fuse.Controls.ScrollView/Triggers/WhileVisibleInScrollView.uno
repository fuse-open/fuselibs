using Uno;

using Fuse.Elements;
using Fuse.Controls;

namespace Fuse.Triggers
{
	/**
		How the bounds of an element are treated.
	*/
	public enum WhileVisibleInScrollViewMode
	{
		/**
			Activates while the element is at least partially within the ScrollView.
		*/
		Partial,
		/**
			Activates while the element is completely visible within the ScrollView.
		*/
		Full,
	}

	/**
		Active while an element is positioned within the visible area of the @ScrollView. 
		
			<ScrollView>
				<StackPanel>
					<Each Items="{images}">
						<DockPanel Height="100">
							<Image Url="{source}" MemoryPolicy="UnloadUnused" Dock="Left"
								Visibility="Hidden" ux:Name="theImage"/>
							<Text Value="{description}" TextWrapping="Wrap"/>
							
							<WhileVisibleInScrollView>
								<Change theImage.Visibility="Visible"/>
							</WhileVisibleInScrollView>
						</DockPanel>
					</Each>
				</StackPanel>
			</ScrollView>
			
		This example will show the images only when they are actually in the visible area. Combined with the `UnloadUnused` memory policy this will allow the memory to be freed when they aren't visible to the user.
		
		If the panel has a fixed height, as in this example, you could also collapse the text to save the calculation and rendering time.
		
		You would also use this trigger if you wish to animate something within a ScrollView. There's no point in animating something the user can't actually see; using the trigger can save resources by not animating things that aren't visible.
			
		Note that the element itself need not necessarily be visible, but just have a layout that positions it in the visible area. `Visibility="Hidden"` on a @Visual does not prevent the activiation of this trigger.
		
		This trigger responds to changes in scroll position. Layout changes on the element will also update the status but layout changes further up the tree may not update the status (we do not have an efficient way to monitor for global positioning changes).
	*/
	public class WhileVisibleInScrollView : WhileTrigger
	{
		ScrollViewBase _scrollable;
		Element _element;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_scrollable = Parent.FindByType<ScrollViewBase>();
			if (_scrollable == null)
			{
				Fuse.Diagnostics.UserError( "Could not find a ScrollView control.", this );
				return;
			}
			
			_element = Parent as Element;
			if (_element == null)
			{
				Fuse.Diagnostics.UserError( "Parent must be an Element", this );
				return;
			}
			
			if (!_element.HasLayoutIn(_scrollable))
			{
				Fuse.Diagnostics.UserError( "Must have an Element path to the ScrollView", this );
				return;
			}
			
			_scrollable.ScrollPositionChanged += OnScrollPositionChanged;
			_element.Placed += OnElementPlaced;
			RequireLayout(_element);
			Update();
		}
		
		protected override void OnUnrooted()
		{
			if (_scrollable != null)
			{
				_element.Placed -= OnElementPlaced;
				_scrollable.ScrollPositionChanged -= OnScrollPositionChanged;
				_scrollable = null;
			}
			base.OnUnrooted();
		}

		float _distance = 0;
		/**
			The maximum allowed distance away from the visible area where this trigger remains active.
			
			The distance is measured as the shortest line between the visible rectangle and the rectangle of the element. For example, in a vertical `ScrollView` an item above the top is measured from its bottom edge to the top of the visible area.
			
			The default is `0` meaning at least a portion must actually be visible.
		*/
		public float Distance
		{
			get { return _distance; }
			set
			{
				_distance = value;
				Update();
			}
		}

		IScrolledLength _relativeTo = IScrolledLengths.Points;
		/**
			The measurement used by `Distance`.
			
			Default is `Points`.
			
			@see Fuse.Triggers.Scrolled.RelativeTo
		*/
		public IScrolledLength RelativeTo
		{
			get { return _relativeTo; }
			set
			{
				_relativeTo = value;
				Update();
			}
		}

		WhileVisibleInScrollViewMode _mode = WhileVisibleInScrollViewMode.Partial;
		/**
			How the bounds of an element are treated.

			Default is `Partial`. When set to `Full`, the whole element bounds need to be inside view for the `WhileVisibleInScrollView` trigger to activate.

			Both options can be combined with `Distance` to adjust when the trigger activates.
		*/
		public WhileVisibleInScrollViewMode Mode
		{
			get { return _mode; }
			set
			{
				_mode = value;
				Update();
			}
		}
		
		void OnScrollPositionChanged(object s, object args)
		{
			Update();
		}

		void OnElementPlaced(object s, object args)
		{	
			Update();
		}
		
		void Update()
		{
			if (_element == null || _scrollable == null || !_element.HasMarginBox)
				return;
				
			const float zeroTolerance = 1e-05f;

			var min = _element.GetLayoutPositionIn(_scrollable);
			var max = min + _element.ActualSize;
			var maxDist = _scrollable.ToScalarPosition( RelativeTo.GetPoints(Distance, _scrollable) );

			bool isInView = false;

			switch (_mode)
			{
				case WhileVisibleInScrollViewMode.Full:
					var dist = _scrollable.DistanceToView(min, max);
					var distStart = _scrollable.ToScalarPosition(float2(dist.X, dist.Y));
					var distEnd = _scrollable.ToScalarPosition(float2(dist.Z, dist.W));
					isInView = (distStart > (maxDist - zeroTolerance)) && (distEnd > (maxDist - zeroTolerance));
					break;
				case WhileVisibleInScrollViewMode.Partial:
					var dist = _scrollable.DistanceToView(max, min);
					var distStart = _scrollable.ToScalarPosition(float2(dist.X, dist.Y));
					var distEnd = _scrollable.ToScalarPosition(float2(dist.Z, dist.W));
					isInView = (distStart > (-1 * maxDist - zeroTolerance)) && (distEnd > ( -1 * maxDist - zeroTolerance));
					break;
			}

			SetActive( isInView );
		}
		
	}
}
