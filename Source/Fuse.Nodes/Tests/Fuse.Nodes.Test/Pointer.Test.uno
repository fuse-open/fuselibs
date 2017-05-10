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
		private TestRootPanel _root;
		private List<string> _bubblingSequence;

		public FusePointerTest()
		{
			_root = new TestRootPanel();
			_bubblingSequence = new List<string>();

			Fuse.Input.Pointer.RaiseMoved(_root, GetZeroPointerEventData());
			Fuse.Input.Pointer.RaiseReleased(_root, GetDefaultPointerEventData());
		}

		[Test]
		public void BubblingSequence()
		{
			var setup = SetupEnvironment();

			Fuse.Input.Pointer.Pressed.AddHandler(setup.ParentPanel, PointerPressedHandler);
			Fuse.Input.Pointer.Pressed.AddHandler(setup.ChildPanel, PointerPressedHandler);
			Fuse.Input.Pointer.Pressed.AddHandler(setup.Control, PointerPressedHandler);

			Fuse.Input.Pointer.Released.AddHandler(setup.ParentPanel, PointerReleasedHandler);
			Fuse.Input.Pointer.Released.AddHandler(setup.ChildPanel, PointerReleasedHandler);
			Fuse.Input.Pointer.Released.AddHandler(setup.Control, PointerReleasedHandler);

			Fuse.Input.Pointer.RaisePressed(_root, GetDefaultPointerEventData());
            Assert.AreEqual(new string[] { "3", "2", "1" }, _bubblingSequence.ToArray());

			_bubblingSequence.Clear();
			Fuse.Input.Pointer.RaiseReleased(_root, GetDefaultPointerEventData());
            Assert.AreEqual(new string[] { "3", "2", "1" }, _bubblingSequence.ToArray());
		}

		[Test]
		public void SoftCapture()
		{
			var setup = SetupEnvironment(true);

			Fuse.Input.Pointer.RaisePressed(_root, GetDefaultPointerEventData());
			Assert.IsTrue(setup.ParentPanel.Captured);
			Assert.IsTrue(setup.ChildPanel.Captured);
			Assert.IsTrue(setup.Control.Captured);

			Fuse.Input.Pointer.RaiseReleased(_root, GetDefaultPointerEventData());
			Assert.IsFalse(setup.ParentPanel.Captured);
			Assert.IsFalse(setup.ChildPanel.Captured);
			Assert.IsFalse(setup.Control.Captured);
		}

		[Test]
		public void SoftCaptureParentNoCapture()
		{
			var setup = SetupEnvironment(true);
			setup.ChildPanel.SoftCaptureModeEnabled = false;

			Fuse.Input.Pointer.RaisePressed(_root, GetDefaultPointerEventData());
			Assert.IsTrue(setup.ParentPanel.Captured);
			Assert.IsFalse(setup.ChildPanel.Captured);
		}

		[Test]
		public void SoftCaptureOutsideOfControls()
		{
			var setup = SetupEnvironment(true);

			Fuse.Input.Pointer.RaisePressed(_root, GetOutsideOfControlsPointerEventData());
			Assert.IsFalse(setup.ParentPanel.Captured);
			Assert.IsFalse(setup.ChildPanel.Captured);
			Assert.IsFalse(setup.Control.Captured);
		}

		[Test]
		public void HardCapture()
		{
			var setup = SetupEnvironment(true, true);

			Fuse.Input.Pointer.RaisePressed(_root, GetDefaultPointerEventData());
			Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
			Assert.IsFalse(setup.ParentPanel.Captured);
			Assert.IsFalse(setup.ChildPanel.Captured);
			Assert.IsTrue(setup.Control.Captured);
		}

		[Test]
		public void HardCaptureControlNoCapture()
		{
			var setup = SetupEnvironment(true, true);
			setup.Control.HardCaptureModeEnabled = false;

			Fuse.Input.Pointer.RaisePressed(_root, GetDefaultPointerEventData());
			Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
			Assert.IsFalse(setup.ParentPanel.Captured);
			Assert.IsTrue(setup.ChildPanel.Captured);
			Assert.IsFalse(setup.Control.Captured);
		}

		[Test]
		[Ignore("https://github.com/fusetools/fuselibs/issues/229")]
		public void SoftCaptureForDisabledNode()
		{
			var setup = SetupEnvironment(true);

			Fuse.Input.Pointer.RaisePressed(_root, GetDefaultPointerEventData());
			setup.ChildPanel.IsEnabled = false;
			Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
			Assert.IsTrue(setup.ParentPanel.Captured);
			Assert.IsTrue(setup.ChildPanel.Captured);
			Assert.IsFalse(setup.Control.Captured);
		}

		[Test]
		[Ignore("https://github.com/fusetools/fuselibs/issues/229")]
		public void SoftCaptureForUnrootedNode()
		{
			var setup = SetupEnvironment(true);

			Fuse.Input.Pointer.RaisePressed(_root, GetDefaultPointerEventData());
			setup.ChildPanel.Children.Remove(setup.Control);
			Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
			Assert.IsTrue(setup.ParentPanel.Captured);
			Assert.IsTrue(setup.ChildPanel.Captured);
			Assert.IsFalse(setup.Control.Captured);
		}

		[Test]
		public void PointerEnterLeave()
		{
			var setup = SetupEnvironment();

			Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
			Assert.IsTrue(setup.ParentPanel.Entered);
			Assert.IsTrue(setup.ChildPanel.Entered);
			Assert.IsTrue(setup.Control.Entered);

			Fuse.Input.Pointer.RaiseMoved(_root, GetOutsideOfControlsPointerEventData());
			Assert.IsFalse(setup.ParentPanel.Entered);
			Assert.IsFalse(setup.ChildPanel.Entered);
			Assert.IsFalse(setup.Control.Entered);
		}

		[Test]
		public void PointerEnterLeaveOnRemove()
		{
			var setup = SetupEnvironment();

			Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
			setup.ChildPanel.Children.Remove(setup.Control);
			Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
			Assert.IsTrue(setup.ParentPanel.Entered);
			Assert.IsTrue(setup.ChildPanel.Entered);
			Assert.IsFalse(setup.Control.Entered);
		}

		[Test]
		public void PointerEnterLeaveOnDisabled()
		{
			var setup = SetupEnvironment();

			Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
			setup.Control.IsEnabled = false;
			Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
			Assert.IsTrue(setup.ParentPanel.Entered);
			Assert.IsTrue(setup.ChildPanel.Entered);
			Assert.IsFalse(setup.Control.Entered);
		}

		[Test]
		public void EventResponder()
		{
			IPointerEventResponder prevEventResponder = Pointer.EventResponder;
			try
			{
				var testPointerEventResponder = new TestPointerEventResponder();
				Pointer.EventResponder = testPointerEventResponder;

				Fuse.Input.Pointer.RaisePressed(_root, GetDefaultPointerEventData());
				Assert.AreEqual(1, testPointerEventResponder.PointerPressedArgs.Count);
				Assert.AreEqual(_root, testPointerEventResponder.PointerPressedArgs[0].Visual);

				Fuse.Input.Pointer.RaiseMoved(_root, GetDefaultPointerEventData());
				Assert.AreEqual(1, testPointerEventResponder.PointerMovedArgs.Count);
				Assert.AreEqual(_root, testPointerEventResponder.PointerMovedArgs[0].Visual);

				Fuse.Input.Pointer.RaiseReleased(_root, GetDefaultPointerEventData());
				Assert.AreEqual(1, testPointerEventResponder.PointerReleasedArgs.Count);
				Assert.AreEqual(_root, testPointerEventResponder.PointerReleasedArgs[0].Visual);

				Fuse.Input.Pointer.RaiseWheelMoved(_root, GetDefaultPointerEventData());
				Assert.AreEqual(1, testPointerEventResponder.PointerWheelMovedArgs.Count);
				Assert.AreEqual(_root, testPointerEventResponder.PointerWheelMovedArgs[0].Visual);
			}
			finally
			{
				Pointer.EventResponder = prevEventResponder;
			}
		}

		void PointerPressedHandler(object sender, PointerPressedArgs args)
		{
			_bubblingSequence.Add(((PointerElement)sender).Name);
		}

		void PointerReleasedHandler(object sender, PointerReleasedArgs args)
		{
			_bubblingSequence.Add(((PointerElement)sender).Name);
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

		PointerSetupEntity SetupEnvironment(bool softCaptureModeEnabled = false, bool hardCaptureModeEnabled = false)
		{
			var parentPanel = new PointerElement("1", softCaptureModeEnabled, hardCaptureModeEnabled);
			var childPanel = new PointerElement("2", softCaptureModeEnabled, hardCaptureModeEnabled);
			var dummyControl = new PointerElement("3", softCaptureModeEnabled, hardCaptureModeEnabled);
			parentPanel.Children.Add(childPanel);
			childPanel.Children.Add(dummyControl);

			_root.Children.Add(parentPanel);
            _root.Layout(int2(200));

            return new PointerSetupEntity(parentPanel, childPanel, dummyControl);
		}
	}
}
