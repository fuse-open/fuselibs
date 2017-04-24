using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Text.Bidirectional.Implementation
{
	[ForeignInclude(Language.Java, "java.text.Bidi")]
	static extern(Android) class JavaRuns
	{
		public static List<Run> GetLogical(Substring text)
		{
			var result = new List<Run>();
			var handle = Create(text.ToString());
			var count = GetRunCount(handle);

			for (int run = 0; run < count; ++run)
			{
				var start = GetRunStart(handle, run);
				var limit = GetRunLimit(handle, run);
				var str = text.GetSubstring(start, limit - start);
				result.Add(new Run(str, GetRunLevel(handle,run)));
			}

			return result;
		}

		[Foreign(Language.Java)]
		static Java.Object Create(string text)
		@{
			return new Bidi(text, Bidi.DIRECTION_DEFAULT_LEFT_TO_RIGHT);
		@}

		[Foreign(Language.Java)]
		static int GetRunCount(Java.Object handle)
		@{
			return ((Bidi)handle).getRunCount();
		@}

		[Foreign(Language.Java)]
		static int GetBaseLevel(Java.Object handle)
		@{
			return ((Bidi)handle).getBaseLevel();
		@}

		[Foreign(Language.Java)]
		static int GetRunStart(Java.Object handle, int run)
		@{
			return ((Bidi)handle).getRunStart(run);
		@}

		[Foreign(Language.Java)]
		static int GetRunLimit(Java.Object handle, int run)
		@{
			return ((Bidi)handle).getRunLimit(run);
		@}

		[Foreign(Language.Java)]
		static int GetRunLevel(Java.Object handle, int run)
		@{
			return ((Bidi)handle).getRunLevel(run);
		@}
	}
}
