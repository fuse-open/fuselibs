using Uno;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Text.Implementation;

namespace Fuse.Text.Implementation
{
	[Require("Source.Include", "unicode/ubrk.h")]
	static extern(USE_ICU) class UBrk
	{
		public static BitArray GetSoftLineBreaks(Substring text)
		{
			var result = new BitArray(text.Length + 1);
			ICU.CheckError(ubrk(text._parent, text._start, text.Length, result.Data));
			return result;
		}

		[Foreign(Language.CPlusPlus)]
		public static ICU.ErrorCode ubrk(string text, int offset, int length, byte[] outBitArray)
		@{
			::UErrorCode error = U_ZERO_ERROR;

			auto bi = ::ubrk_open(UBRK_LINE, 0, (const ::UChar*)(text + offset), length, &error);
			if (U_FAILURE(error))
				return error;

			const int32_t bytesize = 8;
			int32_t boundary = ::ubrk_first(bi);
			while (boundary != UBRK_DONE)
			{
				int32_t i = boundary / bytesize;
				uint8_t mask = (uint8_t)(1 << (boundary % bytesize));
				outBitArray[i] |= mask;
				boundary = ::ubrk_next(bi);
			}

			ubrk_close(bi);
			return U_ZERO_ERROR;
		@}
	}
}
