using Uno;
using Uno.UX;

using Fuse.Triggers;

namespace Fuse.Navigation
{
	public delegate void ActivatedHandler(object sender, EventArgs args);
	
	public abstract class NavigationTrigger : PulseTrigger<EventArgs>
	{
		internal NavigationTrigger() { }
		
		protected Visual PageContext { get { return _proxy.Page; } }
		protected INavigation NavContext { get { return _proxy.Navigation; } }
		NavigationPageProxy _proxy;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_proxy = new NavigationPageProxy(NavReady,NavUnready);
			_proxy.Rooted(Parent);
		}
		
		abstract protected void NavReady();
		abstract protected void NavUnready();

		protected override void OnUnrooted()
		{
			_proxy.Unrooted();
			_proxy = null;
			base.OnUnrooted();
		}
	}

	/** Active whenever a page becomes active.
		
		This trigger will also be pulsed at rooting time if the page is currently the active one.

		## Example

		This example will print to the console whenever the each of the two pages is activated:

			<PageControl>
				<Page Background="Red">
					<Activated>
						<DebugAction Message="Red page activated" />
					</Activated>
				</Page>
				<Page Background="Blue">
					<Activated>
						<DebugAction Message="Blue page activated" />
					</Activated>
				</Page>
			</PageControl>

		Note that this trigger may also be used as an attached event directly on a `Page`, like so:
		
			<Page Activated="{jsActivated}">
			</Page>
	*/
	public class Activated : NavigationTrigger
	{
		[UXAttachedEventAdder("Navigation.Activated")]
		/** Adds a handler for when the page is @Activated */
		public static void AddHandler(Visual visual, PulseHandler handler)
		{
			AddHandlerImpl<Activated>(visual, handler);
		}

		[UXAttachedEventRemover("Navigation.Activated")]
		public static void RemoveHandler(Visual visual, PulseHandler handler)
		{
			RemoveHandlerImpl<Activated>(visual, handler);
		}
	
		protected override void NavReady()
		{
			//guaranteed to trigger once during rooting if page is already active
			if (NavContext.ActivePage == PageContext)
				Pulse();
				
			NavContext.ActivePageChanged += OnActivePageChanged;
		}
		
		protected override void NavUnready()
		{
			NavContext.ActivePageChanged -= OnActivePageChanged;
		}
		
		void OnActivePageChanged(object s, Visual active)
		{
			if (active == PageContext)
				Pulse(new EventArgs());
		}
	}

	/** Active whenever a page becomes inactive.
		
		This trigger may not pulse when the trigger, navigation, or the page is unrooted.

		## Example

		This example will print to the console whenever the each of the two pages is deactivated:

			<PageControl>
				<Page Background="Red">
					<Deactivated>
						<DebugAction Message="Red page deactivated" />
					</Deactivated>
				</Page>
				<Page Background="Blue">
					<Deactivated>
						<DebugAction Message="Blue page deactivated" />
					</Deactivated>
				</Page>
			</PageControl>
		
		Note that this trigger may also be used as an attached event directly on a `Page`, like so:
		
			<Page Deactivated="{jsDeactivated}">
			</Page>
	*/
	public class Deactivated : NavigationTrigger
	{
		[UXAttachedEventAdder("Navigation.Deactivated")]
		/** Adds a handler for when the page is @Deactivated */
		public static void AddHandler(Visual visual, PulseHandler handler)
		{
			AddHandlerImpl<Deactivated>(visual, handler);
		}

		[UXAttachedEventRemover("Navigation.Deactivated")]
		public static void RemoveHandler(Visual visual, PulseHandler handler)
		{
			RemoveHandlerImpl<Deactivated>(visual, handler);
		}
		
		bool _isActive;
		protected override void NavReady()
		{
			_isActive = NavContext.ActivePage == PageContext;
			NavContext.ActivePageChanged += OnActivePageChanged;
		}
		
		protected override void NavUnready()
		{
			NavContext.ActivePageChanged -= OnActivePageChanged;
		}
		
		void OnActivePageChanged(object s, Visual active)
		{
			bool _newActive = NavContext.ActivePage == PageContext;
			if (_newActive == _isActive)
				return;
			_isActive = _newActive;
			if (!_isActive)
				Pulse(new EventArgs());
		}
	}
	
}
