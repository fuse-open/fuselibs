using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Input;
using FuseTest;

namespace Fuse.Test
{
	class PointerSetupEntity
	{
		public PointerElement ParentPanel { get; private set; }

		public PointerElement ChildPanel { get; private set; }

		public PointerElement Control { get; private set; }

		public PointerSetupEntity(PointerElement parentPanel, PointerElement childPanel, PointerElement dummyControl)
		{
			ParentPanel = parentPanel;
			ChildPanel = childPanel;
			Control = dummyControl;
		}
	}

	class TestPointerEventResponder : IPointerEventResponder
	{
		public readonly List<PointerPressedArgs> PointerPressedArgs = new List<PointerPressedArgs>();
		public void OnPointerPressed(PointerPressedArgs args)
		{
			PointerPressedArgs.Add(args);
		}

		public readonly List<PointerMovedArgs> PointerMovedArgs = new List<PointerMovedArgs>();
		public void OnPointerMoved(PointerMovedArgs args)
		{
			PointerMovedArgs.Add(args);
		}

		public readonly List<PointerReleasedArgs> PointerReleasedArgs = new List<PointerReleasedArgs>();
		public void OnPointerReleased(PointerReleasedArgs args)
		{
			PointerReleasedArgs.Add(args);
		}

		public readonly List<PointerWheelMovedArgs> PointerWheelMovedArgs = new List<PointerWheelMovedArgs>();
		public void OnPointerWheelMoved(PointerWheelMovedArgs args)
		{
			PointerWheelMovedArgs.Add(args);
		}
	}

	public class FusePointerTest : TestBase
	{
		TestRootPanel CreateTestRootPanel()
		{
			var root = new TestRootPanel();
			Fuse.Input.Pointer.RaiseMoved(root, GetZeroPointerEventData());
			Fuse.Input.Pointer.RaiseReleased(root, GetDefaultPointerEventData());
			return root;
		}

		class BubblingSequenceTester
		{
			public BubblingSequenceTester(PointerSetupEntity setup)
			{
				Fuse.Input.Pointer.Pressed.AddHandler(setup.ParentPanel, PointerPressedHandler);
				Fuse.Input.Pointer.Pressed.AddHandler(setup.ChildPanel, PointerPressedHandler);
				Fuse.Input.Pointer.Pressed.AddHandler(setup.Control, PointerPressedHandler);

				Fuse.Input.Pointer.Released.AddHandler(setup.ParentPanel, PointerReleasedHandler);
				Fuse.Input.Pointer.Released.AddHandler(setup.ChildPanel, PointerReleasedHandler);
				Fuse.Input.Pointer.Released.AddHandler(setup.Control, PointerReleasedHandler);
			}

			public void PointerPressedHandler(object sender, PointerPressedArgs args)
			{
				BubblingSequence.Add(((PointerElement)sender).Name);
			}

			public void PointerReleasedHandler(object sender, PointerReleasedArgs args)
			{
				BubblingSequence.Add(((PointerElement)sender).Name);
			}

			public readonly List<string> BubblingSequence = new List<string>();
		}

		[Test]
		public void BubblingSequence()
		{
			using (var root = CreateTestRootPanel())
			{
				var setup = SetupEnvironment(root);
				var bst = new BubblingSequenceTester(setup);

				Fuse.Input.Pointer.RaisePressed(root, GetDefaultPointerEventData());
				Assert.AreEqual(new string[] { "3", "2", "1" }, bst.BubblingSequence.ToArray());

				bst.BubblingSequence.Clear();
				Fuse.Input.Pointer.RaiseReleased(root, GetDefaultPointerEventData());
				Assert.AreEqual(new string[] { "3", "2", "1" }, bst.BubblingSequence.ToArray());
			}
		}

		[Test]
		public void SoftCapture()
		{
			using (var root = CreateTestRootPanel())
			{
				var setup = SetupEnvironment(root, true);

				Fuse.Input.Pointer.RaisePressed(root, GetDefaultPointerEventData());
				Assert.IsTrue(setup.ParentPanel.Captured);
				Assert.IsTrue(setup.ChildPanel.Captured);
				Assert.IsTrue(setup.Control.Captured);

				Fuse.Input.Pointer.RaiseReleased(root, GetDefaultPointerEventData());
				Assert.IsFalse(setup.ParentPanel.Captured);
				Assert.IsFalse(setup.ChildPanel.Captured);
				Assert.IsFalse(setup.Control.Captured);
			}
		}

