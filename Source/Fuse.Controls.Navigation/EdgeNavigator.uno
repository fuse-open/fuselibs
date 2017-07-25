using Uno;
using Uno.UX;

using Fuse;
using Fuse.Animations;
using Fuse.Elements;
using Fuse.Gestures;
using Fuse.Navigation;
using Fuse.Triggers;

namespace Fuse.Controls
{
	public partial class EdgeNavigator : Panel
	{
		EdgeNavigation _navigation = new EdgeNavigation();

		public EdgeNavigator()
		{
			ClipToBounds = true;
			
			Children.Add(_navigation);
			
			var q = new Tapped(OnTapped);
			Children.Add(q);
		}
		
		public Fuse.Navigation.VisualNavigation Navigation
		{	
			get { return _navigation; }
		}
		
		public Visual Active
		{
			get { return _navigation.Active; }
			set { _navigation.Active = value; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			
			for (int i=0; i < _navigation.Pages.Count; ++i)
				UpdateChild(_navigation.Pages[i].Visual);
		}
		
		protected override void OnUnrooted()
		{
			for (int i=0; i < _navigation.Pages.Count; ++i)
				CleanupChild(_navigation.Pages[i].Visual);
				
			base.OnUnrooted();
		}
		
		protected override void OnChildAdded(Node o)
		{
			base.OnChildAdded(o);
			if (IsRootingCompleted && Fuse.Navigation.Navigation.IsPage(o))
				UpdateChild(o);
		}
		
		void UpdateChild(Node o)
		{
			var elm = o as Element;
			if (elm == null)
				return;
				
			var pd = GetPageData(elm);
			CleanupChild(pd,elm);
			var e = EdgeNavigation.GetEdge(elm);
			switch(e)
			{
				case NavigationEdge.Left: 
					SetupEdge(pd, elm, float2(-1,0), Alignment.Left); 
					break;
				case NavigationEdge.Right: 
					SetupEdge(pd, elm, float2(1,0), Alignment.Right); 
					break;
				case NavigationEdge.Top: 
					SetupEdge(pd, elm, float2(0,-1), Alignment.Top);
					break;
				case NavigationEdge.Bottom: 
					SetupEdge(pd, elm, float2(0,1), Alignment.Bottom); 
					break;
				case NavigationEdge.None: 
					break;
			}
		}

		protected override void OnChildRemoved(Node o)
		{
			base.OnChildRemoved(o);
			if (IsRootingCompleted)
				CleanupChild(o);
		}
		
		void CleanupChild(Node o)
		{
			var elm = o as Element;
			if (elm != null) 
			{
				var pd = GetPageData(elm, false);
				if (pd != null)
					CleanupChild(pd,elm);
			}
		}

		void SetupEdge(PageData pd, Element elm,float2 rel, Alignment align)
		{
			elm.Alignment = align;
			
			var move = new Move();
			move.X = rel.X;
			move.Y = rel.Y;
			move.RelativeTo = TranslationModes.Size;
			
			var enter = new EnteringAnimation();
			enter.Animators.Add(move);
			
			pd.Enter = enter;
			elm.Children.Add(enter);
		}

		void CleanupChild(PageData pd, Visual elm)
		{
			if (pd.Enter != null)
			{
				elm.Children.Remove(pd.Enter);
				pd.Enter = null;
			}
		}
		
		//very ugly way to get dismiss region, TODO: wrap better?
		void OnTapped(object s, TappedArgs args)
		{
			if (_navigation.IsDismissPoint(args.WindowPoint))
				Dismiss();
		}
		
		void Dismiss()
		{
			if (_navigation.IsAnyPanelActive() )
				_navigation.Goto(null, NavigationGotoMode.Transition);
		}
		
		void GotoEdge(NavigationEdge edge)
		{
			for (var elm = FirstChild<Visual>(); elm != null; elm = elm.NextSibling<Visual>())
			{
				var e = EdgeNavigation.GetEdge(elm);
				if (e != edge)
					continue;
				_navigation.Goto(elm, NavigationGotoMode.Transition);
				break;
			}
		}
		
		static readonly PropertyHandle _pageDataProperty = Fuse.Properties.CreateHandle();
	
		class PageData
		{
			public Trigger Enter;
		}
		
		static PageData GetPageData(Element elm, bool create = true)
		{
			object v;
			if (elm.Properties.TryGet(_pageDataProperty, out v))
				return (PageData)v;
				
			if (!create)
				return null;
				
			var sd = new PageData();
			elm.Properties.Set(_pageDataProperty, sd);
			return sd;
		}
		
	}
}
