using Uno.Compiler.ExportTargetInterop;

namespace Uno
{
	extern(DOTNET) public static class BufferAccessor
	{
		[Obsolete]
		public static byte[] GetBytes(Uno.Buffer buffer)
		{
			return buffer.GetBytes();
		}
	}
}