		[Test]
		public void SoftCaptureParentNoCapture()
		{
			using (var root = CreateTestRootPanel())
			{
				var setup = SetupEnvironment(root, true);
				setup.ChildPanel.SoftCaptureModeEnabled = false;

				Fuse.Input.Pointer.RaisePressed(root, GetDefaultPointerEventData());
				Assert.IsTrue(setup.ParentPanel.Captured);
				Assert.IsFalse(setup.ChildPanel.Captured);
			}
		}

		[Test]
		public void SoftCaptureOutsideOfControls()
		{
			using (var root = CreateTestRootPanel())
			{
				var setup = SetupEnvironment(root, true);

				Fuse.Input.Pointer.RaisePressed(root, GetOutsideOfControlsPointerEventData());
				Assert.IsFalse(setup.ParentPanel.Captured);
				Assert.IsFalse(setup.ChildPanel.Captured);
				Assert.IsFalse(setup.Control.Captured);
			}
		}

		[Test]
		public void HardCapture()
		{
			using (var root = CreateTestRootPanel())
			{
				var setup = SetupEnvironment(root, true, true);

				Fuse.Input.Pointer.RaisePressed(root, GetDefaultPointerEventData());
				Fuse.Input.Pointer.RaiseMoved(root, GetDefaultPointerEventData());
				Assert.IsFalse(setup.ParentPanel.Captured);
				Assert.IsFalse(setup.ChildPanel.Captured);
				Assert.IsTrue(setup.Control.Captured);
			}
		}

		[Test]
		public void HardCaptureControlNoCapture()
		{
			using (var root = CreateTestRootPanel())
			{
				var setup = SetupEnvironment(root, true, true);
				setup.Control.HardCaptureModeEnabled = false;

				Fuse.Input.Pointer.RaisePressed(root, GetDefaultPointerEventData());
				Fuse.Input.Pointer.RaiseMoved(root, GetDefaultPointerEventData());
				Assert.IsFalse(setup.ParentPanel.Captured);
				Assert.IsTrue(setup.ChildPanel.Captured);
				Assert.IsFalse(setup.Control.Captured);
			}
		}

		[Test]
		public void PointerEnterLeave()
		{
			using (var root = CreateTestRootPanel())
			{
				var setup = SetupEnvironment(root);
				Fuse.Input.Pointer.RaiseMoved(root, GetDefaultPointerEventData());
				Assert.IsTrue(setup.ParentPanel.Entered);
				Assert.IsTrue(setup.ChildPanel.Entered);
				Assert.IsTrue(setup.Control.Entered);

				Fuse.Input.Pointer.RaiseMoved(root, GetOutsideOfControlsPointerEventData());
				Assert.IsFalse(setup.ParentPanel.Entered);
				Assert.IsFalse(setup.ChildPanel.Entered);
				Assert.IsFalse(setup.Control.Entered);
			}
		}

		[Test]
		public void PointerEnterLeaveOnRemove()
		{
			using (var root = CreateTestRootPanel())
			{
				var setup = SetupEnvironment(root);
				Fuse.Input.Pointer.RaiseMoved(root, GetDefaultPointerEventData());
				setup.ChildPanel.Children.Remove(setup.Control);
				Fuse.Input.Pointer.RaiseMoved(root, GetDefaultPointerEventData());
				Assert.IsTrue(setup.ParentPanel.Entered);
				Assert.IsTrue(setup.ChildPanel.Entered);
				Assert.IsFalse(setup.Control.Entered);
			}
		}

		[Test]
		public void PointerEnterLeaveOnDisabled()
		{
			using (var root = CreateTestRootPanel())
			{
				var setup = SetupEnvironment(root);
				Fuse.Input.Pointer.RaiseMoved(root, GetDefaultPointerEventData());
				setup.Control.IsEnabled = false;
				Fuse.Input.Pointer.RaiseMoved(root, GetDefaultPointerEventData());
				Assert.IsTrue(setup.ParentPanel.Entered);
				Assert.IsTrue(setup.ChildPanel.Entered);
				Assert.IsFalse(setup.Control.Entered);
			}
		}

