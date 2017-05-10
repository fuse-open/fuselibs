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
	public class VariousTriggerTests : TestBase
	{
		private TestRootPanel _root;

		public VariousTriggerTests()
		{
			_root = new TestRootPanel();
		}

		[Test]
		public void WhileToggled1()
		{
			var setup = SetupHelper.Setup(_root, new Switch(), new WhileTrue());
			var switchControl = (Switch)setup.Control;

			switchControl.Value = true;
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(0, setup.BackwardAction.PerformedCount);
			
			switchControl.Value = false;
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void WhileToggled2()
		{
			var setup = SetupHelper.Setup(_root, new Switch() { Value = true }, new WhileTrue());
			var switchControl = (Switch)setup.Control;

			switchControl.Value = false;
			_root.PumpDeferred();
			Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			
			switchControl.Value = true;
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void WhileContainsText()
		{
			var setup = SetupHelper.Setup(_root, new TextInput(), new WhileContainsText());
			var textInput = (TextInput)setup.Control;

			textInput.Value = "some text";
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(0, setup.BackwardAction.PerformedCount);
			
			textInput.Value = "";
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void TextViewWhileContainsText()
		{
			var setup = SetupHelper.Setup(_root, new TextView(), new WhileContainsText());
			var textInput = (TextView)setup.Control;

			textInput.Value = "some text";
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(0, setup.BackwardAction.PerformedCount);
			
			textInput.Value = "";
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void ContainingText()
		{
			//deprecated trigger
			SetupEntity setup = null;
			using (var dg = new RecordDiagnosticGuard())
			{
				setup = SetupHelper.Setup(_root, new TextInput() { Value = "some text" }, new ContainingText());

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(1, diagnostics.Count);
				Assert.AreEqual(DiagnosticType.Deprecated, diagnostics[0].Type);
				Assert.Contains("Use the trigger WhileContainsText instead", diagnostics[0].Message);
			}
			var textInput = (TextInput)setup.Control;

			textInput.Value = "";
			_root.PumpDeferred();
			Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
			
			textInput.Value = "some text";
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void WhileEnabled()
		{
			var setup = SetupHelper.Setup(_root, new TextInput(), new WhileEnabled());

			setup.Control.IsEnabled = false;
			_root.PumpDeferred();
			Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);

			setup.Control.IsEnabled = true;
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void WhileEnabled_2()
		{
			var setup = SetupHelper.Setup(_root, new TextInput() { IsEnabled = false }, new WhileEnabled());

			setup.Control.IsEnabled = true;
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

			setup.Control.IsEnabled = false;
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void WhileDisabled()
		{
			var setup = SetupHelper.Setup(_root, new TextInput(), new WhileDisabled());

			setup.Control.IsEnabled = false;
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

			setup.Control.IsEnabled = true;
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void WhileDisabled_2()
		{
			var setup = SetupHelper.Setup(_root, new TextInput() { IsEnabled = false }, new WhileDisabled());

			setup.Control.IsEnabled = true;
			_root.PumpDeferred();
			Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);

			setup.Control.IsEnabled = false;
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void Removing()
		{
			var setup = SetupHelper.Setup(_root, new TextInput(), new RemovingAnimation());

			setup.Panel.BeginRemoveChild(setup.Control);
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(0, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void Focusing()
		{
			var focusPanel = new Panel();
			Focus.SetIsFocusable(focusPanel, true);
			var setup = SetupHelper.Setup(_root, focusPanel, new WhileFocused());
				
			Focus.GiveTo(setup.Control);
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(0, setup.BackwardAction.PerformedCount);
			
			Focus.Release();
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void WhileFocusWithin()
		{
			var focusPanel = new Panel();
			Focus.SetIsFocusable(focusPanel, true);
			var setup = SetupHelper.Setup(_root, focusPanel, new WhileFocusWithin());
				
			Focus.GiveTo(setup.Control);
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(0, setup.BackwardAction.PerformedCount);
			
			Focus.Release();
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void ScrollRange()
		{
			var setup = SetupHelper.Setup(_root, new ScrollView() { AllowedScrollDirections = ScrollDirections.Vertical }, new ScrollingAnimation() { From = 0, To = 10 });
			var scrollView = (ScrollView)setup.Control;

			scrollView.ScrollPosition = float2 (0,20);
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(0, setup.BackwardAction.PerformedCount);

			scrollView.ScrollPosition = float2 (0,0);
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}

		[Test]
		public void ScrollRange_2()
		{
			var setup = SetupHelper.Setup(_root, new ScrollView() { AllowedScrollDirections = ScrollDirections.Vertical, ScrollPosition = float2 (0,20) }, new ScrollingAnimation() { From = 0, To = 10 });
			var scrollView = (ScrollView)setup.Control;

			scrollView.ScrollPosition = float2 (0,0);
			_root.PumpDeferred();
			Assert.AreEqual(0, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);

			scrollView.ScrollPosition = float2 (0,10);
			_root.PumpDeferred();
			Assert.AreEqual(1, setup.ForwardAction.PerformedCount);
			Assert.AreEqual(1, setup.BackwardAction.PerformedCount);
		}
	}
}
