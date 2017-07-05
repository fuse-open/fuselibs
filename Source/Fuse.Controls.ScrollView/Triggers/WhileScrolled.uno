using Uno;
using Uno.UX;

using Fuse.Controls;

namespace Fuse.Triggers
{
	/**
		Is active while the @ScrollView is scrolled within a given region.
		
		This defines the region the same way as @Scrolled
	*/
	public class WhileScrolled : WhileTrigger
	{
		ScrollViewBase _scrollable;
		
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
			Update();
		}
		
		void Update()
		{
			if (_scrollable != null)
				SetActive(_region.IsInZone(_scrollable));
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
			Update();
		}

		/* Composition of ScrollRegion (Copies in Scrolled.uno/WhileScrolled.uno)*/
		ScrollRegion _region = new ScrollRegion();
		/** @see Scrolled.To */
		public ScrolledWhere To
		{
			get { return _region.To; }
			set { if (_region.SetTo(value)) Update(); }
		}

		/** @see Scrolled.Within */
		public float Within
		{
			get { return _region.Within; }
			set { if (_region.SetWithin(value)) Update(); }
		}

		/** @see Scrolled.RelativeTo */
		public IScrolledLength RelativeTo
		{
			get { return _region.RelativeTo; }
			set { if (_region.SetRelativeTo(value)) Update(); }
		}
		/* End Composition */
	}
}
