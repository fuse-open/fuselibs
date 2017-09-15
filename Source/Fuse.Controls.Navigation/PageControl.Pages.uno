using Uno;
using Uno.Collections;

using Fuse.Reactive;
using Fuse.Navigation;

namespace Fuse.Controls
{
	public partial class PageControl
	{	
		//extra class as NavigationControl is already a Fuse.Reactive.IObserver
		class PagesListener : Fuse.Reactive.IObserver
		{
			[WeakReference]
			PageControl PageControl;

			public PagesListener( PageControl pageControl, Fuse.Reactive.IObservable data )
			{
				PageControl = pageControl;
				_data = data;
				_subscription = data.Subscribe(this);
			}

			Uno.IDisposable _subscription;
			Fuse.Reactive.IObservable _data;

			public void Dispose()
			{
				if (_subscription != null)
				{
					_subscription.Dispose();
					_subscription = null;
				}
			}

			void Fuse.Reactive.IObserver.OnSet(object newValue) { PageControl.UpdatePages(); }
			void Fuse.Reactive.IObserver.OnFailed(string message ) { PageControl.UpdatePages(); }
			void Fuse.Reactive.IObserver.OnAdd(object value) { PageControl.UpdatePages(); }
			void Fuse.Reactive.IObserver.OnRemoveAt(int index) { PageControl.UpdatePages(); }
			void Fuse.Reactive.IObserver.OnInsertAt(int index, object value) { PageControl.UpdatePages(); }
			void Fuse.Reactive.IObserver.OnNewAt(int index, object value) { PageControl.UpdatePages(); }
			void Fuse.Reactive.IObserver.OnNewAll(IArray values) { PageControl.UpdatePages(); }
			void Fuse.Reactive.IObserver.OnClear() { PageControl.UpdatePages(); }
		}
		PagesListener _pagesListener;

		IArray _pages;
		/**
			Provides a list of models that define the pages for the page control. The pages have the same structure as `Navigator.Pages` -- but here they do not define a history. To control what is the current page bind to `ActiveIndex`.
			
			The items in the array are objects, either explicitly created or via the Model feature. They should contain the the `$path` property which specifies the path to use. The object itself will be added to the data context for the page, allowing lookups from within the object.
		*/
		public IArray Pages
		{
			get { return _pages; }
			set
			{
				_pages = value;
				OnPagesChanged();
			}
		}

		void OnPagesChanged()
		{
			if (!IsRootingStarted)
				return;

			if (_pagesListener != null)
			{
				_pagesListener.Dispose();
				_pagesListener = null;
			}

			if (_pages != null)
			{
				var obs = _pages as Fuse.Reactive.IObservable;
				if (obs != null)
					_pagesListener = new PagesListener( this, obs );
			}
			
			UpdatePages();
		}

		List<Visual> _addedPages;
		void UpdatePages()
		{
			List<Visual> toAdd = null;
			
			if (_pages != null)
			{
				toAdd = new List<Visual>();
				for (int i=0; i < _pages.Length; ++i)
				{
					var page = _pages[i];
					var path = GetObjectPath( page );
					if (path == null)
					{
						Fuse.Diagnostics.UserError( "Model is missing a $template or $page property", this);
						continue;
					}

					var f = FindTemplate(path);
					if (f == null)
					{
						Fuse.Diagnostics.UserError( "No matching template path: " + path, this );
						continue;
					}
					
					var useVisual = f.New() as Visual;
					UpdateContextData( useVisual, page );
					toAdd.Add( useVisual );
				}
			}
			
			if (_addedPages != null)
			{
				if (toAdd != null)
				{
					for (int i=0; i < toAdd.Count; ++i)
						_addedPages.Remove( toAdd[i] );
				}
				
				//remaining are no longer used
				for (int i=0; i < _addedPages.Count; ++i)
					BeginRemoveChild( _addedPages[i] );
				_addedPages = null;
			}
			
			if (toAdd != null)
			{
				var ta = new Node[toAdd.Count];
				for (int i=0; i < toAdd.Count; ++i)
					ta[i] = toAdd[i];
				InsertOrMoveNodesAfter( (Node)Navigation, ((IEnumerable<Node>)ta).GetEnumerator() );
				_addedPages = toAdd;
			}
		}
	}
}
