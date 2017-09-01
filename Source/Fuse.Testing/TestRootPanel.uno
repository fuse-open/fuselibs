using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.UX;

using OpenGL;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;
using Fuse.Input;
using Fuse.Internal;
using Fuse.Scripting;
using Fuse.Triggers;

/* 
	This file is based on a copy of FuseTest's equivalent file, but with a minimal
	public API surface. This file implements the public test API required by ux:Test.
*/

namespace Fuse.Testing
{
	class TestRootViewport : RootViewport, IRenderViewport
	{
		extern(!Android && !iOS)
		public TestRootViewport(Uno.Platform.Window window, float pixelsPerPoint = 0)
			: base(window, pixelsPerPoint)
		{
			OverrideSize( float2(100), pixelsPerPoint, pixelsPerPoint );
		}

		extern(Android || iOS)
		public TestRootViewport(Uno.Platform.Window window, float pixelsPerPoint = 0)
		{
			OverrideSize( float2(100), pixelsPerPoint, pixelsPerPoint );
		}

		internal void Resize(float2 size)
		{
			OverrideSize(size, PixelsPerPoint, PixelsPerOSPoint);
			OnResized(null,null);
		}
	}

	/** Bootstrapper for ux:Test

		This class does not serve any general-purpose purpose, and
		shouldn't be used by applications.

		@advanced
		@experimental
	*/
	[UXTestBootstrapperFor("Fuse.Node")]
	public class TestRootPanel : Panel
	{
		TestRootViewport _rootViewport;
		
		internal TestRootViewport RootViewport { get { return _rootViewport; } }
		
		public TestRootPanel()
		{
			this.SnapToPixels = false;

			_rootViewport = new TestRootViewport(Uno.Application.Current.Window, 1);
			_rootViewport.Children.Add(this);
			Time.Init(0);
		}

		List<Diagnostic> _errors = new List<Diagnostic>();

		TestFailedException FindTestFailedException(Exception e)
		{
			var testFailedException = e as TestFailedException;
			if (testFailedException != null)
				return testFailedException;

			var aggregateException = e as AggregateException;
			if (aggregateException != null)
			{
				foreach (var innerException in aggregateException.InnerExceptions)
				{
					testFailedException = FindTestFailedException(innerException);
					if (testFailedException != null)
						return testFailedException;
				}
			}

			var wrapException = e as WrapException;
			if (wrapException != null)
				return FindTestFailedException(wrapException.InnerException);

			return null;
		}

		/** This entry point is required for this class to be used as a [UXTestBootstrapper] */
		public void RunTest()
		{
			var guard = new TestRootSingletonsGuard(this);

			try
			{
				Fuse.Diagnostics.DiagnosticReported += OnDiagnostic;

				_rootViewport.Resize( int2(800, 600) );
				PerformLayout( int2(800, 600) );

				try
				{
					StepFrameJS();
				}
				catch (Exception e)
				{
					var testFailedException = FindTestFailedException(e);
					if (testFailedException != null)
						Assert.Fail(testFailedException.Message);
					else
						throw;
				}
			}
			finally
			{
				Fuse.Diagnostics.DiagnosticReported -= OnDiagnostic;
			}

			foreach (var e in _errors)
			{
				Assert.Fail(e.ToString());
			}

			guard.Dispose();
		}

		void OnDiagnostic(Diagnostic d)
		{
			if (d.UnoType == Uno.Diagnostics.DebugMessageType.Error)
			{
				_errors.Add(d);
				
			}
		}

		enum StepFlags
		{
			None = 0,
			WaitJS = 1 << 0,
			IncrementFrame = 1 << 1,
		}
		
		/**
			Indicates any deferred actions should be pumped. Code that should work without 
			a new frame should call this instead of `IncrementFrame` to help ensure the 
			frame updating code is not used inappropriately. This limits itself to just processing
			the pending deferred messages in the current update stage.
		*/
		internal void PumpDeferred()
		{
			UpdateManager.TestProcessCurrentDeferredActions();
		}
		
		/**
			Does a single step of the elapsedTime. This is used when you need to tightly control
			the step time, or simulate a frame drop. Otherwise if you have  large time consider
			using `StepFrame` instead.
		*/
		internal void IncrementFrame(float elapsedTime = -1) 
		{
			IncrementFrameImpl(elapsedTime, StepFlags.IncrementFrame);
		}

		float _frameIncrement = 1/60f;
		float StepIncrement { get { return _frameIncrement; } }
			
		void IncrementFrameImpl(float elapsedTime = -1, 
			StepFlags flags = StepFlags.IncrementFrame)
		{
			if (elapsedTime < 0)
				elapsedTime = _frameIncrement;
				
			if (flags.HasFlag(StepFlags.WaitJS))
			{
				var w = Fuse.Reactive.JavaScript.Worker;
				if (w != null)
					w.WaitIdle();
			}
				
			Time.Set( Time.FrameTime + elapsedTime );
			UpdateManager.Update();
			if (flags.HasFlag(StepFlags.IncrementFrame))
				UpdateManager.IncreaseFrameIndex();
		}
		
