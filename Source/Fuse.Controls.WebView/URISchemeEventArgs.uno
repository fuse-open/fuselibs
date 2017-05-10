namespace Fuse.Controls
{
	public sealed class URISchemeEventArgs : Uno.EventArgs, Fuse.Scripting.IScriptEvent
	{
		public readonly string Url;

		public URISchemeEventArgs(string url) : base()
		{
			Url = url;
		}

		void Fuse.Scripting.IScriptEvent.Serialize(Fuse.Scripting.IEventSerializer s)
		{
			s.AddString("url", Url);
		}
	}
}
