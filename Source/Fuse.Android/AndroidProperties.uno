using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse
{

	extern(Android) public static class AndroidProperties
	{

		public static int BuildVersion
		{
			get { return GetBuildVersion(); }
		}
		
		public static string ReleaseVersion
		{
			get { return GetReleaseVersion(); }
		}

		[Foreign(Language.Java)]
		static int GetBuildVersion()
		@{
			return android.os.Build.VERSION.SDK_INT;
		@}
		
		[Foreign(Language.Java)]
		static string GetReleaseVersion()
		@{
			return android.os.Build.VERSION.RELEASE;
		@}

	}

}
