
namespace Fuse.Scripting
{
	public class ScriptException: Uno.Exception
	{
		public string Name { get; private set;}
		public string ErrorMessage { get; private set;}
		public string FileName { get; private set;}
		public int LineNumber { get; private set;}
		public string SourceLine { get; private set;}
		public string JSStackTrace { get; private set;}

		const int MaxSourceLineLength = 300;
		const string SourceLineTooLongMessage = " ... source line truncated for readability ...";

		public ScriptException(
			string name,
			string errorMessage,
			string fileName,
			int lineNumber,
			string sourceLine,
			string stackTrace)
		{
			Name = name;
			ErrorMessage = errorMessage;
			FileName = fileName;
			LineNumber = lineNumber;
			SourceLine = sourceLine;
			JSStackTrace = stackTrace;
		}

		public override string Message
		{
			get
			{
				var stringBuilder = new Uno.Text.StringBuilder();
				if (!string.IsNullOrEmpty(Name))
				{
					stringBuilder.Append("Name: ");
					stringBuilder.AppendLine(Name);
				}
				if (!string.IsNullOrEmpty(ErrorMessage))
				{
					stringBuilder.Append("Error message: ");
					stringBuilder.AppendLine(ErrorMessage);
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
				if (!string.IsNullOrEmpty(SourceLine))
				{
					stringBuilder.Append("Source line: ");
					if (SourceLine.Length > MaxSourceLineLength)
					{
						stringBuilder.Append(SourceLine.Substring(0, MaxSourceLineLength));
						stringBuilder.AppendLine(SourceLineTooLongMessage);
					}
					else
					{
						stringBuilder.AppendLine(SourceLine);
					}
				}
				if (!string.IsNullOrEmpty(JSStackTrace))
				{
					stringBuilder.Append("JS stack trace: ");
					stringBuilder.AppendLine(JSStackTrace);
				}
				return stringBuilder.ToString();
			}
		}
	}
}
