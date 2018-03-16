using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Reactive;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ExpressionSourcesTest : TestBase
	{
		[Test]
		// Expressions are objects that are created by the UX compiler and not explicitly declared as UX objects, so we should double-check that
		//  correct source information is generated for them.
		public void ExpressionSources()
		{
			var p = new UX.ExpressionSources();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				// Dig into expr object and make sure its sources are what we expect
				var binding = (ExpressionBinding)p.V.Bindings[0];
				var addExpr = (Add)binding.Key;
				Assert.AreEqual(4, addExpr.SourceLineNumber);
				Assert.AreEqual("UX/ExpressionSources.ux", addExpr.SourceFileName);
				var lhsSin = (Sin)addExpr.Left;
				Assert.AreEqual(4, lhsSin.SourceLineNumber);
				Assert.AreEqual("UX/ExpressionSources.ux", lhsSin.SourceFileName);
				var lhsProp = (Property)lhsSin.Operand;
				Assert.AreEqual(4, lhsProp.SourceLineNumber);
				Assert.AreEqual("UX/ExpressionSources.ux", lhsProp.SourceFileName);
				var lhsConst = (Constant)lhsProp.Object;
				Assert.AreEqual(4, lhsConst.SourceLineNumber);
				Assert.AreEqual("UX/ExpressionSources.ux", lhsConst.SourceFileName);
				var rhsCos = (Cos)addExpr.Right;
				Assert.AreEqual(4, rhsCos.SourceLineNumber);
				Assert.AreEqual("UX/ExpressionSources.ux", rhsCos.SourceFileName);
				var rhsProp = (Property)rhsCos.Operand;
				Assert.AreEqual(4, rhsProp.SourceLineNumber);
				Assert.AreEqual("UX/ExpressionSources.ux", rhsProp.SourceFileName);
				var rhsConst = (Constant)rhsProp.Object;
				Assert.AreEqual(4, rhsConst.SourceLineNumber);
				Assert.AreEqual("UX/ExpressionSources.ux", rhsConst.SourceFileName);
			}
		}
	}
}