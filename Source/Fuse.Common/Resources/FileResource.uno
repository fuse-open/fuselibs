using Uno;
using Uno.IO;
using Uno.UX;

namespace Fuse.Resources
{
	public class FileResource: FileSource
	{	
		FileSource _file;

		[UXConstructor]
		public FileResource([UXParameter("File")] FileSource file): base(file.Name)
		{
			_file = file;
		}

		public override Stream OpenRead() { return _file.OpenRead(); }
	}
}
