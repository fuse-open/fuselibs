using Uno;
using Uno.IO;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
	extern(iOS) internal class IosPaths
	{
		internal static Dictionary<string, string> GetPathDictionary()
		{
			var dict = new Dictionary<string, string>();
			dict["documents"] = GetDocumentsDirectory();
			dict["library"] = GetLibraryDirectory();
			dict["caches"] = GetCachesDirectory();
			dict["temporary"] = GetTemporaryDirectory();
			return dict;
		}


		[Foreign(Language.ObjC)]
		public static string GetCachesDirectory()
		@{
			return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
		@}


		[Foreign(Language.ObjC)]
		public static string GetDocumentsDirectory()
		@{
			return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		@}


		[Foreign(Language.ObjC)]
		public static string GetLibraryDirectory()
		@{
			return NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
		@}


		[Foreign(Language.ObjC)]
		public static string GetTemporaryDirectory()
		@{
			return NSTemporaryDirectory();
		@}
	}
}