		/**
			If something being tested uses `PerformNextFrame` then you'll typically need to IncrementFrame
			twice. The first call completes the current frame (when the posting occurs), and the next 
			completes the following frame (when the action is posted).
			This function makes this expectation clearer.
		*/
		internal void CompleteNextFrame()
		{
			IncrementFrame();
			IncrementFrame();
		}
		
		/**
			Steps at a reasonable frame rate to reach the `elapsedTime`.
		*/
		internal void StepFrame(float elapsedTime = -1)
		{
			if (elapsedTime < 0)
				elapsedTime = _frameIncrement;
				
			var e = 0f;
			const float zeroTolerance = 1e-05f;
			while (e < (elapsedTime - zeroTolerance))
			{
				var s = Math.Min( _frameIncrement, elapsedTime - e );
				IncrementFrame(s);
				e += s;
			}
		}
		
		/**
			Steps frames until the JS action list in the Dispatch manages to synchronize. Note
			in IncrementFrame we wait for JS processing to be done via `ThreadWorker.WaitIdle`,
			that simulates that the JS doesn't take long to execute. Here we intentionally don't
			force the Dispatcher to lock/process since it will naturally miss a frame -- we'd like
			the tests to sometimes miss frames as well.
		*/
		internal void StepFrameJS()
		{
			var fence = Fuse.Reactive.JavaScript.Worker.PostFence();
			var loop = true;
			while(loop)
			{
				loop = !fence.IsSignaled;
				IncrementFrameImpl(_frameIncrement, StepFlags.WaitJS | StepFlags.IncrementFrame);
			}
		}
		
		/**
			Steps frames until the Deferred actions are all cleared. Guaranteed to step at least one frame.
		*/
		internal void StepFrameDeferred()
		{
			while(true)
			{
				IncrementFrame();
				if (!TestDeferredManager.HasPending)
					break;
			}
		}

		internal void UpdateAnimators()
		{
			UpdateManager.Update();
		}

		internal void PointerPress(float2 windowPoint)
		{
			Fuse.Input.Pointer.RaisePressed(this, CreatePointerEvent(windowPoint));
			StepFrame();
		}
		
		internal void PointerMove(float2 windowPoint)
		{
			Fuse.Input.Pointer.RaiseMoved(this, CreatePointerEvent(windowPoint));
			StepFrame();
		}
		
		internal void PointerSlide(float2 from, float2 to, float speed)
		{
			var len = Vector.Length(to - from);
			var unit = Vector.Normalize(to - from);
			
			var at = 0f;
			while( at < len )
			{
				PointerMove(from + unit * at);
				at = Math.Min(len, at + _frameIncrement * speed);
			}
		}
		
		internal void PointerSwipe(float2 from, float2 to, float speed = 500)
		{
			var len = Vector.Length(to - from);
			var unit = Vector.Normalize(to - from);
			
			PointerPress(from);
			var at = _frameIncrement * speed;
			while( at < len )
			{
				PointerMove(from + unit * at);
				at = Math.Min(len, at + _frameIncrement * speed);
			}
			PointerRelease(to);
		}
		
		internal void PointerRelease(float2 windowPoint)
		{
			Fuse.Input.Pointer.RaiseReleased(this, CreatePointerEvent(windowPoint));
			StepFrame();
		}
		
		PointerEventData CreatePointerEvent(float2 windowPoint)
		{
			var ped = new PointerEventData
				{
					PointIndex = 1,
					WindowPoint = windowPoint,
					WheelDelta = float2(0),
					WheelDeltaMode = Uno.Platform.WheelDeltaMode.DeltaPixel,
					IsPrimary = true,
					PointerType = Uno.Platform.PointerType.Touch,
					Timestamp = Time.FrameTime,
				};
			return ped;
		}
		
		/**
			The UX compiler genertes instantiations of all UXGlobalModule's in the App InitializeUX.
			This does not happen for test cases, so you must explicitly say which modules you want.
			This function abstracts that concept rather than tests just instatiating them directly.
		*/
		static internal void RequireModule<T>() where T : new()
		{
			if (_modules == null)
				_modules = new List<object>();
				
			for (int i=0; i < _modules.Count; ++i)
			{
				if (_modules[i] is T)
					return;
			}
			
			_modules.Add( new T() );
		}
		static List<object> _modules;
	}

	/**	
		Global singletons are not set by default during testing. This is to help discourage such references from fuselibs itself. This guard sets up those references for tests where it is unavoidable.
	*/
	class TestRootSingletonsGuard : IDisposable
	{
		internal TestRootSingletonsGuard(TestRootPanel trp)
		{
			AppBase.TestSetRootViewport( trp.RootViewport );
		}
		
		public void Dispose()
		{
			AppBase.TestSetRootViewport( null );
		}
	}
}
