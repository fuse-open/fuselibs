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
	/**
		 A navigation control for panels that slide in from the sides of the display.
		 
		 Add an `Edge` property to the children to define on which edge they attach. The user can swipe from that side to reveal the panel.
		 
		 Use a `GoBack` inside this navigation to dismiss side-panels from UX, or use the `dismiss` method from JavaScript.
		 
		## Model
		
		The EdgeNavigator can be bound to a model with the `Pages` property. For example:
			
			<EdgeNavigator Pages="{pages}">
				<Panel Edge="Left" ux:Template="left"/>
				<Panel Edge="Right" ux:Template="right"/>
				<Panel ux:Template="main"/>
			</EdgeNavigator>
			
		Then in your main model state you define `pages`
		
			export default class MainState {
				constructor() {
					this.pages = [ new LeftPage(), new RightPage(), new MainPage() ]
				}
			}
			
			class LeftPage {
				constructor() {
					this.$path = "left"
				}
			}
			
			class RightPage {
				constructor() {
					this.$path = "right"
				}
			}
			
			class MainPage {
				constructor() {
					this.$path = "main"
				}
			}
	*/
	public partial class EdgeNavigator : NavigationControl, IRouterOutlet
	{
		EdgeNavigation _edgeNavigation = new EdgeNavigation();

		public EdgeNavigator()
		{
			IsRouterOutlet = false; //backwards compatibility, this wasn't an outlet before but typically used within a Router
			HitTestMode = HitTestMode.LocalBounds | HitTestMode.Children;
			
			SetNavigation(_edgeNavigation);
			
			var q = new Tapped(OnTapped);
			Children.Add(q);
		}
		
		public new Fuse.Navigation.VisualNavigation Navigation
		{
			get { return base.Navigation; }
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_pages.Rooted(this);
			RootActivePage();
		}
		
		protected override void OnUnrooted()
		{
			UnrootActivePage();
			_pages.Unrooted();
			base.OnUnrooted();
		}
		
		protected override void CreateTriggers(Element elm, ControlPageData pd)
		{
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

		void SetupEdge(ControlPageData pd, Element elm,float2 rel, Alignment align)
		{
			elm.Alignment = align;
			
			var move = new Move();
			move.X = rel.X;
			move.Y = rel.Y;
			move.RelativeTo = TranslationModes.Size;
			
			var enter = new EnteringAnimation();
			enter.Animators.Add(move);
			
			pd.Enter = enter;
		}

		//very ugly way to get dismiss region, TODO: wrap better?
		void OnTapped(object s, TappedArgs args)
		{
			if (_edgeNavigation.IsDismissPoint(args.WindowPoint))
				Dismiss();
		}
		
		void Dismiss()
		{
			if (_edgeNavigation.IsAnyPanelActive() )
				_edgeNavigation.Goto(null, NavigationGotoMode.Transition);
		}
		
		void GotoEdge(NavigationEdge edge)
		{
			for (var elm = FirstChild<Visual>(); elm != null; elm = elm.NextSibling<Visual>())
			{
				var e = EdgeNavigation.GetEdge(elm);
				if (e != edge)
					continue;
				_edgeNavigation.Goto(elm, NavigationGotoMode.Transition);
				break;
			}
		}
		
		static readonly PropertyHandle _controlPageDataProperty = Fuse.Properties.CreateHandle();
	
		OutletType IRouterOutlet.Type 
		{ 
			get { return RouterOutletType; }
		}
		
		void IRouterOutlet.PartialPrepareGoto(double progress)
		{
		}
		
		void IRouterOutlet.CancelPrepare()
		{
		}
		
		RoutingResult IRouterOutlet.CompareCurrent(RouterPage routerPage, out Visual pageVisual)
		{
			return CommonNavigation.CompareCurrent(this, Active, routerPage, out pageVisual);
		}
		
		RoutingResult IRouterOutlet.Goto(RouterPage routerPage, NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle, out Visual pageVisual)
		{
			return CommonNavigation.Goto(this, routerPage, gotoMode, operation, operationStyle, out pageVisual);
		}
		
		RouterPage IRouterOutlet.GetCurrent(out Visual pageVisual)
		{
			pageVisual = Active;
			if (Active == null)
				return new RouterPage( "" );
			else
				return PageData.GetOrCreate(Active).RouterPage;
		}

		CommonNavigationPages _pages = new CommonNavigationPages();
		/**
			Provides a list of models that define the pages for the EdgeNavigator. The pages have the same structure as `PageControl.Pages`.
			
			The items in the array are objects, either explicitly created or via the Model feature. They should contain the the `$path` property which specifies the path to use. The object itself will be added to the data context for the page, allowing lookups from within the object.
		*/
		public IArray Pages
		{
			get { return _pages.Pages; }
			set { _pages.Pages = value; }
		}
		
	}
}
