using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Reactive;
using Fuse.Resources;

namespace Fuse.Navigation
{
	interface IPageResourceBinding
	{
		void UpdateSource();
	}

	[UXUnaryOperator("Page")]
	public sealed class PageExpression: Reactive.Expression
	{
		[UXValueBindingArgument]
		public string Key { get; private set; }

		[UXConstructor]
		public PageExpression([UXParameter("Key")] string key)
		{
			Key = key;
		}

		public override IDisposable Subscribe(IContext dc, IListener listener)
		{
			return new Subscription(this, dc.Node, listener);
		}

		class Subscription: IDisposable, IPageResourceBinding
		{
			PageExpression _pe;
			Node _node;
			INavigation _nav;
			Visual _currentPage;
			IListener _listener;

			public Subscription(PageExpression pe, Node node, IListener listener)
			{
				_pe = pe;
				_node = node;
				_listener = listener;
				ResourceRegistry.AddResourceChangedHandler(_pe.Key, OnChanged);
				NavigationPageProperty.RootedBindings.Add(this);
				UpdateSource();
			}

			public void UpdateSource()
			{
				var local = LocalObject;
				if (local == _nav || local == _currentPage)
					return;

				ReleaseCurrent();

				_nav = local as INavigation;
				_currentPage = local as Visual;
				if (_nav != null)
				{
					_nav.Navigated += OnNavigated;
					GotoPage(_nav.ActivePage);
				}
				else
				{
					OnChanged();
				}
			}

			void ReleaseCurrent()
			{
				if (_nav != null)
				{
					_nav.Navigated -= OnNavigated;
					_nav = null;
				}
				_currentPage = null;
			}

			public void Dispose()
			{
				ReleaseCurrent();
				NavigationPageProperty.RootedBindings.Remove(this);
				ResourceRegistry.RemoveResourceChangedHandler(_pe.Key, OnChanged);
				_listener = null;
				_node = null;
			}

			object LocalObject
			{
				get
				{
					var n = _node;
					while (n != null)
					{
						var v = n as Visual;
						if (v != null)
						{
							var page = NavigationPageProperty.GetNavigationPage(v);
							if (page != null)
								return page;

							var navi = Navigation.GetLocalNavigation(v);
							if (navi != null)
								return navi;
						}

						n = n.ContextParent;
					}

					return null;
				}
			}

			void OnNavigated(object s, NavigatedArgs args)
			{
				GotoPage(args.NewVisual);
			}

			void GotoPage(Visual page)
			{
				if (page == _currentPage)
					return;

				_currentPage = page;
				OnChanged();
			}

			void OnChanged()
			{
				var listener = _listener;
				if (listener == null) return;

				var page = _currentPage;
				if (page != null)
				{
					// TODO: keeping "Node" for backward compatibility - mortoray please review
					if ((_pe.Key == "Visual" || _pe.Key == "Node"))
					{
						listener.OnNewData(_pe, page);
					}
					else
					{
						object resource;
						if (page.TryGetResource(_pe.Key, Acceptor, out resource))
							listener.OnNewData(_pe, resource);
					}
				}
			}

			bool Acceptor(object obj)
			{
				return true;
			}
		}
	}

	internal interface IPagePropertyListener
	{
		void PageChanged(Visual where);
	}
	
	static public class NavigationPageProperty
	{
		static readonly PropertyHandle _pageProperty = Fuse.Properties.CreateHandle();

		static internal List<IPageResourceBinding> RootedBindings = new List<IPageResourceBinding>();

		static Dictionary<Visual, List<IPagePropertyListener>> _watchers = 
			new Dictionary<Visual, List<IPagePropertyListener>>();
		
		static List<IPagePropertyListener> GetWatcherList(Visual where, bool optional = false)
		{
			List<IPagePropertyListener> o;
			if (_watchers.TryGetValue(where, out o))
				return o;
				
			if (optional)
				return null;
				
			var q = new List<IPagePropertyListener>();
			_watchers.Add(where, q);
			return q;
		}
		
		static internal void AddPageWatcher(Visual where, IPagePropertyListener callback)
		{
			GetWatcherList(where).Add(callback);
		}
		
		static internal void RemovePageWatcher(Visual where, IPagePropertyListener callback)
		{
			var list = GetWatcherList(where, true);
			if (list == null)
				return;
				
			list.Remove(callback);
			if (list.Count == 0)
				_watchers.Remove(where);
		}
		
		[UXAttachedPropertySetter("Navigation.Page")]
		public static void SetNavigationPage(Visual n, Visual page)
		{
			var old = GetNavigationPage(n);
			if (old == page)
				return;
				
			n.Properties.Set(_pageProperty, page);
			UpdateListeners(n);
		}
		
		static void UpdateListeners(Visual node)
		{
			//TODO: replace with listeners
			foreach (var binding in RootedBindings)
				binding.UpdateSource();
				
			//iterate up looking for anything that might be affected by this change
			while (node != null)
			{
				var list = GetWatcherList(node, true);
				if (list != null)
				{
					//need copy since may be modified during callback (could be optimized to avoid this)
					var dup = new List<IPagePropertyListener>();
					for (int i=0; i < list.Count; ++i)
						dup.Add(list[i]);
						
					for (int i=0; i < dup.Count; ++i)
						dup[i].PageChanged(node);
				}
				
				node = node.Parent;
			}
		}
		

		[UXAttachedPropertyGetter("Navigation.Page")]
		public static Visual GetNavigationPage(Visual n)
		{
			object v;
			if (n.Properties.TryGet(_pageProperty, out v))
				return (Visual)v;
			return null;
		}

		[UXAttachedPropertyResetter("Navigation.Page")]
		public static void ResetNavigationPage(Visual n)
		{
			n.Properties.Clear(_pageProperty);
			UpdateListeners(n);
		}
	}
}
