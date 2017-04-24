using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Graphics;
using Uno.Platform;
using Fuse;

namespace Fuse.Controls.VideoImpl
{

	/*extern(DesignMode)*/ static class VideoDiskCache
	{

		static int _fileCount = 0;
		static readonly Dictionary<string, string> _files = new Dictionary<string, string>();

		static VideoDiskCache()
		{
			Fuse.Platform.Lifecycle.Terminating += OnTerminating;
		}

		static void OnTerminating(Fuse.Platform.ApplicationState newState)
		{
			Fuse.Platform.Lifecycle.Terminating -= OnTerminating;
			foreach (var pair in _files)
			{
				if (Uno.IO.File.Exists(pair.Value))
				{
					debug_log "Deleting temporary file: " + pair.Value;
					Uno.IO.File.Delete(pair.Value);
				}
			}
		}

		public static string GetFilePath(FileSource fileSource)
		{
			if (!_files.ContainsKey(fileSource.Name))
			{
				var bytes = fileSource.ReadAllBytes();
				var path = Uno.IO.Directory.GetUserDirectory(Uno.IO.UserDirectory.Data) + "/tempVideo" + _fileCount.ToString() + "." + GetFileExtension(fileSource.Name);
				_fileCount++;
				Uno.IO.File.WriteAllBytes(path, bytes);
				_files.Add(fileSource.Name, path);
			}
			return _files[fileSource.Name];
		}

		public static string GetFileExtension(string fileName)
		{
			var strings = fileName.Split(new [] { '.' });
			return strings[strings.Length - 1];
		}

	}

}
