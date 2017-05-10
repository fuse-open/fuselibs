using Uno;

namespace Fuse.Triggers.Actions
{
	public enum TimelineActionHow
	{
		/** @see Timeline.Pause */
		Pause,
		/** @see Timeline.Resume (Play is an alias for Resume) */
		Play,
		/** @see Timeline.PlayTo, requires `Progress` */
		PlayTo,
		/** @see Timeline.Pulse */
		Pulse,
		/** @see Timeline.PulseBackward */
		PulseBackward,
		/** @see Timeline.PulseForward */
		PulseForward,
		/** @see Timeline.Resume */
		Resume,
		/** Sets the `Timeline.Progress` to `Progress` */
		Seek,
		/** @see Timeline.Stop */
		Stop,
	}
	
	/**
		A unified action that controls a @Timeline.
		
		These actions differ from the `IPlayback` interface, which only supports a plain media view of the Timeline. `TimelineAction` exposes the advanced functionality of @Timeline, and matches the JavaScript interface.
	*/
	public class TimelineAction : TriggerAction
	{
		public Timeline Target { get; set; }
		
		public TimelineActionHow How { get; set; }

		/**
			A relative progress location (0..1) for certain `How` values (`PlayTo`, `Seek`).
		*/
		public double Progress { get; set; }
		
		protected override void Perform(Node target)
		{
			var t = Target;
			if (t == null)
			{
				Fuse.Diagnostics.UserError( "`TimelineAction` called without a `Timeline` `Target`", this );
				return;
			}
			
			switch (How)
			{
				case TimelineActionHow.Pause:
					t.Pause();
					break;
				case TimelineActionHow.PlayTo:
					t.PlayTo(Progress);
					break;
				case TimelineActionHow.Pulse:
					t.Pulse();
					break;
				case TimelineActionHow.PulseBackward:
					t.PulseBackward();
					break;
				case TimelineActionHow.PulseForward:
					t.PulseForward();
					break;
				case TimelineActionHow.Play:
				case TimelineActionHow.Resume:
					t.Resume();
					break;
				case TimelineActionHow.Seek:
					t.Progress = Progress;
					break;
				case TimelineActionHow.Stop:
					t.Stop();
					break;
			}
		}
	}
}
