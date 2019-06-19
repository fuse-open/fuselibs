using Uno;
using Uno.UX;

using Fuse.Animations;
using Fuse.Elements;
using Fuse.Gestures;
using Fuse.Navigation;
using Fuse.Triggers.Actions;

namespace Fuse.Controls
{
	public enum NavigatorSwipeDirection
	{
		/** No swiping is enabled. */
		None,
		/** Used on pages to indicate they should use the Navigator swipe direction */
		Default,
		Left,
		LeftEdge,
		Up,
		Bottom,
		Right,
		RightEdge,
		Down,
		Top,
	}
	
	public enum NavigatorSwipeHow
	{
		/** Navigates back one step in the navigation history. Will give error if swiped further back than possible. */
		Back,
		/** Pushes the bookmark path to the navigation history, and navigates to it */
		PushBookmark,
		/** Navigates to the bookmark path, deleting the navigation history in the process */
		GotoBookmark,
	}

	/**
		Allows navigation through swipe gestures.
		
		We can control the behavior of a `NavigatorSwipe` using the `How` parameter, which controls what happens when the specified direction is swiped. `PushBookmark` and `GotoBookmark` both
		navigate to the bookmark specified by the `Bookmark` property in their own way(same behavior as @(Router) ). `Back` navigates backwards, but should be used with caution, 
		as it does not check if there is anything to go back to, meaning it can generate errors.
		
		In the following example, we demonstrate `NavigatorSwipe` being used on both a `Navigator`, and navigated pages. Some navigation rules are set up:

		 * Swiping up while on the blue panel will go to a bookmark pointing to the indigo page. 
		 * Swiping up while on the indigo page will navigate you to the red page. 
		 * Swiping down on any page will go back to the previous page.
		
			<Panel>
				<Router ux:Name="router" />

				<JavaScript>
				    router.bookmark({
				        name: "indigo",
				        path: [ "indigoPanel", { } ]
				    });
				    router.bookmark({
				        name: "red",
				        path: [ "redPanel", { } ]
				    });
				</JavaScript>

				<DockPanel ux:Class="NamedPanel">
					<string ux:Property="Title" />
					<Text Value="{Property Title}" FontSize="30" Alignment="TopCenter" Margin="20" />
				</DockPanel>
				<Navigator DefaultPath="bluePanel">
					<NamedPanel Title="Blue panel" ux:Template="bluePanel" Color="#2196F3">
						<NavigatorSwipe How="PushBookmark" Bookmark="indigo" Direction="Up"/>
					</NamedPanel>
					<NamedPanel Title="Red panel" ux:Template="redPanel" Color="#F44336" />
					<NamedPanel Title="Indigo panel" ux:Template="indigoPanel" Color="#3F51B5">
						<NavigatorSwipe How="PushBookmark" Bookmark="red" Direction="Up"/>
					</NamedPanel>
					<NavigatorSwipe How="Back" Direction="Down"/>
				</Navigator>
			</Panel>
	*/
	public class NavigatorSwipe : NodeGroupBase
	{
		NavigatorSwipeDirection _direction = NavigatorSwipeDirection.None;
		public NavigatorSwipeDirection Direction
		{
			get { return _direction; }
			set 
			{ 
				_direction = value;
				if (_swipeGesture != null)
				{
					SetupGestureSwipeDerection();
					_swipeGesture.IsEnabled = Direction != NavigatorSwipeDirection.None;
				}
			}
		}

		void SetupGestureSwipeDerection()
		{
			switch (Direction)
			{
				case NavigatorSwipeDirection.Left:
					_swipeGesture.Direction = Fuse.Gestures.SwipeDirection.Left;
					break;
				case NavigatorSwipeDirection.Right:
					_swipeGesture.Direction =  Fuse.Gestures.SwipeDirection.Right;
					break;
				case NavigatorSwipeDirection.Up:
					_swipeGesture.Direction =  Fuse.Gestures.SwipeDirection.Up;
					break;
				case NavigatorSwipeDirection.Down:
					_swipeGesture.Direction = Fuse.Gestures.SwipeDirection.Down;
					break;
				case NavigatorSwipeDirection.LeftEdge:
					_swipeGesture.Edge = Fuse.Gestures.Edge.Left;
					break;
				case NavigatorSwipeDirection.RightEdge:
					_swipeGesture.Edge = Fuse.Gestures.Edge.Right;
					break;
				case NavigatorSwipeDirection.Top:
					_swipeGesture.Edge = Fuse.Gestures.Edge.Top;
					break;
				case NavigatorSwipeDirection.Bottom:
					_swipeGesture.Edge = Fuse.Gestures.Edge.Bottom;
					break;
			}
		}

