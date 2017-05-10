using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
	extern(Android) internal static class UnifiedPaths
	{
		[Foreign(Language.Java)]
		public static string GetCacheDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getExternalCacheDir().getAbsolutePath();
		@}


		[Foreign(Language.Java)]
		public static string GetDataDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getFilesDir().getAbsolutePath();
		@}
	}
}
