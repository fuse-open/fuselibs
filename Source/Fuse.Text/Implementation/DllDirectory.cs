using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

namespace Fuse.Text.Implementation
{
	public static class DllDirectory
	{
		public static void SetTargetSpecific()
		{
			if (Path.DirectorySeparatorChar == '\\') // Super-awesome and reliable Windows detection
			{
				var asmDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

				switch (IntPtr.Size)
				{
					case 4: SetDllDirectory(Path.Combine(asmDir, "x86")); break;
					case 8: SetDllDirectory(Path.Combine(asmDir, "x64")); break;
					default: throw new Exception("Invalid IntPtr.Size: " + IntPtr.Size);
				}
			}
		}
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern bool SetDllDirectory(string path);
	}
}
