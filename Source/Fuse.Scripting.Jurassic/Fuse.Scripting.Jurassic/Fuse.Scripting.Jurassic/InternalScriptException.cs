using System;
using System.Text;
using System.Windows.Forms.Design;
using Jurassic;
using JR = Jurassic;

namespace Fuse.Scripting.Jurassic
{
	public class JurassicException : Exception
	{
		public readonly int LineNumber;
		public readonly string Name;
		public readonly string SourcePath;
		public readonly string FunctionName;
		public readonly string ErrorMessage;
		public readonly string StackTrace;
	
		public JurassicException(JavaScriptException jse)
			: base("", jse)
		{
			LineNumber = jse.LineNumber;
			Name = jse.Name ?? "Unknown";
			SourcePath = jse.SourcePath ?? "N/A";
			FunctionName = jse.FunctionName ?? "N/A";

			var errorObj = jse.ErrorObject as JR.Library.ErrorInstance;
			if (errorObj != null)
			{
				ErrorMessage = errorObj.Message ?? "N/A";
				StackTrace = errorObj.Stack ?? "N/A";
			}
			else
			{
				ErrorMessage = (jse.ErrorObject != null) ? jse.ErrorObject.ToString() : "N/A";
				StackTrace = "N/A";
			}
		}

		string ToMessage()
		{
			var msg = new StringBuilder();
			msg.AppendFormat("LineNumber: {0}\n", LineNumber);
			msg.AppendFormat("Name: {0}\n", Name);
			msg.AppendFormat("SourcePath: {0}\n", SourcePath);
			msg.AppendFormat("FunctionName: {0}\n", FunctionName);
			msg.AppendFormat("ErrorMessage: {0}\n", ErrorMessage);
			msg.AppendFormat("StackTrace: {0}\n", StackTrace);
			return msg.ToString();
		}

		public override string Message
		{
			get { return ToMessage(); }
		}
	}
}