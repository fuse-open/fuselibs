using Uno;

namespace Fuse.Controls
{
	internal static class EnumHelpers
	{
		public static string AsString<T>(T e) where T: struct
		{
			return e.ToString().ToLower();
		}

		public static T As<T>(string str) where T: struct
		{
			T result = default(T);
			if (Uno.Enum.TryParse<T>(str, true, out result))
				return result;
			else
				throw new Exception("Unexpected " + typeof(T).FullName + ": " + str);
		}
	}
}
