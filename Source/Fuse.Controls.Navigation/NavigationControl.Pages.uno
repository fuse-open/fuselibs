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
			
			The `$navigationRequest` property may be used to fine-tune how transitions to the pages performed. Without this property the control will infer the type of transition based on how the array has been modified. The properties are a subset of those offered by `modifyPath`:
			
				- `transition`: Either `Bypass` or `Transition`
				- `style`: The style of the operation, which can be used as a matching criteria in transitions.
				- `operation`: `Pop`, `Replace`, `Push` or `Goto`
		*/
		public IArray PageHistory
		{
			get { return _pageHistory; }
			set
			{
				_pageHistory = value;
				if (IsRootingCompleted)
				{
					OnPageHistoryChanged();
					FullUpdatePages(UpdateFlags.ForceGoto | UpdateFlags.Bypass);
				}
			}
		}
		
		int _curPageIndex = -1;
		void OnPageHistoryChanged()
		{
			if (AncestorRouterPage == null)
				return;
				
			AncestorRouterPage.ChildRouterPages.Detach();
			
			if (_pageHistory == null)
				return;
			var obs = _pageHistory as IObservableArray;
			if (obs != null)
			{
				AncestorRouterPage.ChildRouterPages.Attach( obs, this );
			}
			else
			{
				Fuse.Diagnostics.UserError( "PageHistory expects an observable array. It will not work correctly otherwise", this );
			}
				
			_curPageIndex = -1;
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
			Bypass = 1 << 3,
		}

		/*
			By the time this is called the backing ChildRouterPages map will already have the object, mapped with the path and context. 
		*/
		void FullUpdatePages(UpdateFlags flags = UpdateFlags.None)
		{
			int pageNdx = _pageHistory.Length - 1;
				
			var rr = new RouterRequest();
			rr.Operation = pageNdx < _curPageIndex ? RoutingOperation.Pop :
				pageNdx == _curPageIndex ? RoutingOperation.Replace :
				pageNdx > 0 ? RoutingOperation.Push : 
				RoutingOperation.Goto;
			if (flags.HasFlag(UpdateFlags.ForceGoto))
				rr.Operation = RoutingOperation.Goto;
			else if (flags.HasFlag(UpdateFlags.Add))
				rr.Operation = pageNdx > 0 ? RoutingOperation.Push : RoutingOperation.Goto;
			else if (flags.HasFlag(UpdateFlags.Replace))
				rr.Operation = RoutingOperation.Replace;
				
			rr.Transition = flags.HasFlag(UpdateFlags.Bypass) ? NavigationGotoMode.Bypass : NavigationGotoMode.Transition;
			
			RouterPage rPage;
			if (pageNdx >= AncestorRouterPage.ChildRouterPages.Count)
			{
				rPage = RouterPage.CreateDefault();
				Fuse.Diagnostics.InternalError( "Inconsistent navigation history", this );
			}
			else if (pageNdx >= 0)
			{
				//this is expected, since the PagesMap will do the mapping
				rPage = AncestorRouterPage.ChildRouterPages[pageNdx];
			}
			else
			{
				//having no page is inconsistent but must be dealt with since it can happen temporarily while binding
				rPage = RouterPage.CreateDefault();
			}
			
			//adapt request
			IObject navRequest = RouterPage.GetNavigationRequest( rPage.Context );
			if (navRequest != null)
			{
				if (!rr.AddArguments(navRequest, RouterRequest.Fields.Transition | 	
					RouterRequest.Fields.Style | RouterRequest.Fields.Operation))
				{
					Fuse.Diagnostics.UserError( "Invalid $navigationRequest, visual result may not match expectation", this );
					//continue anyway since the resulting state is still valid
				}
			}
			
			Visual ignore;
			((IRouterOutlet)this).Goto( rPage, rr.Transition, rr.Operation, rr.Style, out ignore );
			
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
		
		ContextDataResult ISubtreeDataProvider.TryGetDataProvider( Node n, DataType type, out object provider )
		{
			provider = null;
			var v = n as Visual;
			if (v == null)
				return ContextDataResult.Continue;
				
			var pd = PageData.Get(v);
			if (pd == null)
				return ContextDataResult.Continue;
			
			provider = pd.Context;
			return type == DataType.Prime ? ContextDataResult.NullProvider : ContextDataResult.Continue;
		}
	}
	
}