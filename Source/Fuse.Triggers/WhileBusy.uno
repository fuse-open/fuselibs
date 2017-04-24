
namespace Fuse.Triggers
{
	/**
		A trigger that is active whenever a sibling or parent is marked as busy.
		
		UX nodes can mark themselves as busy, meaning that they are currently waiting on some background task and are not ready for rendering.
		This can be anything from making a HTTP request to performing an expensive computation.
		We can use WhileBusy to react to this, as it will be activated while a sibling or parent node is marked as busy.
		
		> *Note:* You can use the [FuseJS/BusyTask API](/docs/fuse/triggers/busytaskmodule) to mark nodes as busy via JavaScript.
		
		## Example
			
		The following example displays an @Image from a URL, and a text while it's loading.
			
			<Image Url="SOME_IMAGE_URL">
				<WhileBusy>
					<Text Value="Loading..." />
				</WhileBusy>
			</Image>
			
		When a node is marked as busy, its ancestors are also considered busy.
		This lets us react to multiple busy nodes in the same trigger.
		In the following example we have two @Images loaded via HTTP, and a "Loading..." indicator that fades to transparency after both images have downloaded.
			
			<Panel>
				<Panel ux:Name="loadingPanel" Opacity="0" Alignment="Top">
					<Text>Loading...</Text>
				</Panel>
				<WhileBusy>
					<Change loadingPanel.Opacity="1" Duration="0.5" />
				</WhileBusy>
				<StackPanel>
					<Image Url="SOME_IMAGE_URL" />
					<Image Url="SOME_OTHER_IMAGE_URL" />
				</StackPanel>
			</Panel>
		
	*/
	public class WhileBusy: WhileTrigger, IBusyHandler
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			BusyTask.AddListener(Parent, Update);
			Update();
		}

		protected override void OnUnrooted()
		{
			BusyTask.RemoveListener(Parent, Update);
			base.OnUnrooted();
		}

		/**
			If true then the busy status is blocked from reaching parent nodes.
			
				<WhileBusy ux:Name="W1">...</WhileBusy>
				<Panel>
					<WhileBusy ux:Name="W2" IsHandled="true">...</WhileBusy>
					<Image Url="http://some.place/file.png"/>
					
			In this arrangement the `W1` trigger will not be active while the `Image` is loading. The `IsHandled="true"` in the `W2` trigger indicates it completely handles the busy status for this node and its descendants.
		*/
		public bool IsHandled { get; set; }
		
		BusyTaskActivity _activity = BusyTaskActivity.Common;
		/**
			Marks what kind of busy activity is considered by this trigger.
			
			This is `All` by default, meaning all busy activity is considered.
		*/
		public BusyTaskActivity Activity
		{
			get { return _activity; }
			set 
			{ 
				_activity = value;
				if (IsRootingCompleted)
					Update();
			}
		}

		BusyTaskMatch _match = BusyTaskMatch.Descendents;
		public BusyTaskMatch Match
		{
			get { return _match; }
			set
			{
				_match = value;
				if (IsRootingCompleted)
					Update();
			}
		}
		
		void Update()
		{
			//safety check
			if (Activity == BusyTaskActivity.None)
				return;
				
			var act = BusyTask.GetBusyActivity(Parent, Match);
			SetActive( (act & Activity) != BusyTaskActivity.None);
		}
		
		BusyTaskActivity IBusyHandler.BusyActivityHandled
		{
			get { return IsHandled ? Activity : BusyTaskActivity.None; }
		}
	}
}