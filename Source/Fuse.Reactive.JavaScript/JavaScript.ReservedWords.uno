using Uno.Collections;

namespace Fuse.Reactive
{
	partial class JavaScript
	{
		// Taken from the ECMAScript 5.1 Standard
		// https://www.ecma-international.org/publications/files/ECMA-ST-ARCH/ECMA-262%205th%20edition%20December%202009.pdf
		static HashSet<string> _reservedKeywords = new HashSet<string>()
		{
			"break", "do", "instanceof", "typeof",
			"case", "else", "new", "var",
			"catch", "finally", "return", "void",
			"continue", "for", "switch", "while",
			"debugger", "function", "this", "with",
			"default", "if", "throw",
			"delete", "in", "try", 
			"undefined" // not actually a reserved word in the spec, but most linters etc treat it as such
		};

		internal static bool IsReservedKeyword(string s)
		{
			return _reservedKeywords.Contains(s);
		}

		internal static string ToValidName(string name)
		{
			return IsReservedKeyword(name) ? "$" + name : name;
		}
	}
}