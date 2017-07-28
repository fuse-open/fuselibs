using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Controls
{
	public class ScrollViewPagerArgs : EventArgs
	{
	}
	
	public class ScrollViewPager : Behavior, IPropertyListener
	{
		int _retain = 3;
		public int Retain
		{
			get { return _retain; }
			set
			{
				if (_retain == value)
					return;
					
				_retain = value;
			}
		}
		
		float _endRange = 0.75f;
		public float EndRange
		{
			get { return _endRange; }
			set
			{
				if (_endRange == value)
					return;
				
				_endRange = value;
			}
		}
		
		Each _each;
		public Each Each 
		{
			get { return _each; }
			set { _each = value; }
		}
		
		ScrollViewBase _scrollable;
		protected override void OnRooted()
		{
			base.OnRooted();

			if (Each == null)
			{
				Fuse.Diagnostics.UserError( "Require an Each", this );
				return;
			}
			
			if (!Each.HasLimit)
				Each.Limit = 1;
			
			_scrollable = Parent.FindByType<ScrollViewBase>();
			if (_scrollable == null)
			{
				Fuse.Diagnostics.UserError( "Could not find a Scrollable control.", this );
				return;
			}
			
			_scrollable.AddPropertyListener(this);
			_prevActualSize = float2(0);
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
			if (obj != _scrollable)
				return;
				
			if (prop == ScrollView.ScrollPositionName)
			{
				if (!_pendingPosition)
				{
					UpdateManager.AddDeferredAction(CheckPosition);
					_pendingPosition = true;
				}
			}
			else if (prop == ScrollView.SizingChanged)
			{
				if (!_pendingSizing)
				{
					UpdateManager.AddDeferredAction(CheckSizing);
					_pendingSizing = true;
				}
			}
		}
		
		bool _pendingPosition;
		bool _pendingSizing;

		public delegate void ScrollViewPagerHandler(object s, ScrollViewPagerArgs args);
		
		public event ScrollViewPagerHandler ReachedEnd;
		
		public event ScrollViewPagerHandler ReachedStart;
		
		bool _nearTrueEnd;
		bool _nearTrueStart;
		void CheckPosition()
		{
			_pendingPosition = false;
			var nearEnd = _scrollable.ToScalarPosition( (_scrollable.MaxScroll - _scrollable.ScrollPosition) /
				_scrollable.ActualSize) < EndRange;
			var nearStart = _scrollable.ToScalarPosition( (_scrollable.ScrollPosition - _scrollable.MinScroll) /
				_scrollable.ActualSize) < EndRange;
			
			var nearTrueEnd = false;
			var nearTrueStart = false;
			
			if (nearEnd && nearStart)
			{
				//nothing, otherwise we'd flip back and forth
				nearTrueEnd = true;
				nearTrueStart = true;
			}
			else if (nearEnd)
			{
				var offset = Each.Offset;
				var limit = Each.Limit;
				var count = Each.DataCount;
				
				if (offset + limit < count)
					Each.Offset = offset + 1;
				else
					nearTrueEnd = true;
			}
			else if (nearStart)
			{
				var offset = Each.Offset;
				if (offset > 0)
					Each.Offset = offset - 1;
				else
					nearTrueStart = true;
			}
			
			if (nearTrueStart != _nearTrueStart && nearTrueStart)
			{	
				if (ReachedStart != null)
					ReachedStart(this, new ScrollViewPagerArgs());
			}
			_nearTrueStart = nearTrueStart;
			
			if (nearTrueEnd != _nearTrueEnd &&  nearTrueEnd)
			{
				if (ReachedEnd != null)
					ReachedEnd(this, new ScrollViewPagerArgs());
			}
			_nearTrueEnd = nearTrueEnd;
		}

		float2 _prevActualSize;
		void CheckSizing()
		{
			_pendingSizing = false;
			var range = _scrollable.MaxScroll - _scrollable.MinScroll;
			var pages = _scrollable.ContentMarginSize / _scrollable.ActualSize;

			var scalarPages = _scrollable.ToScalarPosition(pages);
			if (scalarPages < Retain)
			{
				var count = Each.DataCount;
				var offset = Each.Offset;
				var limit = Each.Limit;
				
				if (offset + limit < count)
					Each.Limit = limit + 1;
			}
			else if (scalarPages > Retain &&
				_scrollable.ToScalarPosition(_scrollable.ActualSize) < _scrollable.ToScalarPosition(_prevActualSize) )
			{
				//only reduce when the ScrollView itself is being shrunk in size, otherwise we run the risk
				//of flickering between to sizes for an element that pushes it back/forth over the limit
				var limit = Each.Limit;
				
				if (limit > 1)
					Each.Limit = limit - 1;
			}
		}
		
	}
}
