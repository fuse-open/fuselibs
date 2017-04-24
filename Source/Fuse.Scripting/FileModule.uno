using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Scripting
{
	public class CodeModule : ScriptModule
	{
		public CodeModule(Bundle bundle, string fileName, string code, int lineNumberOffset)
		{
			Bundle = bundle;
			FileName = fileName;
			Code = code;
			LineNumberOffset = lineNumberOffset;
		}
	}

	public class FileModule : ScriptModule
	{
		public FileModule(FileSource fs)
		{
			File = fs;
		}
	}
}