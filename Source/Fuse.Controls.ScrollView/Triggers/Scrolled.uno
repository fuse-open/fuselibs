using Uno;
using Uno.UX;

using Fuse.Controls;

namespace Fuse.Triggers
{
	public class ScrolledArgs : EventArgs
	{
	}
	
	/**
		Triggers when the ScrollView is scrolled to within a specified region.
		
		`Scrolled` triggers only once when the ScrollView enters the region. It will not trigger again until the scrolling leaves and comes back. See the `check` function if you need to force a recheck.
	*/
	public partial class Scrolled : PulseTrigger<ScrolledArgs>
	{
		//is it already in the target zone
		bool _inZone;
		ScrollViewBase _scrollable;
		
		void Update()
		{
			if (_scrollable != null)
				_inZone = _region.IsInZone(_scrollable);
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_scrollable = Parent.FindByType<ScrollViewBase>();
			if (_scrollable == null)
			{
				Fuse.Diagnostics.UserError( "Scrolled could not find a Scrollable control.", this );
				return;
			}
			
			_scrollable.ScrollPositionChanged += OnScrollPositionChanged;
			_inZone = _region.IsInZone(_scrollable);
		}
		
		protected override void OnUnrooted()
		{
			if (_scrollable != null)
			{
				_scrollable.ScrollPositionChanged -= OnScrollPositionChanged;
				_scrollable = null;
			}
			base.OnUnrooted();
		}
		
		void OnScrollPositionChanged(object s, object args)
		{
			var inz = _region.IsInZone(_scrollable);
			if (inz == _inZone)
				return;

			_inZone = inz;

			if (_inZone)
				Pulse( new ScrolledArgs() );
		}
		
		void Check()
		{
			if (_scrollable != null && _region.IsInZone(_scrollable))
				Pulse( new ScrolledArgs() );
		}
		
		/* Composition of ScrollRegion (Copies in Scrolled.uno/WhileScrolled.uno)*/
		ScrollRegion _region = new ScrollRegion();
		/** A relative location in the ScrollView where this trigger will fire. */
		public ScrolledWhere To
		{
			get { return _region.To; }
			set { if (_region.SetTo(value)) Update(); }
		}
		
		/** A distance from `To` that defines the area of the region. 
		
			For example `<Scrolled To="End" Within="100">` will fire when the ScrollView is scrolled within 100 points of the end of the content.
		*/
		public float Within
		{
			get { return _region.Within; }
			set { if (_region.SetWithin(value)) Update(); }
		}

		/**
			Specifies how the `Within` value is interpreted.
			
			The default is `Points`. Other options are:
				- `Pixels`
				- `ScrollViewSize` a multiple of the size of the ScrollView itself
				- `ContentSize` a multiple of the size of the Content of the ScrollView
		*/
		public IScrolledLength RelativeTo
		{
			get { return _region.RelativeTo; }
			set { if (_region.SetRelativeTo(value)) Update(); }
		}
		/* End Composition */

	}
}
