using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Animations;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Gestures;
using Fuse.Input;
using Fuse.Triggers;
using Fuse.Triggers.Actions;
using FuseTest;

namespace Fuse.Triggers.Test
{
	public class VariousTriggerTest : TestBase
	{
		[Test]
		public void WhileToggled1()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new Switch(), new WhileTrue());
				var switchControl = (Switch)setup.Control;

				switchControl.Value = true;
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

				switchControl.Value = false;
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		public void WhileToggled2()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new Switch() { Value = true }, new WhileTrue());
				var switchControl = (Switch)setup.Control;

				switchControl.Value = false;
				root.PumpDeferred();
				Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);

				switchControl.Value = true;
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void WhileContainsText()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new TextInput(), new WhileContainsText());
				var textInput = (TextInput)setup.Control;

				textInput.Value = "some text";
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

				textInput.Value = "";
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void TextViewWhileContainsText()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new TextView(), new WhileContainsText());
				var textInput = (TextView)setup.Control;

				textInput.Value = "some text";
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

				textInput.Value = "";
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void ContainingText()
		{
			using (var root = new TestRootPanel())
			{
				//deprecated trigger
				SetupEntity setup = null;
				using (var dg = new RecordDiagnosticGuard())
				{
					setup = SetupHelper.Setup(root, new TextInput() { Value = "some text" }, new ContainingText());

					var diagnostics = dg.DequeueAll();
					Assert.AreEqual(1, diagnostics.Count);
					Assert.AreEqual(DiagnosticType.Deprecated, diagnostics[0].Type);
					Assert.Contains("Use the trigger WhileContainsText instead", diagnostics[0].Message);
				}
				var textInput = (TextInput)setup.Control;

				textInput.Value = "";
				root.PumpDeferred();
				Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);

				textInput.Value = "some text";
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void WhileEnabled()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new TextInput(), new WhileEnabled());

				setup.Control.IsEnabled = false;
				root.PumpDeferred();
				Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);

				setup.Control.IsEnabled = true;
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void WhileEnabled_2()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new TextInput() { IsEnabled = false }, new WhileEnabled());

				setup.Control.IsEnabled = true;
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

				setup.Control.IsEnabled = false;
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void WhileDisabled()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new TextInput(), new WhileDisabled());

				setup.Control.IsEnabled = false;
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

				setup.Control.IsEnabled = true;
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void WhileDisabled_2()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new TextInput() { IsEnabled = false }, new WhileDisabled());

				setup.Control.IsEnabled = true;
				root.PumpDeferred();
				Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);

				setup.Control.IsEnabled = false;
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void Removing()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new TextInput(), new RemovingAnimation());

				setup.Panel.BeginRemoveChild(setup.Control);
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(0, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		public void Focusing()
		{
			var focusPanel = new Panel();
			Focus.SetIsFocusable(focusPanel, true);

			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, focusPanel, new WhileFocused());

				Focus.GiveTo(setup.Control);
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

				Focus.Release();
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		public void WhileFocusWithin()
		{
			var focusPanel = new Panel();
			Focus.SetIsFocusable(focusPanel, true);

			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, focusPanel, new WhileFocusWithin());

				Focus.GiveTo(setup.Control);
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

				Focus.Release();
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		public void ScrollRange()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new ScrollView() { AllowedScrollDirections = ScrollDirections.Vertical }, new ScrollingAnimation() { From = 0, To = 10 });
				var scrollView = (ScrollView)setup.Control;

				scrollView.ScrollPosition = float2 (0,20);
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

				scrollView.ScrollPosition = float2 (0,0);
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}

		[Test]
		public void ScrollRange_2()
		{
			using (var root = new TestRootPanel())
			{
				var setup = SetupHelper.Setup(root, new ScrollView() { AllowedScrollDirections = ScrollDirections.Vertical, ScrollPosition = float2 (0,20) }, new ScrollingAnimation() { From = 0, To = 10 });
				var scrollView = (ScrollView)setup.Control;

				scrollView.ScrollPosition = float2 (0,0);
				root.PumpDeferred();
				Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);

				scrollView.ScrollPosition = float2 (0,10);
				root.PumpDeferred();
				Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
				Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			}
		}
	}
}
