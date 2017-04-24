using Uno;
using Uno.Collections;
using Uno.IO;
using Uno.UX;

namespace Fuse
{
	class FileSourceConverter: Marshal.IConverter
	{
		public bool CanConvert(Type t) { return t == typeof(FileSource) || t.IsSubclassOf(typeof(FileSource)); }
		public object TryConvert(Type t, object obj)
		{
			if (!CanConvert(t)) return null;

			if (obj is string)
			{
				var path = (string)obj;

				foreach(var f in Uno.IO.Bundle.AllFiles)
				{
					if (f.SourcePath == path) return new Uno.UX.BundleFileSource(f);
				}

				return new JSFileSource((string)obj);
			}
			else if (obj is IObject) return new JSFileSource(((IObject)obj)["path"] as string);
			return null;
		}
	}

	class JSFileSource: FileSource
	{
		string _path;

		public JSFileSource(string path): base(path)
		{
			_path = path;
		}

		public override Stream OpenRead()
		{
			return Uno.IO.File.OpenRead(_path);
		}
	}
}
