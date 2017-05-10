using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Text.Implementation
{
	[DotNetType]
	extern(DotNet && HOST_WINDOWS) static class DllDirectory
	{
		public static void SetTargetSpecific()
		{
		}
	}
}
