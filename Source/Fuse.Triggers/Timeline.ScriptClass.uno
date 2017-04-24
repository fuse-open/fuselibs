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
				new ScriptMethod<Timeline>("pause", pause, ExecutionThread.MainThread),
				new ScriptMethod<Timeline>("pulse", pulse, ExecutionThread.MainThread),
				new ScriptMethod<Timeline>("pulseBackward", pulseBackward, ExecutionThread.MainThread),
				new ScriptMethod<Timeline>("pulseForward", pulseForward, ExecutionThread.MainThread),
				new ScriptMethod<Timeline>("play", resume, ExecutionThread.MainThread),
				new ScriptMethod<Timeline>("playTo", playTo, ExecutionThread.MainThread),
				new ScriptMethod<Timeline>("resume", resume, ExecutionThread.MainThread),
				new ScriptMethod<Timeline>("seek", seek, ExecutionThread.MainThread),
				new ScriptMethod<Timeline>("stop", stop, ExecutionThread.MainThread)
			);
		}

		/**
			Pulses the Timeline (plays to end and back to start).
			
			@scriptmethod pulse()
		*/
		static void pulse(Context c, Timeline n, object[] args)
		{
			n.Pulse();
		}
		
		/**
			Pulses the Timeline forward (plays to the end and deactivates).
			
			@scriptmethod pulseForward()
		*/
		static void pulseForward(Context c, Timeline n, object[] args)
		{
			n.PulseForward();
		}
		
		/**
			Pulses the Timeline backward (seeks to end then plays backward to start)
			
			@scriptmethod pulseBackward()
		*/
		static void pulseBackward(Context c, Timeline n, object[] args)
		{
			n.PulseBackward();
		}
		
		/**
			Plays to a particular progress in the Timeline. This plays from the current progress to the new
			target progress.
			
			@scriptmethod playTo( progress )
			
			@param progress The relative position (0..1) to play to.
		*/
		static void playTo(Context c, Timeline n, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "Timeline.seek requires 1 argument", n );
				return;
			}

			n.PlayTo( Marshal.ToDouble(args[0]) );
		}
		
		/**
			Stops playback. This sets the target progress to the current location such that @resume
			will not keep playing.
			
			@scriptmethod stop()
		*/
		static void stop(Context c, Timeline n, object[] args)
		{
			n.Stop();
		}
		
		/**
			Resumes playback from the current progress to the target progress. Call this after a @pause to
			resume playback.
			
			@scriptmethod resume()
		*/
		static void resume(Context c, Timeline n, object[] args)
		{
			n.Resume();
		}
		
		/**
			Pauses playback at the current progress. Call @resume to continue playing.
			
			@scriptmethod pause()
		*/
		static void pause(Context c, Timeline n, object[] args)
		{
			n.Pause();
		}
		
		/**
			Seeks to a given location (jumps there without playing the intervening animation).
			
			@scriptmethod seek( progress )
			@param progress The relative position (0..1) to seek to.
		*/
		static void seek(Context c, Timeline n, object[] args)
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
