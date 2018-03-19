using Uno;
using Uno.Collections;

using Fuse;
using Fuse.Controls;
using Fuse.Input;
using Fuse.Internal;
using Fuse.Nodes;

namespace FuseTest
{
	 /* TODO: Missing bootstrapper */
	public class TestRootViewport : RootViewport, IRenderViewport
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

		public void Resize(float2 size)
		{
			OverrideSize(size, PixelsPerPoint, PixelsPerOSPoint);
			OnResized(null,null);
		}
	}

	public class TestRootPanel : Panel, IDisposable
	{
		TestRootViewport _rootViewport;
		
		public TestRootViewport RootViewport { get { return _rootViewport; } }
		
		public TestRootPanel(bool infiniteMax = false, float pixelsPerPoint = 1)
		{
			this.InfiniteMax = infiniteMax;
			this.SnapToPixels = false;

			_rootViewport = new TestRootViewport(Uno.Application.Current.Window, pixelsPerPoint);
			_rootViewport.Children.Add(this);
			Time.Init(0);
		}

		void IDisposable.Dispose()
		{
			Pointer.ClearPointersDown();

			// dispose _rootViewport before cleaning low memory, to
			// make sure ImageSources etc are unpinned first
			(_rootViewport as IDisposable).Dispose();

			//force things to clean (LowMemory should do most items)
			CleanLowMemory();
			
			//restore margins to defaults
			if( !defined(iOS||Android))
			{
				Fuse.Platform.SystemUI.SetMargins( float4(0), float4(0), float4(0) );
			}
		}
		
		public void CleanLowMemory()
		{
			Fuse.Resources.DisposalManager.Clean(Fuse.Resources.DisposalRequest.LowMemory);
		}

		[Flags]
		public enum CreateFlags
		{
			None = 0,
			NoIncrement = 1 << 0,
		}
		
		/**
			Call this version if the layout size is important in the test.
		*/
		static public TestRootPanel CreateWithChild(Node child, int2 layoutSize,
			CreateFlags flags = CreateFlags.None)
		{
			return CreateWithChildImpl(child, layoutSize, flags, 1);
		}
		
		static TestRootPanel CreateWithChildImpl(Node child, int2 layoutSize,
			CreateFlags flags, int density)
		{
			var root = new TestRootPanel(false, density);
			root.Children.Add(child);
			root.Layout(layoutSize);
			if (!flags.HasFlag(CreateFlags.NoIncrement))
				root.IncrementFrame();
			return root;
		}

		static public TestRootPanel CreateWithChildDensity(Node child, int2 layoutSize, int density)
		{
			return CreateWithChildImpl(child, layoutSize, CreateFlags.None, density);
		}
		
		/**
			Call this version if layout size is not important, but don't test anything where it is
			important then!
		*/
		static public TestRootPanel CreateWithChild(Node child,
			CreateFlags flags = CreateFlags.None)
		{
			return CreateWithChildImpl(child, int2(800,600), flags, 1);
		}
		
		public new void Layout( float2 clientSizeInPoint )
		{
			_rootViewport.Resize(clientSizeInPoint);
			PerformLayout( clientSizeInPoint );
		}

		/**
			Sets the layout size but does not perform layout. A call to IncrementFrame will invoke
			the standard layout handling.
		*/
		public void SetLayoutSize( float2 clientSizeInPoint )
		{
			_rootViewport.Resize(clientSizeInPoint);
		}
		
		public new void Layout( int2 cp ) { Layout( float2(cp.X,cp.Y) ); }

		//usually called in next frame in live app, layout phase
		public void UpdateLayout()
		{
			Layout( _rootViewport.Size );
		}

		public float2 SnapToPixelsPos(float2 p)
		{
			return Math.Floor(p * this.AbsoluteZoom + 0.5f) / this.AbsoluteZoom;
		}

		public float SnapToPixelsPos(float p)
		{
			return Math.Floor(p * this.AbsoluteZoom + 0.5f) / this.AbsoluteZoom;
		}

		public float2 SnapToPixelsSize(float2 p)
		{
			return Math.Ceil(p * this.AbsoluteZoom) / this.AbsoluteZoom;
		}

		public float SnapToPixelsSize(float p)
		{
			return Math.Ceil(p * this.AbsoluteZoom) / this.AbsoluteZoom;
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
		public void PumpDeferred()
		{
			UpdateManager.TestProcessCurrentDeferredActions();
		}
		
		/**
			Does a single step of the elapsedTime. This is used when you need to tightly control
			the step time, or simulate a frame drop. Otherwise if you have  large time consider
			using `StepFrame` instead.
		*/
		public void IncrementFrame(float elapsedTime = -1) 
		{
			IncrementFrameImpl(elapsedTime, StepFlags.IncrementFrame);
		}
			
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
		public void CompleteNextFrame()
		{
			IncrementFrame();
			IncrementFrame();
		}
		
		static float _frameIncrement = 1/60f;
		public float StepIncrement { get { return _frameIncrement; } }
		
		DrawContext _dc;
		/**
			Performs a draw call on the root. It's undefined to what GL context this draws and whether it actually
			does any GL operations.
		*/
		public void TestDraw()
		{
			if (_dc == null)
				_dc = new DrawContext(_rootViewport);
			
			DrawManager.PrepareDraw(_dc);
			
			//at the moment this is the quickest way to fake the context, by creating a real one. Otherwise
			//we need to make `DrawContext` mockable and replace it in this test -- though something would still
			//need to make `draw` statements work.
			var fb = FramebufferPool.Lock( (int2)_rootViewport.PixelSize, Uno.Graphics.Format.RGBA8888, true);
			_dc.PushRenderTarget(fb);

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.StartFrame(_dc.RenderTarget);
			
			_rootViewport.Draw(_dc);
			
			_dc.PopRenderTarget();
			FramebufferPool.Release(fb);

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.EndFrameAndVisualize(_dc);
			
			DrawManager.EndDraw(_dc);
		}

		/**
			Captures the drawing output to be inspected.
		*/
		public TestFramebuffer CaptureDraw()
		{
			if (_dc == null)
				_dc = new DrawContext(_rootViewport);

			DrawManager.PrepareDraw(_dc);
			
			var ret = new TestFramebuffer((int2)_rootViewport.PixelSize);
			_dc.PushRenderTarget(ret.Framebuffer);
			_dc.Clear(float4(0),1);

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.StartFrame(_dc.RenderTarget);

			_rootViewport.Draw(_dc);

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.EndFrameAndVisualize(_dc);

			_dc.PopRenderTarget();

			DrawManager.EndDraw(_dc);

			return ret;
		}

		/**
			Steps at a reasonable frame rate to reach the `elapsedTime`.
		*/
		public void StepFrame(float elapsedTime = -1)
		{
			if (elapsedTime < 0)
				elapsedTime = _frameIncrement;

			const float zeroTolerance = 1e-05f;

			var e = 0f;
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
			
			If an `elapsedTime` is specified it will wait this additional amount of time (simulate
			the steps). If the synchronization exceeds the total time it will throw an exception.
			This is currently only useful if elapsedTime is sufficiently large to accomodate several
			_frameIncrement steps.
		*/
		public void StepFrameJS(float elapsedTime = 0)
		{
			var w = Fuse.Reactive.JavaScript.Worker;
			if (w == null)
				throw new Exception("Calling stepFrameJS though there is no JavaScript worker" );
				
			var fence = Fuse.Reactive.JavaScript.Worker.PostFence();
			var loop = true;
			var e = 0f;
			while(loop)
			{
				loop = !fence.IsSignaled;
				IncrementFrameImpl(_frameIncrement, StepFlags.WaitJS | StepFlags.IncrementFrame);
				e += _frameIncrement;
			}
			
			if (elapsedTime > 0)
			{
				if (e >= elapsedTime)
					throw new Exception( "Unable to satisfy time constraint in stepping" );
				StepFrame(elapsedTime - e);
			}
		}
		
		/**
			If the test code involves multiple JavaScript elements that need to communicate between
			each other, a single StepFrameJS may not be enough. This happens when an Observable in
			one is connected to an Observable in another. The single StepFrameJS only takes care of
			a single JS propagation, not the followup to the other element.
			
			This calls StepFrameJS multiple times to be correct in those situations.  The number should
			be the number of modules that need to be traversed. Don't just increase the number
			until it works.
		*/
		public void MultiStepFrameJS(int count)
		{
			for (int i=0; i < count; ++i)
				StepFrameJS();
		}
		
		public void MultiStepFrame(int count)
		{
			for (int i=0; i < count; ++i)
				StepFrame();
		}
		
		/**
			Steps frames until the Deferred actions are all cleared. Guaranteed to step at least one frame.
		*/
		public void StepFrameDeferred()
		{
			while(true)
			{
				IncrementFrame();
				if (!TestDeferredManager.HasPending)
					break;
			}
		}

		public void UpdateAnimators()
		{
			UpdateManager.Update();
		}

		bool InfiniteMax = false;

		float2 _pointerWindowPoint;
		public void PointerPress(float2 windowPoint, int pointIndex = 0)
		{
			_pointerWindowPoint = windowPoint;
			Fuse.Input.Pointer.RaisePressed(this, CreatePointerEvent(windowPoint, pointIndex));
			StepFrame();
		}
		
		public void PointerMove(float2 windowPoint, int pointIndex = 0)
		{
			_pointerWindowPoint = windowPoint;
			Fuse.Input.Pointer.RaiseMoved(this, CreatePointerEvent(windowPoint, pointIndex));
			StepFrame();
		}
		
		public void PointerSlide(float2 from, float2 to, float speed)
		{
			var len = Vector.Length(to - from);
			var unit = Vector.Normalize(to - from);
			var step = _frameIncrement * speed;
			int steps = (int)Math.Ceil( len / step );
			
			for (int i=0; i <= steps; ++i)
				PointerMove(from + unit * Math.Min(len, i * step));
		}
		
		public void PointerSlideRel(float2 offset, float speed = 500)
		{
			PointerSlide( _pointerWindowPoint, _pointerWindowPoint + offset, speed  );
		}
		
		public void PointerSwipe(float2 from, float2 to, float speed = 500)
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
		
		public void PointerRelease(float2 windowPoint, int pointIndex = 0)
		{
			Fuse.Input.Pointer.RaiseReleased(this, CreatePointerEvent(windowPoint, pointIndex));
			StepFrame();
		}
		
		public void PointerRelease()
		{
			PointerRelease(_pointerWindowPoint);
		}
		
		PointerEventData CreatePointerEvent(float2 windowPoint, int pointIndex = 0)
		{
			var ped = new PointerEventData
				{
					PointIndex = pointIndex,
					WindowPoint = windowPoint,
					WheelDelta = float2(0),
					WheelDeltaMode = Uno.Platform.WheelDeltaMode.DeltaPixel,
					IsPrimary = pointIndex == 0,
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
		static public void RequireModule<T>() where T : new()
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
		
		extern(!iOS && !Android) public void SetSafeMargins( float4 margins ) 
		{
			Fuse.Platform.SystemUI.SetMargins( float4(0), margins, margins );
		}
	}

	/**	
		Global singletons are not set by default during testing. This is to help discourage such references from fuselibs itself. This guard sets up those references for tests where it is unavoidable.
	*/
	public class TestRootSingletonsGuard : IDisposable
	{
		public TestRootSingletonsGuard(TestRootPanel trp)
		{
			AppBase.TestSetRootViewport( trp.RootViewport );
		}
		
		void IDisposable.Dispose()
		{
			AppBase.TestSetRootViewport( null );
		}
	}
}
