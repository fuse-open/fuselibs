using Uno;
using Uno.UX;
using Fuse.Scripting;
using Fuse.Reactive;
using Uno.Threading;

namespace FuseJS
{
	[UXGlobalModule]
	/** @hide
	*/
	public class FileReaderImpl : NativeModule
	{
		sealed class FileReadCommand
		{
			string _path;
			public FileReadCommand(string path)
			{
				_path = path;
			}
			public string ReadAsText()
			{
				return Uno.IO.File.ReadAllText(_path);
			}
			public string ReadAsDataURL()
			{
				var file = Uno.IO.File.ReadAllBytes(_path);
				var type = _path.ToUpper().EndsWith("PNG") ? "png" : "jpeg"; // TODO: Get filetype from file object instead
				var base64 = Uno.Text.Base64.GetString(file);
				return "data:image/" + type + ";base64," + base64;
			}
		}

		static readonly FileReaderImpl _instance;
		public FileReaderImpl()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/FileReaderImpl");
			AddMember(new NativePromise<string, string>("readAsDataURL", readAsDataURL, null));
			AddMember(new NativePromise<string, string>("readAsText", readAsText, null));
		}

		static Future<string> readAsDataURL(object[] args)
		{
			var path = (string)args[0];
			return Promise<string>.Run(new FileReadCommand(path).ReadAsDataURL);
		}

		static Future<string> readAsText(object[] args)
		{
			var path = (string)args[0];
			return Promise<string>.Run(new FileReadCommand(path).ReadAsText);
		}
	}
}