using Uno;

namespace Fuse.Scripting
{
	public class ScriptException: Uno.Exception
	{
		public string Name { get; private set;}
		public string FileName { get; private set;}
		public int LineNumber { get; private set;}
		public string ScriptStackTrace { get; private set; }

		[Obsolete("Use ScriptException.Message instead")]
		public string ErrorMessage { get { return Message; } }

		[Obsolete("Use ScriptException.ScriptStackTrace instead")]
		public string JSStackTrace { get { return ScriptStackTrace; } }

		[Obsolete]
		public string SourceLine { get { return null; } }

		public ScriptException(
			string name,
			string message,
			string fileName,
			int lineNumber,
			string stackTrace) : base(message)
		{
			Name = name;
			FileName = fileName;
			LineNumber = lineNumber;
			ScriptStackTrace = stackTrace;
		}

		public override string ToString()
		{
			var stringBuilder = new Uno.Text.StringBuilder();
			if (!string.IsNullOrEmpty(Name))
			{
				stringBuilder.Append("Name: ");
				stringBuilder.AppendLine(Name);
			}
			if (!string.IsNullOrEmpty(FileName))
			{
				stringBuilder.Append("File name: ");
				stringBuilder.AppendLine(FileName);
			}
			if (LineNumber >= 0)
			{
				stringBuilder.Append("Line number: ");
				stringBuilder.AppendLine(LineNumber.ToString());
			}
			if (!string.IsNullOrEmpty(ScriptStackTrace))
			{
				stringBuilder.Append("Script stack trace: ");
				stringBuilder.AppendLine(ScriptStackTrace);
			}
			return base.ToString() + "\n" + stringBuilder.ToString();
		}
	}
}
