using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;
// TODO: Split up into multiple files..

namespace Fuse.FileSystem
{
	extern(!mobile) internal static class UnifiedPaths
	{
		private static string _dataDirectory;
		private static string _cacheDirectory;


		static string GetAppBaseDirectory()
		{
			// Here we just use the location of the exe file.
			// This makes more sense the appdata folders as long as the app is not installed.
			string exeDir;
			if defined(DOTNET)
			{
				exeDir = Path.GetDirectoryName(Path.GetFullPath(BclAssembly.GetExecutingAssembly().Location));
			}
			else
			{
				exeDir = Path.GetDirectoryName(Path.GetFullPath(Environment.GetCommandLineArgs()[0]));
			}
			return exeDir;
		}


		public static string GetCacheDirectory()
		{
			// Right now the path of the executable is used.
			// This is probably appropriate during testing, but if we ever
			// rebrand Fuse as a OSX or Windows desktop this should
			// probably be changed.

			return GetOrCreateDirectory(ref _cacheDirectory, "fs_cache");
		}


		public static string GetDataDirectory()
		{
			return GetOrCreateDirectory(ref _dataDirectory, "fs_data");
		}


		private static string GetOrCreateDirectory(ref string path, string name)
		{
			if (path == null)
			{
				// This should be ok wrt. race conditions as it won't matter if directory
				// is created more than one time.. (no locks should be required)
				var baseDir = GetAppBaseDirectory();
				path = Path.Combine(baseDir, name).NormalizePath();
				Directory.CreateDirectory(path);
			}
			return path;
		}
	}
}
