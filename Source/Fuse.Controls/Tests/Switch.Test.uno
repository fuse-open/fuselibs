using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Test
{
	public class SwitchTest : TestBase
	{
		[Test]
		public void AllElementProps()
		{
			var s = new Switch();
			ElementPropertyTester.All(s);
		}

		[Test]
		public void AllLayoutTets()
		{
			var s = new Switch();
			ElementLayoutTester.All(s);
		}

		[Test]
		public void HasIsToggled00()
		{
			var e = new Switch();
			Assert.IsFalse(e.Value);
		}

		[Test]
		public void HasIsToggled01()
		{
			var e = new Switch();
			e.Value = true;
			Assert.IsTrue(e.Value);
		}

		[Test]
		public void HasIsToggled02()
		{
			var e = new Switch();
			e.Value = false;
			Assert.IsFalse(e.Value);
		}

		[Test]
		public void HasIsToggled03()
		{
			var e = new Switch();
			e.Value = false;
			Assert.IsFalse(e.Value);
		}

		[Test]
		public void HasIsToggled04()
		{
			var e = new Switch();
			e.Value = true;
			Assert.IsTrue(e.Value);
			e.Value = false;
			Assert.IsFalse(e.Value);
		}


		[Test]
		public void ToggledChanged00()
		{
			var e = new Switch();
			var helper = new ToggledChangedHelper(e);
			Assert.AreEqual(0, helper.ToggledChangedNum);
		}

		class ToggledChangedHelper
		{
			public int ToggledChangedNum { get; private set; }

			public ToggledChangedHelper(Switch e)
			{
				e.ValueChanged += ValueChanged;
			}

			void ValueChanged(object sender, EventArgs e)
			{
				ToggledChangedNum = ToggledChangedNum + 1;
			}
		}

		[Test]
		public void ToggledChanged01()
		{
			var e = new Switch();
			var helper = new ToggledChangedHelper(e);
			e.Value = false; // Setting to false doesn't toggle, same value!
			Assert.AreEqual(0, helper.ToggledChangedNum);
		}

		[Test]
		public void ToggledChanged02()
		{
			var e = new Switch();
			var helper = new ToggledChangedHelper(e);
			e.Value = true;
			Assert.AreEqual(1, helper.ToggledChangedNum);
		}

		[Test]
		public void ToggledChanged03()
		{
			var e = new Switch();
			var helper = new ToggledChangedHelper(e);
			e.Value = false;
			e.Value = false; 
			Assert.AreEqual(0, helper.ToggledChangedNum);
		}

		[Test]
		public void ToggledChanged04()
		{
			var e = new Switch();
			var helper = new ToggledChangedHelper(e);
			e.Value = true;
			e.Value = true;
			Assert.AreEqual(1, helper.ToggledChangedNum);
		}

		[Test]
		public void ToggledChanged05()
		{
			var e = new Switch();
			var helper = new ToggledChangedHelper(e);
			e.Value = true;
			e.Value = false;
			Assert.AreEqual(2, helper.ToggledChangedNum);
		}

		[Test]
		public void ToggledChanged06()
		{
			var e = new Switch();
			var helper = new ToggledChangedHelper(e);
			e.Value = false;
			Assert.AreEqual(0, helper.ToggledChangedNum);
		}

		[Test]
		public void ToggledChanged07()
		{
			var e = new Switch();
			var helper = new ToggledChangedHelper(e);
			e.Value = false;
			Assert.AreEqual(0, helper.ToggledChangedNum);
		}
	}
}
