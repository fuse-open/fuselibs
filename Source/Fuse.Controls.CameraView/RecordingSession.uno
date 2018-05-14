using Uno;
using Uno.Threading;
using Fuse.Scripting;

namespace Fuse.Controls
{
	public abstract class RecordingSession
	{
		public abstract Future<Recording> Stop();

		static RecordingSession()
		{
			ScriptClass.Register(typeof(RecordingSession),
				new ScriptPromise<RecordingSession,Recording,object>("stop", ExecutionThread.MainThread, stop, ConvertRecording));
		}

		/**
			Stop recording video

			@scriptmethod stop()

			Returns a Promise that resloves to a @Recording

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.startRecording()
						.then(function(recordingSession) {
							recordingSession.stop()
								.then(function(recording) { })
								.catch(function(err) { });
						})
						.catch(function(err) { }):
				</JavaScript>
		*/
		static Future<Recording> stop(Context context, RecordingSession recordingSession, object[] args)
		{
			return recordingSession.Stop();
		}

		static object ConvertRecording(Context c, Recording recording)
		{
			return c.Unwrap(recording);
		}
	}
}
