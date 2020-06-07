using Uno;

using Fuse;
using Fuse.Animations;
using Fuse.Triggers;

namespace Fuse.Navigation
{
	/**
		These triggers respond to the current "activation" state of a page.

		[subclass Fuse.Navigation.NavigationAnimation]

		The states of these triggers depends on the page progress of a page, where 0 is active and +/-1 (or higher) is inactive. These values are logically mapped into a range from 0...1 for each trigger, where 0 is the definitive "off" state of the trigger and 1 is the "on" state.

		Values in between are considered to be in transition. The `Threshold` and `Limit` properties can be used to adjust when these triggers flip between active/inactive on continuous navigation.

		If the navigation is discrete, such as with `Navigator` or `DirectNavigation` the `Threshold` will have no effect as pages are either `0` or `1` in progress. The `Limit` property should also not be used since it will also be ineffectual.

		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public abstract class WhileNavigationTrigger : WhileTrigger
	{
		internal WhileNavigationTrigger() {}

		float _threshold = 1;
		/**
			At which progress should this trigger become active.

			The default is `1`, meaning the trigger will only become active when the page is fully reaches the matching state; partial page progress will be ignored.

			Using the threshold we can lower the point at which the trigger is activated.

				<Page ux:Class="MyPage" Color="#FAA">
					<WhileActive Threshold="0.5">
						<Change this.Color="#AFA"/>
					</WhileActive>
				</Page>
				<PageControl Active="B">
					<MyPage ux:Name="A"/>
					<MyPage ux:Name="B"/>
					<MyPage ux:Name="C"/>
				</PageControl>

			As the user swipes from B to C the progress of B will reduce from 1 towards 0 and the progress of C increases from 0 towards 1. The `Threadhold="0.5"` here causes the trigger swtich at the mid-way point of the transition. In this setup this means that one page is green and the rest are red -- the one closest to active is green.
		*/
		public float Threshold
		{
			get { return _threshold; }
			set { _threshold = value; }
		}

		float _limit;
		bool _hasLimit;
		/**
			An optional limit for when the trigger is active. A progress past this limit will deactivate the trigger.
		*/
		public float Limit
		{
			get { return _limit; }
			set
			{
				_limit = value;
				_hasLimit = true;
			}
		}

		RoutePagePath _path = RoutePagePath.Full;
		/**
			Whether the page just needs to be active in the local navigation or the the full path to the root needs to be active.

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

		RoutePageProxy _proxy;

		protected override void OnRooted()
		{
			base.OnRooted();
			_proxy = new RoutePageProxy(Parent, ProgressUpdated);
			_proxy.Path = Path;
			_proxy.Init();
		}

		protected override void OnUnrooted()
		{
			_proxy.Dispose();
			_proxy = null;
			base.OnUnrooted();
		}

		void ProgressUpdated( double progress )
		{
			progress = MapProgress(progress);
			var set = progress >= Threshold;
			if (_hasLimit)
				set = set && progress <= Limit;
			SetActive( set );
		}

		internal abstract double MapProgress( double progress );
	}

	/**
		Animates while the page is active.

		## Example

		The following example changes the value of a @Text element to `Active` when the
		first page of a @PageControl is active. We set the `Threshold` high to make the
		change happen later when transitioning to the page.

			<PageControl>
				<Page>
					<Panel Alignment="Center">
						<Text ux:Name="text">Inactive</Text>
						<WhileActive Threshold="0.9">
							<Change text.Value="Active" />
						</WhileActive>
					</Panel>
				</Page>
				<Page Background="Blue" />
			</PageControl>

		The progress of this trigger for a page is calculated as `1 - distance_to_active`. So a page progress of 0 will map to `1` for this trigger, and anything more than `1` away from the active page will be `0`. For example, the `Threshold="0.9"` in the above example means the trigger will become active when the page has been swiped 90% of the way to active, instead of waiting to 100%.
	*/
	public class WhileActive : WhileNavigationTrigger
	{
		internal override double MapProgress( double progress )
		{
			return 1 - Math.Min( 1, Math.Abs(progress) );
		}
	}

	/**
		Animates while the page is inactive.

		## Example

		The following example changes the value of a @Text element to `Inactive` when the
		first page of a @PageControl is inactive. We set the `Threshold` low to make the
		change happen earlier when transitioning from the page.

			<PageControl>
				<Page>
					<Panel Alignment="Center">
						<Text ux:Name="text">Active</Text>
						<WhileInactive Threshold="0.1">
							<Change text.Value="Inactive" />
						</WhileInactive>
					</Panel>
				</Page>
				<Page Background="Blue" />
			</PageControl>

		The progress of this trigger is calculated as the page's distance from the active page (or the navigation position for continuous navigation). For example, the active page has a distance of 0, meaning this trigger will not be activated, and a page 1 away from the active has a distance of 1, meaning this trigger will be activated. The `Threshold=0.1` in this example means the trigger activates after the page has been swiped only 10% of the distance away from the active position.
	*/
	public class WhileInactive : WhileNavigationTrigger
	{
		internal override double MapProgress( double progress )
		{
			return Math.Abs(progress);
		}
	}

	/**
		A directional version of @WhileInactive.

		This works like @WhileInactive except remains completely inactive if the page goes in front of the current page. It can only be activated while the page is behind the active one (in the back).
	*/
	public class WhileInExitState : WhileNavigationTrigger
	{
		internal override double MapProgress( double progress )
		{
			return -progress;
		}
	}

	/**
		A directional version of @WhileInactive.

		This works like @WhileInactive except remains completely inactive if the page goes behind the current page. It can only be activated while the page is in front of the active one (in the front).
	*/
	public class WhileInEnterState : WhileNavigationTrigger
	{
		internal override double MapProgress( double progress )
		{
			return progress;
		}
	}
}
