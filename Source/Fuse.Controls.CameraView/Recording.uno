using Uno;
using Uno.Threading;
using Fuse.Scripting;

namespace Fuse.Controls
{
	public abstract class Recording
	{
		readonly string _filePath;

		protected Recording(string filePath)
		{
			_filePath = filePath;
		}

		public string FilePath
		{
			get { return _filePath; }
		}

		static Recording()
		{
			ScriptClass.Register(typeof(Recording),
				new ScriptMethod<Recording>("filePath", filePath));
		}

		/**
			Get the filepath of the video

			@scriptmethod filePath

			Returns a string containing the filepath to the video

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.startRecording()
						.then(function(recordingSession) {
							recordingSession.stop()
								.then(function(recording) {
									var filePath = recording.filePath();
								});
						});
				</JavaScript>
		*/
		static object filePath(Context context, Recording self, object[] args)
		{
			return self.FilePath;
		}
	}
}
