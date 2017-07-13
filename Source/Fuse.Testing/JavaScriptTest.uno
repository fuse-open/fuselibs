using Uno;
using Uno.UX;

using Fuse.Reactive;
using Fuse.Scripting;

namespace Fuse.Testing
{
	class TestFailedException : Exception
	{
		public TestFailedException(string message) : base(message)
		{
		}
	}

	[UXGlobalModule]
	public sealed class UnoTestingHelper : NativeModule
	{
		static readonly UnoTestingHelper _instance;
		public UnoTestingHelper()
		{
			if(_instance != null)
				return;

			Uno.UX.Resource.SetGlobalKey(_instance = this, "FuseJS/Internal/UnoTestingHelper");
			AddMember(new NativeFunction("testFailed", TestFailed));
		}

		class TestFailure
		{
			readonly string _message;
			public TestFailure(string message)
			{
				_message = message;
			}

			public void Fail()
			{
				throw new TestFailedException(_message);
			}
		}

		static object TestFailed(Scripting.Context c, object[] args)
		{
			var message = args[0].ToString();
			UpdateManager.PostAction(new TestFailure(message).Fail);
			return null;
		}
	}

	public class JavaScriptTest : JavaScript
	{
		[UXConstructor]
		public JavaScriptTest([UXAutoNameTable] NameTable nameTable) : base(nameTable)
		{
			ScriptModule.Preamble = "try {\n";
			ScriptModule.Postamble = "\n} catch (err) {\n" +
			                          "\tvar helper = require(\"FuseJS/Internal/UnoTestingHelper\");\n" +
			                          "\thelper.testFailed(\"stack\" in err ? err.stack : err.message);\n" +
			                          "}\n";
		}
	}
}
