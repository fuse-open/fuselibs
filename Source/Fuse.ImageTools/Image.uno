using Uno.Threading;
using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Scripting;
namespace Fuse.ImageTools
{
	public sealed class Image
	{
		public string Path { get; private set; }
		public string Name { get; private set; }
		int2 _dims;

		public int Width {
			get{
				CheckDims();
				return _dims.X;
			}
		}

		public int Height {
			get{
				CheckDims();
				return _dims.Y;
			}
		}

		extern(Android) void CheckDims()
		{
			if(_dims.X == 0 && _dims.Y == 0)
				_dims = AndroidImageUtils.GetSize(this);
		}

		extern(iOS) void CheckDims()
		{
			if(_dims.X == 0 && _dims.Y == 0)
				_dims = iOSImageUtils.GetSize(this);
		}
		
		public bool Rename(string newName, bool overwrite = false)
		{
			if(newName == Name) return true;
			var newPath = Uno.IO.Path.Combine(Uno.IO.Path.GetDirectoryName(Path), newName);
			if(!overwrite && Uno.IO.File.Exists(newPath)) return false;
			Uno.IO.File.Move(Path,newPath);
			Path = newPath;
			Name = newName;
			return true;
		}

		extern(!Mobile) void CheckDims() { }

		public Dictionary<string, object> Info { get; private set; }

		public Image() : this("No path") {}

		public Image(string path)
		{
			Path = path;
			Name = Uno.IO.Path.GetFileName(Path);
			Info = new Dictionary<string, object>();
		}

		public static Image FromObject(object o)
		{
			return FromObject((Scripting.Object)o);
		}

		public static Image FromObject(Scripting.Object o)
		{
			string path = (string) o["path"];
			var outValue = new Image(path);
			return outValue;
		}

		Scripting.Object InfoToObject(Context c)
		{
			var outValue = c.NewObject();
			foreach(var key in Info.Keys)
			{
				outValue[key] = Info[key];
			}
			return outValue;
		}

		public Scripting.Object ToObject(Scripting.Context c)
		{

			var outValue = c.NewObject();

			outValue["path"] = Path;
			outValue["name"] = Uno.IO.Path.GetFileName(Path);
			outValue["width"] = Width;
			outValue["height"] = Height;
			outValue["info"] = InfoToObject(c);

			outValue.Freeze(c);

			return outValue;
		}

		public static Scripting.Object Converter(Context context, Image result)
		{
			return result.ToObject(context);
		}
	}
}
