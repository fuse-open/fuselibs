using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Text;

namespace Fuse.Text.Implementation
{
	[Require("Source.Include", "string.h")]
	static extern(DOTNET || CPlusPlus || PInvoke) class Memory
	{
		[Foreign(Language.CPlusPlus)]
		public static void Copy(byte[] dst, IntPtr src, int len)
		@{
			::memcpy(dst, src, len);
		@}
	}

	[Require("Source.Include", "string.h")]
	static extern(DOTNET || CPlusPlus || PInvoke) class CString
	{
		public static string ToString(IntPtr cstr)
		{
			int len = cstr == IntPtr.Zero ? 0 : strlen(cstr);
			var buffer = new byte[len];
			Memory.Copy(buffer, cstr, len);
			return Utf8.GetString(buffer);
		}

		[Foreign(Language.CPlusPlus)]
		static int strlen(IntPtr cstr)
		@{
			return (int)::strlen((const char*)cstr);
		@}
	}
}
