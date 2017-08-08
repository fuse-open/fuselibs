using Fuse.Reactive;
using Fuse.Navigation;

namespace Fuse.Controls
{
	//TODO: Can probably be moved up to NavigationControl
	public partial class Navigator
	{
		//TODO: Change to IObservableArray
		IArray _pages;
		Uno.IDisposable _pagesSubscription;
		public IArray Pages
		{
			get { return _pages; }
			set
			{
				_pages = value;
				OnPagesChanged();
			}
		}
		
		int _curPageIndex = -1;
		void OnPagesChanged()
		{
			if (!IsRootingStarted)
				return;
				
			if (_pagesSubscription != null)
			{
				_pagesSubscription.Dispose();
				_pagesSubscription = null;
			}
			
			if (_pages == null)
				return;
				
			var obs = _pages as IObservable;
			if (obs != null)
				_pagesSubscription = obs.Subscribe(this);
				
			_curPageIndex = -1;
			FullUpdatePages(UpdateFlags.ForceGoto);
		}
		
		static readonly PropertyHandle _pageContextProperty = Fuse.Properties.CreateHandle();
		
		[Uno.Flags]
		enum UpdateFlags
		{
			None = 0,
			ForceGoto = 1 << 0,
			Add = 1 << 1,
			Replace = 1 << 2,
		}
		
		void FullUpdatePages(UpdateFlags flags = UpdateFlags.None)
		{
			string path = null, param = null;
			int pageNdx = _pages.Length - 1;
			object data = null;
			if (pageNdx >= 0)
			{
				data = _pages[pageNdx];
				var obj = _pages[pageNdx] as IObject;
				if (obj != null && obj.ContainsKey("path"))
					path = Marshal.ToType<string>(obj["path"]);
					
				//perhaps this is good enough to distinguish different objects from being recognized
				//as the same page
				param = "" + data.GetHashCode();
			}
				
			var op = pageNdx < _curPageIndex ? RoutingOperation.Pop :
				pageNdx == _curPageIndex ? RoutingOperation.Replace :
				pageNdx > 0 ? RoutingOperation.Push : 
				RoutingOperation.Goto;
			if (flags.HasFlag(UpdateFlags.ForceGoto))
				op = RoutingOperation.Goto;
			else if (flags.HasFlag(UpdateFlags.Add))
				op = pageNdx > 0 ? RoutingOperation.Push : RoutingOperation.Goto;
			else if (flags.HasFlag(UpdateFlags.Replace))
				op = RoutingOperation.Replace;
				
			var trans = NavigationGotoMode.Transition;
			
			Visual v;
			(this as IRouterOutlet).Goto( ref path, ref param, trans, op, "", out v );
			if (v != null)
			{
				var oldData = v.Properties.Get(_pageContextProperty);
				v.Properties.Set(_pageContextProperty, data);
				v.BroadcastDataChange(oldData, data);
			}
			
			_curPageIndex = pageNdx;
		}
		
		void IObserver.OnSet(object newValue)
		{
			FullUpdatePages(UpdateFlags.ForceGoto);
		}
		
		void IObserver.OnFailed(string message)
		{
			FullUpdatePages();
		}
		
		void IObserver.OnAdd(object value)
		{
			FullUpdatePages(UpdateFlags.Add);
		}
		
		void IObserver.OnRemoveAt(int index)
		{
			if (index == _curPageIndex)
				FullUpdatePages();
			else if( index < _curPageIndex)
				_curPageIndex--;
		}
		
		void IObserver.OnInsertAt(int index, object value)
		{
			if (index >= _curPageIndex)
				FullUpdatePages();
			else	
				_curPageIndex++;
		}
		
		void IObserver.OnNewAt(int index, object value)
		{
			if (index == _curPageIndex)
				FullUpdatePages(UpdateFlags.Replace);
		}
		
		void IObserver.OnNewAll(IArray values)
		{
			FullUpdatePages();
		}
		
		void IObserver.OnClear()
		{
			FullUpdatePages();
		}
		
		object Node.ISubtreeDataProvider.GetData(Node n)
		{
			return n.Properties.Get(_pageContextProperty);
		}
	}
	
}