		[Test]
		public void EventResponder()
		{
			using (var root = CreateTestRootPanel())
			{
				IPointerEventResponder prevEventResponder = Pointer.EventResponder;
				try
				{
					var testPointerEventResponder = new TestPointerEventResponder();
					Assert.AreEqual(0, testPointerEventResponder.PointerMovedArgs.Count);
					Pointer.EventResponder = testPointerEventResponder;
					Assert.AreEqual(0, testPointerEventResponder.PointerMovedArgs.Count);

					Assert.AreEqual(0, testPointerEventResponder.PointerMovedArgs.Count);
					Fuse.Input.Pointer.RaisePressed(root, GetDefaultPointerEventData());
					Assert.AreEqual(1, testPointerEventResponder.PointerPressedArgs.Count);
					Assert.AreEqual(root, testPointerEventResponder.PointerPressedArgs[0].Visual);
					Assert.AreEqual(0, testPointerEventResponder.PointerMovedArgs.Count);

					Fuse.Input.Pointer.RaiseMoved(root, GetDefaultPointerEventData());
					Assert.AreEqual(1, testPointerEventResponder.PointerMovedArgs.Count);
					Assert.AreEqual(root, testPointerEventResponder.PointerMovedArgs[0].Visual);

					Fuse.Input.Pointer.RaiseReleased(root, GetDefaultPointerEventData());
					Assert.AreEqual(1, testPointerEventResponder.PointerReleasedArgs.Count);
					Assert.AreEqual(root, testPointerEventResponder.PointerReleasedArgs[0].Visual);

					Fuse.Input.Pointer.RaiseWheelMoved(root, GetDefaultPointerEventData());
					Assert.AreEqual(1, testPointerEventResponder.PointerWheelMovedArgs.Count);
					Assert.AreEqual(root, testPointerEventResponder.PointerWheelMovedArgs[0].Visual);
				}
				finally
				{
					Pointer.EventResponder = prevEventResponder;
				}
			}
		}

		PointerEventData GetZeroPointerEventData()
		{
			return new PointerEventData
				{
					PointIndex = 1,
					WindowPoint = float2 (0),
					WheelDelta = float2 (0),
					WheelDeltaMode = Uno.Platform.WheelDeltaMode.DeltaPixel,
					IsPrimary = true,
					PointerType = Uno.Platform.PointerType.Mouse
				};
		}

		PointerEventData GetDefaultPointerEventData()
		{
			return new PointerEventData
				{
					PointIndex = 1,
					WindowPoint = float2 (50),
					WheelDelta = float2 (0),
					WheelDeltaMode = Uno.Platform.WheelDeltaMode.DeltaPixel,
					IsPrimary = true,
					PointerType = Uno.Platform.PointerType.Mouse
				};
		}

		PointerEventData GetOutsideOfControlsPointerEventData()
		{
			return new PointerEventData
				{
					PointIndex = 1,
					WindowPoint = float2 (500),
					WheelDelta = float2 (0),
					WheelDeltaMode = Uno.Platform.WheelDeltaMode.DeltaPixel,
					IsPrimary = true,
					PointerType = Uno.Platform.PointerType.Mouse
				};
		}

		PointerSetupEntity SetupEnvironment(TestRootPanel root, bool softCaptureModeEnabled = false, bool hardCaptureModeEnabled = false)
		{
			var parentPanel = new PointerElement("1", softCaptureModeEnabled, hardCaptureModeEnabled);
			var childPanel = new PointerElement("2", softCaptureModeEnabled, hardCaptureModeEnabled);
			var dummyControl = new PointerElement("3", softCaptureModeEnabled, hardCaptureModeEnabled);
			parentPanel.Children.Add(childPanel);
			childPanel.Children.Add(dummyControl);

			root.Children.Add(parentPanel);
			root.Layout(int2(200));

			return new PointerSetupEntity(parentPanel, childPanel, dummyControl);
		}
	}
}
