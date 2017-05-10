using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
	extern(iOS) internal static class UnifiedPaths
	{
		// https://github.com/apache/cordova-plugin-file/blob/master/src/ios/CDVFile.m
		[Foreign(Language.ObjC)]
		public static string GetCacheDirectory()
		@{
			return NSTemporaryDirectory();
		@}


		[Foreign(Language.ObjC)]
		public static string GetDataDirectory()
		@{
			return NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
		@}
	}
}