		public bool IsEnabled
		{
			get { return UseContent; }
			set { UseContent = value; }
		}
		
		NavigatorSwipeHow _how;
		public NavigatorSwipeHow How
		{
			get { return _how; }
			set 
			{ 
				_how = value; 
				switch (_how)
				{
					case NavigatorSwipeHow.Back:
						_modify.How = ModifyRouteHow.PrepareBack;
						break;
					case NavigatorSwipeHow.PushBookmark:
						_modify.How = ModifyRouteHow.PreparePush;
						break;
					case NavigatorSwipeHow.GotoBookmark:
						_modify.How = ModifyRouteHow.PrepareGoto;
						break;
				}
			}
		}
		
		string _bookmark;
		public string Bookmark
		{
			get { return _modify.Bookmark; }
			set  { _modify.Bookmark = value; }
		}
		
		public string Style 
		{ 
			get { return _modify.Style; }
			set { _modify.Style = value; }
		}
		
		SwipeGesture _swipeGesture = new SwipeGesture();
		SwipingAnimation _swipeAnim;
		Swiped _swipedCompleted;
		Swiped _swipedCancelled;
		RouterModify _modify = new RouterModify(RouterModify.Flags.None){ 
			When = TriggerWhen.Start };
		Router _router;
		Animator _prepareAnim;
		
		public NavigatorSwipe()
		{
			UseContent = true;
			
			How = NavigatorSwipeHow.Back;
			
			_swipeAnim = new SwipingAnimation(_swipeGesture);
			_swipeAnim.Actions.Add( _modify );

			_swipedCompleted = new Swiped(_swipeGesture );
			_swipedCompleted.Actions.Add( new RouterModify(RouterModify.Flags.None){
				How = ModifyRouteHow.FinishPrepared });
				
			_swipedCancelled = new Swiped(_swipeGesture);
			_swipedCancelled.How = SwipedHow.Cancelled;
			_swipedCancelled.Actions.Add( new RouterCancelNavigation() );
			
			Nodes.Add(_swipeGesture);
			Nodes.Add(_swipeAnim);
			Nodes.Add(_swipedCompleted);
			Nodes.Add(_swipedCancelled);
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			_router = Router.TryFindRouter(this);
			if (_router == null)
			{
				Fuse.Diagnostics.UserError( "SwipeNavigator requires a Router for interaction", this );
				return;
			}
			if (!(Parent is Element))
			{
				Fuse.Diagnostics.UserError( "SwipeNavigator requires an Element parent", this );
				return;
			}
	
			SetupGestureSwipeDerection();
			_swipeGesture.LengthNode = Parent as Element;
			_swipeGesture.IsEnabled = Direction != NavigatorSwipeDirection.None;
			
			_prepareAnim = new Change<double>(new Router_PrepareProgress_Property(_router)){
				Value = 1,
				};
			_swipeAnim.Animators.Add( _prepareAnim );
		}
		
		protected override void OnUnrooted()
		{
			_swipeAnim.Animators.Remove( _prepareAnim );
			_prepareAnim = null;
			_router = null;
			base.OnUnrooted();
		}
	}
	
	class Router_PrepareProgress_Property: Uno.UX.Property<double>
	{
		Router _obj;
		public Router_PrepareProgress_Property(Router obj) : base("PrepareProgress") { _obj = obj; }
		public override global::Uno.UX.PropertyObject Object { get { return _obj; } }
		public override double Get(PropertyObject obj) { return ((Router)obj).PrepareProgress; }
		public override void Set(PropertyObject obj, double v, global::Uno.UX.IPropertyListener origin) { ((Router)obj).PrepareProgress = v; }
		public override bool SupportsOriginSetter { get { return false; } }
	}
}
