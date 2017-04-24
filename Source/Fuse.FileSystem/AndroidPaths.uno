using Uno;
using Uno.IO;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
	extern(Android) internal class AndroidPaths
	{
		internal static Dictionary<string, string> GetPathDictionary()
		{
			var dict = new Dictionary<string, string>();
			dict["externalCache"] = GetExternalCacheDirectory();
			dict["externalFiles"] = GetExternalFilesDirectory();
			dict["cache"] = GetCacheDirectory();
			dict["files"] = GetFilesDirectory();
			return dict;
		}


		[Foreign(Language.Java)]
		static string GetExternalCacheDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getExternalCacheDir().getAbsolutePath();
		@}


		[Foreign(Language.Java)]
		static string GetExternalFilesDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getExternalFilesDir(null).getAbsolutePath();
		@}


		[Foreign(Language.Java)]
		static string GetCacheDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getCacheDir().getAbsolutePath();
		@}


		[Foreign(Language.Java)]
		static string GetFilesDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getFilesDir().getAbsolutePath();
		@}
	}
}
