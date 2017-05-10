using Uno;
using Uno.Collections;
using Uno.IO;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Resources;

namespace Fuse.Controls.Native.Android
{
	extern(Android) internal class Typeface
	{
		public Java.Object Handle
		{
			get { return _handle; }
		}

		// android.graphics.Typeface
		readonly Java.Object _handle;

		public Typeface(Java.Object handle)
		{
			_handle = handle;
		}

		public static Typeface Default
		{
			get { return new Typeface(GetDefault()); }
		}

		public override bool Equals(object obj)
		{
			return obj is Java.Object
				? _handle.Equals((Java.Object)obj)
				: false;
		}

		public override int GetHashCode()
		{
			return _handle.GetHashCode();
		}

		public static Typeface CreateFromBundleFile(BundleFile file)
		{
			return new Typeface(CreateFromBundleFile(file.BundlePath));
		}

		public static Typeface CreateFromFile(string path)
		{
			return new Typeface(CreateFromFileImpl(path));
		}

		[Foreign(Language.Java)]
		static Java.Object CreateFromBundleFile(string bundlePath)
		@{
			android.content.res.AssetManager assetManager = (com.fuse.Activity.getRootActivity()).getAssets();
			android.graphics.Typeface typeface = android.graphics.Typeface.createFromAsset(assetManager, bundlePath);
			return typeface;
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateFromFileImpl(string path)
		@{
			return android.graphics.Typeface.createFromFile(path);
		@}

		[Foreign(Language.Java)]
		static Java.Object GetDefault()
		@{
			return android.graphics.Typeface.DEFAULT;
		@}
	}

	extern(Android) internal static class TypefaceCache
	{

		static Dictionary<string, Typeface> _typefaces = new Dictionary<string, Typeface>();

		public static Typeface GetTypeface(Font font)
		{
			return font.FileSource is BundleFileSource
				? GetTypefaceFromBundleFile(((BundleFileSource)font.FileSource).BundleFile)
				: GetTypefaceFromFileSource(font.FileSource);
		}

		static Typeface GetTypefaceFromBundleFile(BundleFile file)
		{
			if (_typefaces.ContainsKey(file.BundlePath))
				return _typefaces[file.BundlePath];

			var typeface = Typeface.CreateFromBundleFile(file);
			_typefaces.Add(file.BundlePath, typeface);
			return typeface;
		}

		static Typeface GetTypefaceFromFileSource(FileSource fileSource)
		{
			if (_typefaces.ContainsKey(fileSource.Name))
				return _typefaces[fileSource.Name];

			Typeface typeface;

			if (fileSource is SystemFileSource)
			{
				typeface = Typeface.CreateFromFile(fileSource.Name);
			}
			else
			{
				var data = fileSource.ReadAllBytes();
				var path = Uno.IO.Directory.GetUserDirectory(Uno.IO.UserDirectory.Data) + "/tempFont";

				Uno.IO.File.WriteAllBytes(path, data);

				typeface = Typeface.CreateFromFile(path);

				Uno.IO.File.Delete(path);
			}

			_typefaces.Add(fileSource.Name, typeface);

			return typeface;
		}

	}

}
