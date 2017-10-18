using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Navigation;
using FuseTest;

namespace Fuse.Reactive.Test
{
	[UXFunction("never_yield")]
	public class VarArgsTestNeverYield: Fuse.Reactive.SimpleVarArgFunction
	{
		// A function that never yields any value
	}

	[UXFunction("varargs_test")]
	public class VarArgsTestFunc: Fuse.Reactive.SimpleVarArgFunction
	{
		internal static int C;

		protected override void OnNewPartialArguments(Argument[] args, IListener listener)
		{
			// We want to get this callback exactly 3 times for args.Length == 3 (0, 1 and 2 arguments ready)
			if (args.Length == 3) 
			{
				C++;
				Assert.IsFalse(args[1].HasValue);
			}
			base.OnNewPartialArguments(args, listener);
		}

		protected override void OnNewArguments(Argument[] args, IListener listener)
		{
			if (args.Length == 8)
			{
				Assert.AreEqual(1, args[0].Value);
				Assert.AreEqual(34, args[7].Value);
			}
			else if (args.Length == 4)
			{
				Assert.AreEqual(1, args[0].Value);
				Assert.AreEqual(1, args[3].Value);
			}
			else if (args.Length == 1)
			{
				// Parenthesized comma-expressions should parse as vectors
				Assert.AreEqual(float2(19,2), Marshal.ToFloat2(args[0].Value));
			}
			else if (args.Length != 0)
			{
				// We don't want to see the one with 3 components where the middle component never yields
				Assert.IsTrue(false);
			}
			listener.OnNewData(this, 12);
		}
	}

	public class VarArgs : TestBase
	{
		[Test]
		public void Basics()
		{
			var e = new UX.VarArgs();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual("48", e.t.Value);
				Assert.AreEqual(3, VarArgsTestFunc.C);
			}
		}
	}
}
