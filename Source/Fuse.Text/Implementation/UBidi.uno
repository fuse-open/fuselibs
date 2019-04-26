using Fuse.Text.Implementation;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno;

namespace Fuse.Text.Bidirectional.Implementation
{
	[Require("Source.Include", "unicode/ubidi.h")]
	[Require("Source.Include", "string.h")]
	static extern(USE_ICU) class UBidiRuns
	{
		public static List<Run> GetLogical(Substring text)
		{
			var ubidi = Open();
			try
			{
				SetPara(ubidi, text);
				return GetLevels(ubidi, text);
			}
			finally
			{
				Close(ubidi);
			}
		}

		static void SetPara(IntPtr ubidi, Substring text)
		{
			ICU.CheckError(SetPara_Raw(ubidi, text._parent, text._start, text.Length));
		}

		static List<Run> GetLevels(IntPtr ubidi, Substring text)
		{
			var length = text.Length;
			if (length == 0)
				return new List<Run>();
			var levels = new byte[length];
			ICU.CheckError(GetLevels(ubidi, levels, length));
			var result = new List<Run>();
			int start = 0;
			byte lastLevel = levels[0];
			for (int i = 1; i < length; ++i)
			{
				byte currentLevel = levels[i];
				if (currentLevel != lastLevel)
				{
					result.Add(new Run(text.GetSubstring(start, i - start), (int)lastLevel));
					start = i;
					lastLevel = currentLevel;
				}
			}
			result.Add(new Run(text.GetSubstring(start, length - start), (int)lastLevel));
			return result;
		}

		[Foreign(Language.CPlusPlus)]
		static ICU.ErrorCode SetPara_Raw(IntPtr ubidi, string text, int offset, int length)
		@{
			UErrorCode errorCode = U_ZERO_ERROR;
			ubidi_setPara((UBiDi*)ubidi, (const ::UChar*)(text + offset), length, UBIDI_DEFAULT_LTR, NULL, &errorCode);
			return (int)errorCode;
		@}

		[Foreign(Language.CPlusPlus)]
		static ICU.ErrorCode GetLevels(IntPtr ubidi, byte[] outLevels, int length)
		@{
			UErrorCode errorCode = U_ZERO_ERROR;
			const UBiDiLevel* levels = ubidi_getLevels((UBiDi*)ubidi, &errorCode);
			if (U_FAILURE(errorCode))
				return (int)errorCode;
			memcpy(outLevels, levels, length);
			return (int)errorCode;
		@}

		[Foreign(Language.CPlusPlus)]
		static IntPtr Open()
		@{
			return ubidi_open();
		@}

		[Foreign(Language.CPlusPlus)]
		static void Close(IntPtr ubidi)
		@{
			return ubidi_close((UBiDi*)ubidi);
		@}
	}
}
