using Uno.Collections;
using Uno.Testing;
using Uno.Text;
using Uno;

using FuseTest;

using Fuse.Text.Test;

namespace Fuse.Text.Bidirectional.Test
{
	public class BidirectionalTest : TestBase
	{
		public void Visual(int startLevel, string xs, string expected)
		{
			var logical = Util.MockLineShapedRuns(new Substring(xs), startLevel);
			var visual = Runs.GetVisual(logical);

			var sb = new StringBuilder();
			foreach (var s in visual)
				sb.Append(s.Run.String.ToString());
			Assert.AreEqual(expected, sb.ToString());
		}

		[Test]
		public void LTRVisuals()
		{
			Visual(0, "car", "car");
			Visual(0, "CAR", "CAR");
			Visual(0, "car CAR", "carCAR");
			Visual(0, "CAR car", "CARcar");
			Visual(0, "car CAR bar", "carCARbar");
			Visual(0, "CAR car BAR", "CARcarBAR");
		}

		[Test]
		public void RTLVisuals()
		{
			Visual(1, "car", "car");
			Visual(1, "CAR", "CAR");
			Visual(1, "car CAR ", "CARcar");
			Visual(1, "CAR car ", "carCAR");
			Visual(1, "car CAR bar ", "barCARcar");
			Visual(1, "CAR car BAR ", "BARcarCAR");
		}
	}
}
