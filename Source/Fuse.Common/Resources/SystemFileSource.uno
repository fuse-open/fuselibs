using Uno.UX;
using Uno.IO;

namespace Fuse.Resources
{
	internal sealed class SystemFileSource : FileSource
	{
		public SystemFileSource(string file)
			: base(file)
		{
		}

		public override Stream OpenRead()
		{
			return File.OpenRead(Name);
		}
	}
}
