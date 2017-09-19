using Fuse.Reactive;
using Fuse.Navigation;

namespace Fuse.Controls
{
	public partial class NavigationControl
	{
		//TODO: Change to IObservableArray once Model feature is merged
		IArray _pageHistory;
		/**
			Pages is a stack of pages that controls the local history for a NavigationControl.
			
			It should be bound to a JavaScript observable array. The highest index page will always be the active page for the control. As pages are added/removed from this array the navigation state will change.
			
			The items in the array are objects, either explicitly created or via the Model feature. They should contain the the `$path` property which specifies the path to use. The object itself will be added to the data context for the page, allowing lookups from within the object.
		*/
		public IArray PageHistory
		{
			get { return _pageHistory; }
			set
			{
				_pageHistory = value;
				OnPageHistoryChanged();
			}
		}
		
		int _curPageIndex = -1;
		void OnPageHistoryChanged()
		{
			if (AncestorRouterPage == null || !IsRootingStarted)
				return;
				
			AncestorRouterPage.ChildRouterPages.Detach();
			
			if (_pageHistory == null)
				return;
			
			var obs = _pageHistory as IObservable;
			if (obs != null)
			{
				AncestorRouterPage.ChildRouterPages.Attach( obs, this );
			}
			else
			{
				Fuse.Diagnostics.UserError( "PageHistory expects an observable array. It will not work correctly otherwise", this );
			}
				
			_curPageIndex = -1;
			FullUpdatePages(UpdateFlags.ForceGoto);
		}
		
		void OnPageHistoryUnrooted()
		{
			if (AncestorRouterPage != null)
				AncestorRouterPage.ChildRouterPages.Detach();
		}
		
		[Uno.Flags]
		enum UpdateFlags
		{
			None = 0,
			ForceGoto = 1 << 0,
			Add = 1 << 1,
			Replace = 1 << 2,
		}
		
		protected string GetObjectPath( object data )
		{
			string path = null;
			var obj = data as IObject;
			if (obj != null && obj.ContainsKey("$template")) //set implicitly by Model API
				path = Marshal.ToType<string>(obj["$template"]);
			if (obj != null && obj.ContainsKey("$path"))
				path = Marshal.ToType<string>(obj["$path"]);
				
			return path;
		}

		void FullUpdatePages(UpdateFlags flags = UpdateFlags.None)
		{
			string path = null, param = null;
			int pageNdx = _pageHistory.Length - 1;
			object data = null;
			if (pageNdx >= 0)
			{
				data = _pageHistory[pageNdx];
					
				path = GetObjectPath( data );
				//null is an erorr, but we can process it nonetheless (will go to no page)
				if (path == null)
					Fuse.Diagnostics.UserError( "Model is missing a $template or $page property", this);
					
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
			
			RouterPage rPage;
			if (pageNdx >= AncestorRouterPage.ChildRouterPages.Count)
			{
				rPage = new RouterPage{ Path = path, Parameter = param, Context = data };
				Fuse.Diagnostics.InternalError( "Inconsistent navigation history", this );
			}
			else if (pageNdx >= 0)
			{
				rPage = AncestorRouterPage.ChildRouterPages[pageNdx];
				rPage.Path = path;
				rPage.Parameter = param;
				rPage.Context = data;
			}
			else
			{
				//having no page is inconsistent but must be dealt with since it can happen temporarily while binding
				rPage = new RouterPage();
			}
			
			(this as IRouterOutlet).Goto( rPage, trans, op, "" );
			if (rPage.Visual != null)
				PageData.GetOrCreate(rPage.Visual).SetContext(data);
			
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
			var v = n as Visual;
			if (v == null)
				return null;
				
			var pd = PageData.Get(v);
			if (pd == null)
				return null;
				
			return pd.Context;
		}
	}
	
}