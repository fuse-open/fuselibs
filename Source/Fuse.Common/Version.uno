using Uno;
using Uno.IO;
using Uno.Text;

namespace Fuse
{
	/** Get information about the current Fuse library version */
	public static class Version
	{
		internal class Parser
		{
			readonly TextReader _textReader;

			Parser(TextReader textReader)
			{
				_textReader = textReader;
			}

			char Peek()
			{
				var ret = _textReader.Peek();
				if (ret < 0)
					return '\0';

				return (char)ret;
			}

			char Consume()
			{
				var ret = _textReader.Read();
				if (ret < 0)
					throw new Exception("Unexpected end of string");

				return (char)ret;
			}

			void Expect(char ch)
			{
				if (Peek() != ch)
					throw new Exception("Unexpected character: " + Peek());
				Consume();
			}

			int ParseInt()
			{
				if (!char.IsDigit(Peek()))
					throw new Exception("Unexpected character: " + Peek());

				var sb = new StringBuilder();
				while (char.IsDigit(Peek()))
					sb.Append(Consume());

				return int.Parse(sb.ToString());
			}

			int3 ParseVersion()
			{
				int3 result;
				result.X = ParseInt();
				Expect('.');
				result.Y = ParseInt();
				Expect('.');
				result.Z = ParseInt();
				return result;
			}

			public static int3 Parse(string str)
			{
				var p = new Parser(new Uno.IO.StringReader(str));
				return p.ParseVersion();
			}
		}

		static Version()
		{
			var versionString = @(PACKAGE_VERSION);

			String = versionString;

			try
			{
				var version = Parser.Parse(versionString);
				Major = version.X;
				Minor = version.Y;
				Patch = version.Z;
			}
			catch (Exception e)
			{
				Fuse.Diagnostics.InternalError(string.Format("Failed to parse version-string: \"{0}\"", versionString), null);
			}
		}

		/** The major version number */
		public static readonly int Major;

		/** The minor version number */
		public static readonly int Minor;

		/** The patch version number */
		public static readonly int Patch;

		/** The full version number, following the Semantic Versioning specification */
		public static readonly string String;
	}
}
