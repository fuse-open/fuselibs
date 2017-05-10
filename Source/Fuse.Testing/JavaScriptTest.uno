using Uno.UX;
using Uno.Testing;

using Fuse.Reactive;
using Fuse.Scripting;

namespace Fuse.Testing
{
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
				Assert.Fail(_message);
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
			_scriptModule.Preamble = "try {\n";
			_scriptModule.Postamble = "\n} catch (err) {\n" +
			                          "\tvar helper = require(\"FuseJS/Internal/UnoTestingHelper\");\n" +
			                          "\thelper.testFailed(\"stack\" in err ? err.stack : err.message);\n" +
			                          "}\n";
		}
	}
}
