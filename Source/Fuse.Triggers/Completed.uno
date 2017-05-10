using Uno;

namespace Fuse.Triggers
{

	public class CompletedEventArgs : Uno.EventArgs { }

	public enum CompletedActivation
	{
		SameFrame,
		NextFrame,
	}
	
	/**
		Pulses when the busy status of a node is cleared.
		
		`Completed` is used to respond to the completion of a preparation, loading, or other busy task.
		
		This example draws attention to an `Image` when it has completed loading:
		
			<Image Url="some_big_image">
				<Completed>
					<Scale Factor="0.8" Duration="0.4"/>
				</Completed>
			</Image>
			
		`Completed` always fires, even if the node wasn't busy before. This makes it suitable for things that should always run. It also makes it useful in combination with other triggers. For example, the below scales the image when the navigation page is both active and completed.
		
			<Page>
				<Image Alignment="Center" Url="some_image" ux:Name="theImage"/>
				<WhileActive>
					<Completed>
						<Scale Target="theImage" Factor="1.5" Duration="0.3"/>
					</Completed>
				</WhileActive>
			</Page>
	*/
	public partial class Completed : PulseTrigger<CompletedEventArgs>
	{	
		bool _pulsed;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			Reset();
		}
		
		void Setup()
		{
			if (!_listening)
			{
				BusyTask.AddListener(Parent, Update);
				_listening = true;
				
				//don't check immediately since other things still need to root/complete
				UpdateManager.AddDeferredAction(Update);
			}
		}
		
		protected override void OnUnrooted()
		{
			Cleanup(true);
			base.OnUnrooted();
		}
		
		bool _listening;
		void Cleanup(bool unroot)
		{
			if (Repeat && !unroot)
			{
				_pulsed = false;
				return;
			}
			
			if (_listening)
			{
				BusyTask.RemoveListener(Parent, Update);
				_listening = false;
			}
		}
		
		internal bool TestIsClean
		{
			get { return !_listening; }
		}
		
		CompletedActivation _activation = CompletedActivation.NextFrame;
		/**
			Determines when the trigger actually pulses.
			
			The default is to trigger one frame after the busy state is cleared. This shouldn't normally be changed.
			
			@advanced
		*/
		public CompletedActivation Activation
		{
			get { return _activation; }
			set { _activation = value; }
		}
		
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
		/**
			Determines what nodes are considered for the busy check.
			
			The default is `Descendents`
		*/
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
		
		bool _repeat = false;
		/**
			By default `Completed` will trigger only once after it has been rooted. Set `Repeat="true"` to have it trigger every time a busy operation completes.
		*/
		public bool Repeat
		{
			get { return _repeat; }
			set { _repeat = value; }
		}
		
		bool IsBusy
		{	
			get
			{
				var act = BusyTask.GetBusyActivity(Parent, Match);
				var busy = (act & Activity) != BusyTaskActivity.None;
				return busy;
			}
		}
		
		void Update()
		{
			if (!IsBusy && !_pulsed)
			{
				if (Activation == CompletedActivation.NextFrame)
					UpdateManager.PerformNextFrame(DoPulse);
				else
					DoPulse();
			}
		}
		
		void DoPulse()
		{
			//double check (we should not pulse when busy, nor pulse twice at once)
			if (!IsBusy && !_pulsed)
			{
				_pulsed = true;
				Cleanup(false);
				Pulse(new CompletedEventArgs());
			}
		}
		
		/**
			Resets the already pulsed state and allows the trigger to pulse again.
		*/
		public void Reset()
		{
			_pulsed = false;
			Setup();
		}
	}
}
