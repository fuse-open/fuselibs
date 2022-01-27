namespace Fuse.Controls
{
	public sealed class DownloadEventArgs : Uno.EventArgs, Fuse.Scripting.IScriptEvent
	{
		public readonly string Url;
		public readonly string Path;

		public DownloadEventArgs(string url, string path) : base()
		{
			Url = url;
			Path = path;
		}

		void Fuse.Scripting.IScriptEvent.Serialize(Fuse.Scripting.IEventSerializer s)
		{
			s.AddString("url", Url);
			s.AddString("path", Path);
		}
	}
}
