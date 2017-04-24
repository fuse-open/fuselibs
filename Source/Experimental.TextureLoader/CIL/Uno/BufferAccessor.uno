using Uno.Compiler.ExportTargetInterop;

namespace Uno
{
	[DotNetType("Uno.BufferAccessor")]
	extern(DOTNET) public static class BufferAccessor
	{
		public extern static byte[] GetBytes(Uno.Buffer buffer);
	}
}
