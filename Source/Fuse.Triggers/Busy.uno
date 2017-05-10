using Uno;

namespace Fuse.Triggers
{
	[Flags]
	public enum BusyOn
	{
		/** The busy task has no automatic activation */
		None = 0,
		/** A change in parameter activates the busy task */
		ParameterChanged = 1 << 0,
	}
	
	/**
		Marks a UX node as busy.
		
		There are several cases where we need to perform some background task, for instance fetching data over the network or performing some expensive computation. `Busy` can be used to coorindate this busy activity between JavaScript and UX. 
		
		We often want to be able to signal to our view (UX) that our data is not yet ready for display. Marking a node as busy will activate any `WhileBusy` triggers on it. This is the same mechanism used to indicate that an image is loading.
		
		## Examples
		
		### Loading data
		
		We might wish to display a loading indicator while making an HTTP request.
		
			<Panel>
				<WhileBusy>
					<Text Value="Loading..."/>
				</WhileBusy>
				<Busy IsActive="false" ux:Name="busy"/>
				<JavaScript>
					exports.startLoad = function() {
						busy.activate()
						fetch( "http://example.com/some/data" ).then( function(response) {
							//use the response
							busy.deactivate()
						}).catch(function(err) {
							//make sure to disable the busy status here as well
							busy.deactivate()
						})
					}
				</JavaScript>
				<Activated Handler="{startLoad}"/>
			</Panel>
			
		This example starts loading data when the page is activated. The `Loading...` text will be shown while it is loading, and removed once it is completed.

		
		### Preparing for navigation
		
		The @Navigator waits for a busy page to finish preparing before navigating to it. We can use `Busy` to ensure our bindings our done before this happens.
		
			<Page>
				<Busy Activity="Preparing" On="ParameterChanged" ux:Name="busy"/>
				<JavaScript>
					exports.name = Observable()
					this.Parameter.onValueChanged( module, function(v) {
						exports.name.value = v.name
						busy.deactivate()
					})
				</JavaScript>
				<Text Value="{name}"/>
			</Page>
	*/
	public partial class Busy : Behavior
	{
		bool _isActive = true;
		/**
			Whether the Node is marked busy or not.
			
			The default is `true` -- you must set it explicitly to `false`, or call `.reset` from JS to turn off the busy status.
		*/
		public bool IsActive
		{
			get { return _isActive; }
			set 
			{
				if (value == _isActive)
					return;
					
				_isActive = value;
				UpdateState();
			}
		}
		
		BusyTaskActivity _activity = BusyTaskActivity.Processing;
		/**
			How the node will be marked as busy.
			
			The default is `Processing`. If you wish to delay page navigation until this task is finished you need to use `Preparing`, as that is what @Navigator watches.
		*/
		public BusyTaskActivity Activity
		{
			get { return _activity; }
			set
			{
				if (value == _activity)
					return;
					
				_activity = value;
				UpdateState();
			}
		}

		BusyOn _on = BusyOn.None;
		/**
			When this task is automatically activated.
		*/
		public BusyOn On
		{
			get { return _on; }
			set { _on = value; }
		}
		
		BusyTask _busyTask;
		BusyOn _rootOn; //track what was set while rooted
		void UpdateState()
		{
			if (!IsRootingStarted)
				return;
				
			BusyTask.SetBusy(Parent, ref _busyTask, IsActive ? Activity : BusyTaskActivity.None);
			
			_rootOn = _on;
			if (_rootOn.HasFlag(BusyOn.ParameterChanged))
			{
				var v = Parent as Visual;
				if (v == null)
				{
					_rootOn &= ~BusyOn.ParameterChanged;
					Fuse.Diagnostics.UserError( "On='ParameterChanged' requires a Visual parent", this );
				}
				else
				{
					v.ParameterChanged += OnParameterChanged;
				}
			}
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			if (_rootOn.HasFlag(BusyOn.ParameterChanged))
				(Parent as Visual).ParameterChanged -= OnParameterChanged;
			UpdateState();
		}
		
		protected override void OnUnrooted()
		{
			BusyTask.SetBusy(Parent, ref _busyTask, BusyTaskActivity.None );
			base.OnUnrooted();
		}
		
		void OnParameterChanged(object s, EventArgs args)
		{
			IsActive = true;
		}
	}
}
