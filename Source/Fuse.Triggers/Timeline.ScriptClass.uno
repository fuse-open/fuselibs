using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Triggers
{
	public sealed partial class Timeline
	{
		static Timeline()
		{
			ScriptClass.Register(typeof(Timeline),
				new ScriptMethod<Timeline>("pause", pause),
				new ScriptMethod<Timeline>("pulse", pulse),
				new ScriptMethod<Timeline>("pulseBackward", pulseBackward),
				new ScriptMethod<Timeline>("pulseForward", pulseForward),
				new ScriptMethod<Timeline>("play", resume),
				new ScriptMethod<Timeline>("playTo", playTo),
				new ScriptMethod<Timeline>("resume", resume),
				new ScriptMethod<Timeline>("seek", seek),
				new ScriptMethod<Timeline>("stop", stop)
			);
		}

		/**
			Pulses the Timeline (plays to end and back to start).
			
			@scriptmethod pulse()
		*/
		static void pulse(Timeline n)
		{
			n.Pulse();
		}
		
		/**
			Pulses the Timeline forward (plays to the end and deactivates).
			
			@scriptmethod pulseForward()
		*/
		static void pulseForward(Timeline n)
		{
			n.PulseForward();
		}
		
		/**
			Pulses the Timeline backward (seeks to end then plays backward to start)
			
			@scriptmethod pulseBackward()
		*/
		static void pulseBackward(Timeline n)
		{
			n.PulseBackward();
		}
		
		/**
			Plays to a particular progress in the Timeline. This plays from the current progress to the new
			target progress.
			
			@scriptmethod playTo( progress )
			
			@param progress The relative position (0..1) to play to.
		*/
		static void playTo(Timeline n, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "Timeline.playTo requires 1 argument", n );
				return;
			}

			n.PlayTo( Marshal.ToDouble(args[0]) );
		}
		
		/**
			Stops playback. This sets the target progress to the current location such that @resume
			will not keep playing.
			
			@scriptmethod stop()
		*/
		static void stop(Timeline n)
		{
			n.Stop();
		}
		
		/**
			Resumes playback from the current progress to the target progress. Call this after a @pause to
			resume playback.
			
			@scriptmethod resume()
		*/
		static void resume(Timeline n)
		{
			n.Resume();
		}
		
		/**
			Pauses playback at the current progress. Call @resume to continue playing.
			
			@scriptmethod pause()
		*/
		static void pause(Timeline n)
		{
			n.Pause();
		}
		
		/**
			Seeks to a given location (jumps there without playing the intervening animation).
			
			@scriptmethod seek( progress )
			@param progress The relative position (0..1) to seek to.
		*/
		static void seek(Timeline n, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "Timeline.seek requires 1 argument", n );
				return;
			}
			n.Progress = Marshal.ToDouble(args[0]);
		}
	}
}
