using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Text.Implementation
{
	[extern(HOST_MAC && (PInvoke || CMake)) Require("LinkLibrary", "icucore")]
	[extern(HOST_MAC && (PInvoke || iOS || CMake)) Require("IncludeDirectory", "@('../icu/i18n':Path)")]
	[extern(HOST_MAC && (PInvoke || iOS || CMake)) Require("IncludeDirectory", "@('../icu/common':Path)")]
	[extern(iOS) Require("LinkLibrary", "icuuc")]
	[extern(iOS) Require("LinkLibrary", "icudata")]
	[extern(iOS) Require("LinkDirectory", "@('../icu/iOS/':Path)")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("LinkLibrary", "icudt")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("LinkLibrary", "icuin")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("LinkLibrary", "icuio")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("LinkLibrary", "icule")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("LinkLibrary", "iculx")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("LinkLibrary", "icutu")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("LinkLibrary", "icuuc")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("IncludeDirectory", "@('../icu/x86/icu/include':Path)")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("LinkDirectory","@('../icu/$(PlatformShortName)/icu/lib':Path)")]
	[extern(HOST_WINDOWS && (PInvoke || MSVC)) Require("LinkDirectory","@('../icu/$(PlatformShortName)/icu/lib64':Path)")]
	[extern(CPlusPlus || PInvoke) Require("Source.Include", "unicode/utypes.h")]
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
