using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Elements;
using Fuse.Controls;

namespace Fuse.Navigation.Test
{
	using global::UX;

	public class RouteParamValidation : TestBase
	{
		[Test]
		public void ValidParam1()
		{
			var p = new UX.RouteParamValidation();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				p.GotoTest1.Perform();
				root.StepFrameJS();
				root.StepFrameJS();

				Assert.AreEqual("\"param_string\"", p.GetParamValue("page1"));
				p.Children.Clear();
			}
		}

		[Test]
		public void ValidParam2()
		{
			var p = new UX.RouteParamValidation();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				p.GotoTest2.Perform();
				root.StepFrameJS();
				root.StepFrameJS();

				Assert.AreEqual("{\"hello\":\"world\",\"number\":1337}", p.GetParamValue("page2"));
			}
		}

		[Test]
		public void BadParam1()
		{
			var p = new UX.RouteParamValidation();

			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			using (var dg = new RecordDiagnosticGuard())
			{
				p.GotoTest3.Perform();
				root.StepFrameJS();

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(2, diagnostics.Count);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[0].Type);
				Assert.Contains("Route parameter must be serializeable, cannot contain functions.", diagnostics[0].Message);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[1].Type);
				Assert.Contains("Router.goto(): invalid route provided", diagnostics[1].Message);
			}
		}

		[Test]
		public void BadParam2()
		{
			var p = new UX.RouteParamValidation();

			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			using (var dg = new RecordDiagnosticGuard())
			{
				p.GotoTest4.Perform();
				root.StepFrameJS();

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(2, diagnostics.Count);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[0].Type);
				Assert.Contains("Route parameter must be serializeable, cannot contain functions.", diagnostics[0].Message);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[1].Type);
				Assert.Contains("Router.goto(): invalid route provided", diagnostics[1].Message);
			}
		}

		[Test]
		public void BadParam3()
		{
			var p = new UX.RouteParamValidation();

			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			using (var dg = new RecordDiagnosticGuard())
			{
				p.GotoTest6.Perform();
				root.StepFrameJS();

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(2, diagnostics.Count);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[0].Type);
				Assert.Contains("Route parameter must be serializeable, cannot contain Observables.", diagnostics[0].Message);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[1].Type);
				Assert.Contains("Router.goto(): invalid route provided", diagnostics[1].Message);
			}
		}

		[Test]
		public void NestedObjects()
		{
			var p = new UX.RouteParamValidation();

			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			using (var dg = new RecordDiagnosticGuard())
			{
				p.GotoTest5.Perform();
				root.StepFrameJS();

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(3, diagnostics.Count);
				Assert.AreEqual(DiagnosticType.UserWarning, diagnostics[0].Type);
				Assert.Contains("JavaScript data model contains circular references or is too deep. Some data may not display correctly.", diagnostics[0].Message);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[1].Type);
				Assert.Contains("Route parameter must be serializeable, it contains reference loops or is too large", diagnostics[1].Message);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[2].Type);
				Assert.Contains("Router.goto(): invalid route provided", diagnostics[2].Message);
			}
		}

	}
}

namespace UX
{
	public static class Helper
	{
		public static string GetParamValue(this RouteParamValidation rpv, string templateName)
		{
			foreach (var c in rpv._navigator.Children)
			{
				var rp = c as RouterPanel;
				if (rp != null && rp.Name == (Selector)templateName)
				{
					return rp.ParamValue;
				}
			}
			return null;
		}
	}

}
