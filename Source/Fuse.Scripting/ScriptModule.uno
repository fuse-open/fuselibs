using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;

namespace Fuse.Scripting
{
	public interface IModuleProvider
	{
		Module GetModule();
	}

	public partial class ScriptModule : Module
	{
		FileSource _file;
		public FileSource File
		{
			get { return _file; }
			set
			{
				_file = value;
			}
		}

		public override FileSource GetFile() { return _file; } 

		Bundle _bundle;
		public Bundle Bundle
		{
			get
			{
				var bfs = File as Uno.UX.BundleFileSource;
				return bfs != null ? bfs.BundleFile.Bundle : _bundle;
			}
			set
			{
				_bundle = value;
			}
		}

		public string Preamble { get; set; }
		public string Postamble { get; set; }

		string _code;
		public string Code
		{
			get
			{
				if (File != null) return File.ReadAllText();
				return _code;
			}
			set
			{
				_code = value;
			}
		}

		string _fileName;
		public string FileName
		{
			get
			{
				if (File != null) return _file.Name;
				else return _fileName;
			}
			set
			{
				_fileName = value;
			}
		}

		int _lineNumberOffset;
		public int LineNumberOffset
		{
			get
			{
				if (File != null) return 0;
				return _lineNumberOffset;
			}
			set
			{
				_lineNumberOffset = value;
			}
		}
	}
}
