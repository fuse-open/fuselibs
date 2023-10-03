using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Text.Implementation
{
	[extern(LINUX) Require("linkLibrary", "icuuc")]
	[extern(LINUX) Require("linkLibrary", "icudata")]
	[extern(HOST_MAC && (PInvoke || NATIVE)) Require("linkLibrary", "icucore")]
	[extern(HOST_MAC && (PInvoke || NATIVE)) Require("includeDirectory", "@('../icu/i18n':path)")]
	[extern(HOST_MAC && (PInvoke || NATIVE)) Require("includeDirectory", "@('../icu/common':path)")]
	[extern(iOS) Require("linkLibrary", "icuuc")]
	[extern(iOS) Require("linkLibrary", "icudata")]
	[extern(iOS) Require("includeDirectory", "@('../icu/iOS/include':path)")]
	[extern(iOS) Require("linkDirectory", "@('../icu/iOS/':path)")]
	[extern(HOST_WINDOWS && (PInvoke || NATIVE)) Require("linkLibrary", "icudt")]
	[extern(HOST_WINDOWS && (PInvoke || NATIVE)) Require("linkLibrary", "icuin")]
	[extern(HOST_WINDOWS && (PInvoke || NATIVE)) Require("linkLibrary", "icuio")]
	[extern(HOST_WINDOWS && (PInvoke || NATIVE)) Require("linkLibrary", "icule")]
	[extern(HOST_WINDOWS && (PInvoke || NATIVE)) Require("linkLibrary", "iculx")]
	[extern(HOST_WINDOWS && (PInvoke || NATIVE)) Require("linkLibrary", "icutu")]
	[extern(HOST_WINDOWS && (PInvoke || NATIVE)) Require("linkLibrary", "icuuc")]
	[extern(HOST_WINDOWS && (PInvoke || NATIVE)) Require("includeDirectory", "@('../icu/x64/include':path)")]
	[extern(HOST_WINDOWS && (PInvoke || NATIVE)) Require("linkDirectory", "@('../icu/x64/lib64':path)")]
	[extern(CPlusPlus || PInvoke) Require("source.include", "unicode/utypes.h")]
	static extern(USE_ICU) class ICU
	{
		public enum ErrorCode : int { }

		public static void CheckError(ErrorCode errorCode)
		{
			if (IsFailure(errorCode) != 0)
			{
				throw new Exception("UBiDi error: " + CString.ToString(ErrorCString(errorCode)));
			}
		}

		// Return `int` because `bool` marshalling in .NET is... weird
		[Foreign(Language.CPlusPlus)]
		static int IsFailure(ErrorCode errorCode)
		@{
			return U_FAILURE((::UErrorCode)errorCode);
		@}

		[Foreign(Language.CPlusPlus)]
		static IntPtr ErrorCString(ErrorCode errorCode)
		@{
			return (void*)u_errorName((::UErrorCode)errorCode);
		@}
	}
}
