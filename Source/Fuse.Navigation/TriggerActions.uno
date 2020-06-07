using Uno;
using Uno.UX;

using Fuse.Triggers.Actions;

namespace Fuse.Navigation
{
	public abstract class NavigationTriggerAction : TriggerAction
	{
		public INavigation NavigationContext { get; set; }

		protected override void Perform(Node n)
		{
			var ctx = NavigationContext ?? Navigation.TryFind(n);
			if (ctx == null)
			{
				Fuse.Diagnostics.UserError( "No navigation context was found", this );
				return;
			}
			Perform(ctx, n);
		}

		protected abstract void Perform(INavigation ctx, Node n);
	}

	/** Navigate to a page.

		This action is for navigating a @PageControl directly. Consider using @Router instead to perform
		more structured navigation.

		## Example

			<PageControl>
				<Page>
					<Grid Background="#282a37" Rows="auto,1*" Padding="20">
						<Image Alignment="Center" Url="https://fusetools-web.azureedge.net/fusetools-web/v1464939897151/images/logo_white.png" Width="100" Height="100" />
						<Button Text="Settings">
							<Clicked>
								<NavigateTo Target="settings" />
							</Clicked>
						</Button>
					</Grid>
				</Page>
				<Page ux:Name="settings">
					<Grid Padding="20" Rows="auto, 30" Background="#282a37">
						<Text Value="Settings" Color="#fff" Alignment="TopCenter" FontSize="20"/>
						<Slider />
					</Grid>
				</Page>
			</PageControl>
	*/
	public class NavigateTo : NavigationTriggerAction
	{
		/**
			@Page to navigate to.
		*/
		public Visual Target { get; set; }

		/**
			Avoids transition animation while navigating when set to true.
		*/
		public bool Bypass { get; set; }

		/**
			Clear forward history on navigation when set to true.
		*/
		public bool ClearForwardHistory { get; set; }

		protected override void Perform(INavigation ctx, Node n)
		{
			var mode = Bypass ? NavigationGotoMode.Bypass : NavigationGotoMode.Transition;
			if (Target != null)
			{
				ctx.Goto(Target, mode);

				if (ClearForwardHistory && ctx is StructuredNavigation)
					(ctx as StructuredNavigation).QueueClearForwardHistory();
			}
		}
	}

	/**
		Toggles a `Navigation`.

		This is currently only supported in @(EdgeNavigation), and will do nothing if used on another type of navigation.

		Used on an `EdgeNavigation`, it will navigate to and from a @(Panel) with `EdgeNavigation.Edge` set, specified by using the `Target` property.

		# Example

		This example shows the use of `NavigateToggle` by toggling the visibility of an `EdgePanel`.

			<DockPanel>
				<EdgeNavigation/>
				<Panel Width="150" Edge="Left" Background="#f63" Alignment="Left" ux:Name="nav">
					<EnteringAnimation>
				<Move X="-1" RelativeTo="Size" />
					</EnteringAnimation>
				</Panel>
				<Panel Background="#90CAF9">
					<Tapped>
						<NavigateToggle Target="nav" />
					</Tapped>
				</Panel>
			</DockPanel>
	*/
	public class NavigateToggle : TriggerAction
	{
		INavigation _context;
		[Obsolete]
		/** @deprecated 2018-03-06 */
		public INavigation NavigationContext
		{
			get { return _context; }
			set
			{
				_context = value;
				Fuse.Diagnostics.Deprecated( "NavigateToggle.NavigationContext is no longer supported as it isn't needed", this );
			}
		}

		/** The item to have its navigated state toggled. */
		public Visual Target { get; set; }

		protected override void Perform(Node n)
		{
			INavigation ctx;
			Visual ignore;
			var page = Navigation.TryFindPage((Node)Target ?? n, out ctx, out ignore);
			if (page != null)
				ctx.Toggle(page);
			else
				Fuse.Diagnostics.UserError( "No Page was found", this );
		}
	}

	public abstract class BackForwardNavigationTriggerAction : TriggerAction
	{

		public IBaseNavigation NavigationContext { get; set; }

		protected sealed override void Perform(Node n)
		{
			var nav = NavigationContext ?? Navigation.TryFindBaseNavigation(n);

			if (nav != null)
				Perform(nav, n);
			else
				Fuse.Diagnostics.UserError( "No Navigation context was found", this );
		}

		protected abstract void Perform(IBaseNavigation ctx, Node node);

	}

	/** Navigates backward in the navigation stack/z-order of a @Navigation, @PageControl, or @WebView.

		# Example
		In this example, `GoBack` will be used to navigate away from the first page of a `PageControl`.

			<PageControl>
				<Panel Background="#0F0" ux:Name="firstPage">
					<Button Text="GoBack" Alignment="Center" Margin="10">
						<Clicked>
							<GoBack />
						</Clicked>
					</Button>
				</Panel>
				<Panel Background="#F00" ux:Name="secondPage">
					<Button Alignment="Center" Text="Go to page 1">
						<Clicked>
							<NavigateTo Target="firstPage" />
						</Clicked>
					</Button>
				</Panel>
			</PageControl>

		Backward refers to pages that are behind the active one in navigation order. This trigger is not suitable for navigation that does not have a history or sequence of pages.

		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public class GoBack : BackForwardNavigationTriggerAction
	{
		protected sealed override void Perform(IBaseNavigation ctx, Node node)
		{
			if (ctx.CanGoBack)
				ctx.GoBack();
		}
	}

	/** Navigates forward in a @Navigation, @PageControl, or @WebView.

		# Example
		In this example, `GoForward` will be used to navigate back to the first page of a `PageControl`. This is because "Forward" means "towards the first page" when used in linear navigation.

			<PageControl>
				<Panel Background="#F00" ux:Name="page1">
					<Button Alignment="Center" Text="Go to page 2">
						<Clicked>
							<NavigateTo Target="page2" />
						</Clicked>
					</Button>
				</Panel>
				<Panel Background="#0F0" ux:Name="page2">
					<Button Text="Go back" Alignment="Center" Margin="10">
						<Clicked>
							<GoForward />
						</Clicked>
					</Button>
				</Panel>
			</PageControl>

		Forward refers to pages that are in front of the active one in navigation order.  This trigger is not suitable for navigation that does not have a history or sequence of pages.

		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public class GoForward : BackForwardNavigationTriggerAction
	{

		protected sealed override void Perform(IBaseNavigation ctx, Node node)
		{
			if (ctx.CanGoForward)
				ctx.GoForward();
		}

	}

}
