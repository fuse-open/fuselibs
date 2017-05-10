using Uno;
using Uno.IO;

namespace Fuse.FileSystem
{
	internal static class PathTools
	{
		public static string NormalizePath(this string path)
		{
			if (Path.DirectorySeparatorChar == '\\')
				return path.Replace('\\', '/');
			return path;
		}
	}
}
