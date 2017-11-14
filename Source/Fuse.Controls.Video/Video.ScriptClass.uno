using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Controls
{
	public partial class Video
	{
		static Video()
		{
			ScriptClass.Register(typeof(Video),
				new ScriptMethod<Video>("getDuration", getDuration),
				new ScriptMethod<Video>("resume", resume),
				new ScriptMethod<Video>("pause", pause),
				new ScriptMethod<Video>("stop", stop));
		}

		object _durationMutex = new object();

		// private fields used by ScriptClass for retrieving the position from JavaScript
		double _outDuration;
		void UpdateScriptClass(double duration)
		{
			lock (_durationMutex)
				_outDuration = duration;
		}

		/**
			Gets the duration of the Video in seconds. getDuration will return 0 until the video has initialized.

			@scriptmethod getDuration()
		*/
		static object getDuration(Context c, Video v, object[] args)
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError("getDuration takes 0 arguments, but " + args.Length + " was supplied", v);
				return null;
			}

			lock (v._durationMutex)
				return (object)v._outDuration;
		}

		/**
			Resumes playback from the current position.

			@scriptmethod resume()
		*/
		static void resume(Video v)
		{
			v.Resume();
		}

		/**
			Pauses playback, leaving the current position as-is.

			@scriptmethod pause()
		*/
		static void pause(Video v)
		{
			v.Pause();
		}

		/**
			Stops playback and returns to the beginning of the video.

			@scriptmethod stop()
		*/
		static void stop(Video v)
		{
			v.Stop();
		}
	}
}
