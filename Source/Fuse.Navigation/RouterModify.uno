using Uno;
using Uno.UX;

using Fuse.Triggers.Actions;
using Fuse.Reactive;

namespace Fuse.Navigation
{
	/**
		Performs a transition on the router with extended options.

		> Note: there is also a JavaScript interface for [Router.modify](api:fuse/navigation/router/modify_eca3d620).

		Basic use requires setting the property `Bookmark` to specify the route to navigate to,
		and the `How` property to specify what navigation action will be used, most frequently `Push` or `Goto`.

			<Router ux:Name="router" />
			...
			<JavaScript>
				router.bookmark({
					name: "myBookmark",
					path: ["myPage", {}, "mySubpage", {}]
				});
			</JavaScript>
			...
			<Panel>
				<Clicked>
					<RouterModify How="Push" Bookmark="myBookmark" />
				</Clicked>
				<Text Value="Open subpage" />
			</Panel>

		If we only need to go back in navigation history, the `Bookmark` property can be omitted:

			<RouterModify How="GoBack" />

		When using `Navigator` or `PageControl`, the default transitions can be overriden by setting `Transition`
		and `Style` properties on `RouterModify`. This pushes another page without a transition:

			<RouterModify How="Push" Transition="Bypass" Bookmark="myBookmark" />

		We can use the `Style` property to refer to specific `Transition` triggers on target pages, allowing us
		to trigger different transitions for separate use cases:

			<Router ux:Name="router" />
			...
			<JavaScript>
				router.bookmark({
					name: "myBookmark",
					path: ["secondPage", {}]
				});
			</JavaScript>
			...
			<Navigator DefaultPath="firstPage">
				<StackPanel ux:Template="firstPage">
					<Panel>
						<Clicked>
							<RouterModify How="Push" Bookmark="myBookmark" Style="fromTop" />
						</Clicked>
						<Text Value="Transition from top" />
					</Panel>
					<Panel>
						<Clicked>
							<RouterModify How="Push" Bookmark="myBookmark" Style="fromBottom" />
						</Clicked>
						<Text Value="Transition from bottom" />
					</Panel>
				</StackPanel>

				<Panel ux:Template="secondPage">
					<Transition Style="fromTop">
						<Move Y="-1" RelativeTo="ParentSize" Duration="0.4" Easing="SinusoidalInOut" />
					</Transition>
					<Transition Style="fromBottom">
						<Move Y="1" RelativeTo="ParentSize" Duration="0.4" Easing="SinusoidalInOut" />
					</Transition>
					<Clicked>
						<RouterModify How="GoBack" />
					</Clicked>
					<Text Value="Go back" />
				</Panel>
			</Navigator>
	*/
	public class RouterModify : TriggerAction, IListener
	{
		/** The router to use. If this is null (default) then it looks through the ancestor nodes to find the nearest router. */
		public Router Router { get; set; }
		
		ModifyRouteHow _how = ModifyRouteHow.Goto;
		/** How to modify the router. */
		public ModifyRouteHow How
		{
			get { return _how; }
			set { _how = value; }
		}
		
		/** Get the route from this bookmark. */
		public string Bookmark { get; set; }
		
		NavigationGotoMode _transition = NavigationGotoMode.Transition;
		/** How to transition to the new page. */
		public NavigationGotoMode Transition
		{
			get { return _transition; }
			set { _transition = value; }
		}
		
		/** The operation style of the transition. */
		public string Style { get; set; }

		/* This is an IExpression since the claculation of the path might be costly (in terms of setup
			and evaluation), and we don't want it to keep updating unless it is actually used. */
		/** The target path */
		public IExpression Path { get; set; }
		
		NodeExpressionBinding _pathSub;

		/*protected override void OnUnrooted()
		{
			DisposePathSub();
			base.OnUnrooted();
		}*/
		
		protected override void Perform(Node n)
		{
			if (Path != null)
			{
				DisposePathSub();
				debug_log "Perform:" + n;
				_pathSub = new NodeExpressionBinding(Path, n, this);
				_pathSub.Init();
			}
			else
			{
				PerformRoute(n, null);
			}
		}
		
		void DisposePathSub()
		{
			if (_pathSub != null)
			{
				_pathSub.Dispose();
				_pathSub = null;
			}
		}
		
		void IListener.OnNewData(IExpression source, object value)
		{
			if (source != Path || _pathSub == null)
				return;
		
			try
			{
				Route route = null;
				if (value is string)
				{
					route = new Route((string)value);
				}
				else if (value is IArray)
				{
					var iarr = value as IArray;
					debug_log "Array:" + iarr.Length;
					for (int i= ((iarr.Length-1)/2)*2; i>=0; i -= 2)
					{
						string path;
						if (!Marshal.TryToType<string>(iarr[i], out path))
						{
							Fuse.Diagnostics.UserError( "invalid path component: " + iarr[i], this);
							return;
						}
						string param = null;
						if (i+1 < iarr.Length)
						{
							param = Json.Stringify( iarr[i+1], true);
						}
						
						route =  new Route(path, param, route);
					}
				}
				else
				{
					debug_log value + " :: " + value.GetType();
					Fuse.Diagnostics.UserError("incompatible path", this);
					return;
				}
				
				PerformRoute( (_pathSub as IContext).Node, route);
			}
			finally
			{
				DisposePathSub();
			}
		}
			
		void PerformRoute(Node n, Route route)
		{
			debug_log "Perform:" + n + ":" +route.Format();
			var useRouter = Router ?? Fuse.Navigation.Router.TryFindRouter(n);
			if (useRouter == null)
			{
				Fuse.Diagnostics.UserError( "Router not set and none could be found", this );
				return;
			}
			
			if (Bookmark != null)
			{
				if (!useRouter.Bookmarks.TryGetValue(Bookmark, out route))
				{
					Fuse.Diagnostics.UserError( "Unknown bookmark: " + Bookmark, this );
					return;
				}
			}
			
			useRouter.Modify( How, route, Transition, Style );
		}
	}
	
}