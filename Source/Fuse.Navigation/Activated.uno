using Uno;
using Uno.UX;

using Fuse.Triggers;

namespace Fuse.Navigation
{
	public delegate void ActivatedHandler(object sender, EventArgs args);
	
	/**
		@hide
	*/
	public abstract class NavigationTrigger : PulseTrigger<EventArgs>
	{
		internal NavigationTrigger() { }
		
		RoutePagePath _path = RoutePagePath.Full;
		/**
			Whether just the local navigation, or the full path to the root is required to be active.
			
			Default: Full
		*/
		public RoutePagePath Path
		{
			get { return _path; }
			set 
			{
				_path = value;
				if (_proxy != null)
					_proxy.Path = value;
			}
		}
		
		RoutePageTriggerWhen _when = RoutePageTriggerWhen.Stable;
		/**
			Trigger on navigation start, or only when the navigation is completed.
			
			Default: Stable
		*/
		public RoutePageTriggerWhen When
		{
			get { return _when; }
			set
			{
				_when = value;
				if (_proxy != null)
					_proxy.TriggerWhen = value;
			}
		}
		
		RoutePageProxy _proxy;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_proxy = new RoutePageProxy( Parent, ActiveChanged );
			_proxy.Path = Path;
			_proxy.TriggerWhen = When;
			_proxy.Init();
		}

		protected abstract void ActiveChanged( bool isActive, bool isRoot );
		
		protected override void OnUnrooted()
		{
			_proxy.Dispose();
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

		protected override sealed void ActiveChanged( bool isActive, bool isRoot )
		{
			if (isActive)
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

		protected sealed override void ActiveChanged( bool isActive, bool isRoot )
		{
			if (!isRoot && !isActive)
				Pulse(new EventArgs());
		}
	}
	
}
