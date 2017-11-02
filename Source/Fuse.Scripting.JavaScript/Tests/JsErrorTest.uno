using Uno;
using Uno.Testing;

using FuseTest;
using Fuse.Scripting;

namespace Fuse.Reactive.Test
{
	public class JsErrorTest : TestBase
	{
		[Test]
		public void UnknownSymbol()
		{
			using (var dg = new RecordDiagnosticGuard())
			{
				var e = new UX.Error.UnknownSymbol();
				using (var root = TestRootPanel.CreateWithChild(e))
					root.StepFrameJS();

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(1, diagnostics.Count);
				var s = (ScriptException)diagnostics[0].Exception;
				if (s.SourceLine != null)
					Assert.Contains("none()", s.SourceLine);
				Assert.AreEqual(3, s.LineNumber);
				Assert.Contains("Error.UnknownSymbol.ux", s.FileName);
			}
		}
		
		[Test]
		[Ignore("https://github.com/fusetools/fuselibs-public/issues/679", "Android")]
		public void RequireInvalid()
		{
			using (var dg = new RecordDiagnosticGuard())
			{
				var e = new UX.Error.RequireInvalid();
				using (var root = TestRootPanel.CreateWithChild(e))
					root.StepFrameJS();

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(1, diagnostics.Count);
				var s = (ScriptException)diagnostics[0].Exception;
				if (s.SourceLine != null)
					Assert.Contains("require(\"FuseJS/Pinecone\")", s.SourceLine);
				if (s.LineNumber >= 0)
					Assert.AreEqual(3, s.LineNumber);
				if (s.FileName != null)
					Assert.Contains("Error.RequireInvalid.ux", s.FileName);
				Assert.Contains("module not found: FuseJS/Pinecone", s.ErrorMessage);
			}
		}
		
		[Test]
		/** Simple reading of undefined value in a Call closure to exported function */
		public void ReadUndefined()
		{
			var e = new UX.Error.ReadUndefined();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				using (var dg = new RecordDiagnosticGuard())
				{
					e.CallFlub.Perform();
					root.StepFrameJS();

					var diagnostics = dg.DequeueAll();
					Assert.AreEqual(1, diagnostics.Count);
					var s = (ScriptException)diagnostics[0].Exception;
					if (s.SourceLine != null)
						Assert.Contains("q.value.x", s.SourceLine);
					Assert.AreEqual(6, s.LineNumber);
					Assert.Contains("Error.ReadUndefined.ux", s.FileName);
				}
			}
		}
		
		[Test]
		[Ignore("https://github.com/fusetools/fuselibs/issues/2855")]
		/* Tests a particularly tricky place for an exception in JavaScript. */
		public void OnValueChanged()
		{
			using (var dg = new RecordDiagnosticGuard())
			{
				var e = new UX.Error.OnValueChanged();
				using (var root = TestRootPanel.CreateWithChild(e))
					root.StepFrameJS();

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(1, diagnostics.Count);
				var s = (ScriptException)diagnostics[0].Exception;
				if (s.SourceLine != null)
					Assert.Contains("newValue.value[0]", s.SourceLine);
				Assert.AreEqual(12, s.LineNumber);
				Assert.Contains("Error.OnValueChanged.ux", s.FileName);
				//it's uncertain how stable these error messages are
				Assert.Contains("Cannot read property '0' of undefined", s.ErrorMessage);
			}
		}
	}
}
