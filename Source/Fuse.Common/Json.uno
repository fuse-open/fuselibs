using Uno;
using Uno.Collections;
using Uno.Text;

namespace Fuse
{
	/** Contains tools for serializing scripting objects (based on `IArray` and `IObject`) to Json notation.

	 */
	public static partial class Json
	{
		/** Converts an object to a Json string, optionally normalized in alphabetic order.
			@param normalized Whether to sort object keys in alphabetic order, for object hashing consistency.
		*/
		public static string Stringify(object value, bool normalized = false)
		{
			var sb = new StringBuilder();
			Stringify(value, normalized, sb, new HashSet<object>());
			return sb.ToString();
		}

		static void Stringify(object value, bool normalized, StringBuilder sb, HashSet<object> visitedSet)
		{
			if (value is string) ToLiteral((string)value, sb);
			else if (value is double) sb.Append(ToLiteral((double)value));
			else if (value is float) sb.Append(ToLiteral((double)(float)value));
			else if (value is int) sb.Append(ToLiteral((double)(int)value));
			else if (value is bool) sb.Append(ToLiteral((bool)value));
			else if (value is IObject)
			{
				if (visitedSet.Contains(value))
					throw new Exception("Json.Stringify(): object can not contain cycles");

				visitedSet.Add(value);

				var obj = value as IObject;
				
				sb.Append("{");
				var keys = new string[obj.Keys.Length];
				Uno.Array.Copy(obj.Keys, keys, obj.Keys.Length);
				if (normalized) Uno.Array.Sort(keys, String.Compare);
				for (int i = 0; i < keys.Length; i++)
				{
					if (i > 0) sb.Append(",");
					ToLiteral(keys[i], sb);
					sb.Append(":");
					Stringify(obj[keys[i]], normalized, sb, visitedSet);
				}

				sb.Append("}");

				visitedSet.Remove(value);
			}
			else if (value is IArray)
			{
				if (visitedSet.Contains(value))
					throw new Exception("Json.Stringify(): object can not contain cycles");

				visitedSet.Add(value);

				var arr = value as IArray;

				sb.Append("[");
				for (int i = 0; i < arr.Length; i++)
				{
					if (i > 0) sb.Append(",");
					Stringify(arr[i], normalized, sb, visitedSet);
				}

				sb.Append("]");
				
				visitedSet.Remove(value);
			}
			else sb.Append("null");
		}

		[Obsolete("Use Uno.Data.Json.JsonWriter.QuoteString() instead")]
		public static string Escape(string s)
		{
			var sb = new StringBuilder();
			Escape(s, sb);
			return sb.ToString();
		}

		[Obsolete("Use Uno.Data.Json.JsonWriter.QuoteString() instead")]
		public static void Escape(string s, StringBuilder sb)
		{
			for (int i = 0; i < s.Length; i++)
			{
				if (s[i] == '\"')
				{
					if (sb == null) sb = new StringBuilder();
					sb.Append("\\\"");
				}
				else if (s[i] == '\\')
				{
					if (sb == null) sb = new StringBuilder();
					sb.Append("\\\\");
				}
				else if (s[i] == '\n')
				{
					if (sb == null) sb = new StringBuilder();
					sb.Append("\\n");
				}
				else
				{
					sb.Append(s[i]);
				}
			}
		}

		/** Returns an escaped string encapsulated in Json quotes. */
		public static string ToLiteral(string s)
		{
			return Uno.Data.Json.JsonWriter.QuoteString(s);
		}

		/** Escapes a string encapsulated in Json quotes into a StringBuilder. */
		public static void ToLiteral(string s, StringBuilder sb)
		{
			sb.Append(Uno.Data.Json.JsonWriter.QuoteString(s));
		}

		/** Returns a number as a Json string. */
		public static string ToLiteral(double s)
		{
			if ((int)s == s) return ((int)s).ToString();
			return s.ToString();
		}

		/** Returns the boolean value as a Json literal */
		public static string ToLiteral(bool b)
		{
			if (b) return "true";
			else return "false";
		}
	}
}
