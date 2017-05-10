using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Test
{
	public class SliderTest : TestBase
	{
		[Test]
		public void AllElementProps()
		{
			var s = new Slider();
			ElementPropertyTester.All(s);
		}

		[Test]
		public void AllLayoutTets()
		{
			var s = new Slider();
			ElementLayoutTester.All(s);
		}


		class SliderEventHelper
		{
			public int NumRangeChangedCalled { get; private set; }
			public int NumValueChangedCalled { get; private set; }

			public SliderEventHelper(Slider e)
			{
				e.ProgressChanged += ProgressChanged;
				e.ValueChanged += ValueChanged;
			}

			void ProgressChanged(object sender, EventArgs args)
			{
				NumRangeChangedCalled = NumRangeChangedCalled + 1;
			}

			void ValueChanged(object sender, EventArgs args)
			{
				NumValueChangedCalled = NumValueChangedCalled + 1;
			}
		}

	}
}
