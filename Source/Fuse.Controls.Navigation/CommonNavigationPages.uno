using Uno;
using Uno.Collections;

using Fuse.Reactive;
using Fuse.Navigation;

namespace Fuse.Controls
{
	class CommonNavigationPages
	{	
		/* Maps the bound objects to AddedPage and tracks updates on the source data */
		class PagesMap : ObserverMap<AddedPage>
		{
			CommonNavigationPages PageControl;

			public void Attach( CommonNavigationPages pageControl, IArray obs )
			{
				PageControl = pageControl;
				base.Attach( obs );
			}
			
			public new void Detach()
			{
				PageControl = null;
				base.Detach();
			}

			protected override AddedPage Map(object v)
			{
				return new AddedPage{ Data = v };
			}
			
			protected override object Unmap(AddedPage mv)
			{
				return mv.Data;
			}
			
			protected override void OnUpdated() 
			{ 
				if (PageControl != null)
					PageControl.UpdatePages();
			}
		}
		PagesMap _pagesMap = new PagesMap();

		IArray _pages;
		public IArray Pages
		{
			get { return _pages; }
			set
			{
				_pages = value;
				OnPagesChanged();
			}
		}

		NavigationControl _parent;
		public void Rooted(NavigationControl parent)
		{	
			_parent = parent;
			OnPagesChanged();
		}
		
		void OnPagesChanged()
		{
			if (_parent == null)
				return;

			_pagesMap.Detach();

			if (_pages != null)
			{
				_pagesMap.Attach( this, _pages );
			}
			else
			{
				_pagesMap.Clear();
				UpdatePages();
			}
		}
		
		public void Unrooted()
		{
			_pagesMap.Detach();
			_parent = null;
		}

		class AddedPage
		{
			public string Template;
			public Visual Visual;
			public object Data;
			public RouterPage Page;
		}
		List<AddedPage> _addedPages = new List<AddedPage>();
		void UpdatePages()
		{
			var visualCount = 0;
			
			for (int i=0; i < _pagesMap.Count; ++i)
			{
				var mp = _pagesMap[i];
				//already completed
				if (mp.Template != null && mp.Visual != null)
				{
					visualCount++;
					continue;
				}
					
				if (mp.Data == null)
				{
					Fuse.Diagnostics.UserError( "null page in list", this );
					continue;
				}
					
				mp.Template = Fuse.Navigation.PagesMap.GetObjectPath( mp.Data );
				if (mp.Template == null)
				{
					Fuse.Diagnostics.UserError( "Model is missing a $template or $page property", this);
					continue;
				}

				var f = _parent.FindTemplate(mp.Template);
				if (f == null)
				{
					Fuse.Diagnostics.UserError( "No matching template path: " + mp.Template, this );
					continue;
				}
				
				if (mp.Visual == null)
				{
					mp.Visual = f.New() as Visual;
					if (mp.Visual == null)
					{
						Fuse.Diagnostics.UserError( "Template is not a Visual: " + mp.Template, this );
						continue;
					}
				}

				mp.Page = new RouterPage( mp.Template, null, mp.Data );
				PageData.GetOrCreate(mp.Visual).AttachRouterPage( mp.Page );
				visualCount++;
			}
			
			//remove pages still used
			for (int i=0; i < _pagesMap.Count; ++i)
				_addedPages.Remove( _pagesMap[i] );
				
			//remaining are no longer used
			for (int i=0; i < _addedPages.Count; ++i)
				_parent.BeginRemoveChild( _addedPages[i].Visual );
				
			//create a new list of used pages
			_addedPages.Clear();

			var ta = new Node[visualCount];
			var vc = 0;
			for (int i=0; i < _pagesMap.Count; ++i)
			{
				if (_pagesMap[i].Visual == null)
					continue;
					
				ta[vc++] = _pagesMap[i].Visual;
				_addedPages.Add( _pagesMap[i] );
			}
			_parent.InsertOrMoveNodesAfter( (Node)_parent.Navigation, 
				((IEnumerable<Node>)ta).GetEnumerator() );
		}
	}
}
