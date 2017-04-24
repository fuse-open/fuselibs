using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
	[extern(DOTNET) DotNetType("System.Reflection.Assembly")]
	extern(DOTNET) internal abstract class BclAssembly
	{
		public extern static BclAssembly GetExecutingAssembly();
		public extern string Location { get; }
	}
}
