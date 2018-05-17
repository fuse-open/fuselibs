using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.UX;

using FuseTest;

namespace Fuse.Navigation.Test
{
	public class NavigatorModelTest : ModelTestBase
	{
		[Test]
		//from Issue https://github.com/fuse-open/fuselibs/issues/880
		//data for inner is syncrhonously available, and IsRouterOutlet=false
		public void NestedModel()
		{
			var p = new UX.NavigatorModel.Nested();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				
				Assert.AreEqual( "outer,inner", GetRecursiveText(p));
			}
		}
	}	
}
