using Uno;
using Fuse.Input;
using Fuse.Nodes;

namespace Fuse.Desktop
{
	extern (!MOBILE) class DesktopRootViewport: RootViewport, IRenderViewport
	{
		DrawContext _dc;

		public DesktopRootViewport(Uno.Platform.Window window): base(window)
		{
			Uno.Platform.EventSources.MouseSource.PointerPressed += OnPointerPressed;
			Uno.Platform.EventSources.MouseSource.PointerReleased += OnPointerReleased;
			Uno.Platform.EventSources.MouseSource.PointerMoved += OnPointerMoved;
			Uno.Platform.EventSources.MouseSource.PointerWheelChanged += OnPointerWheelChanged;
			Uno.Platform.EventSources.MouseSource.PointerLeft += OnPointerLeft;

			Uno.Platform.EventSources.HardwareKeys.KeyDown += KeyboardBootstrapper.OnKeyPressed;
			Uno.Platform.EventSources.HardwareKeys.KeyUp += KeyboardBootstrapper.OnKeyReleased;
			Uno.Platform.EventSources.TextSource.TextInput += KeyboardBootstrapper.OnTextInput;

			_dc = new DrawContext(this);
		}

		PointerEventData TranslatePointerEvent(Uno.Platform.PointerEventArgs args)
		{
			return new PointerEventData
			{
				PointIndex = args.FingerId,
				WindowPoint = args.Position * PixelsPerOSPoint / PixelsPerPoint,
				WheelDelta = args.WheelDelta,
				WheelDeltaMode = args.WheelDeltaMode,
				IsPrimary = args.IsPrimary,
				PointerType = args.PointerType,
				Timestamp = Uno.Diagnostics.Clock.GetSeconds() - Time.FrameTimeBase,
			};
		}

		bool _dirty = true;
		internal bool IsDirty { get { return _dirty; }}

		// TODO: this should not be part of the RootViewport class
		// Instead, RootGraphicsViewport should create a proper native graphicsview
		// and get ticks from there
		internal void Draw()
		{
			_dirty = false;

			try
			{
				Internal.DrawManager.PrepareDraw(_dc);

				if defined(FUSELIBS_DEBUG_DRAW_RECTS)
					DrawRectVisualizer.StartFrame(_dc.RenderTarget);


				var zOrder = GetCachedZOrder();
				for (int i = 0; i < zOrder.Length; i++)
					zOrder[i].Draw(_dc);

				if defined(FUSELIBS_DEBUG_DRAW_RECTS)
					DrawRectVisualizer.EndFrameAndVisualize(_dc);

				Internal.DrawManager.EndDraw(_dc);
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		protected override void OnInvalidateVisual()
		{
			base.OnInvalidateVisual();
			_dirty = true;
		}

		void OnPointerPressed(object sender, Uno.Platform.PointerEventArgs args)
		{
			try
			{
				args.Handled = Pointer.RaisePressed(this, TranslatePointerEvent(args));
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		void OnPointerReleased(object sender, Uno.Platform.PointerEventArgs args)
		{
			try
			{
				args.Handled = Pointer.RaiseReleased(this, TranslatePointerEvent(args));
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		void OnPointerMoved(object sender, Uno.Platform.PointerEventArgs args)
		{
			try
			{
				args.Handled = Pointer.RaiseMoved(this, TranslatePointerEvent(args));
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		void OnPointerWheelChanged(object sender, Uno.Platform.PointerEventArgs args)
		{
			try
			{
				args.Handled = Pointer.RaiseWheelMoved(this, TranslatePointerEvent(args));
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		void OnPointerLeft(object sender, Uno.Platform.PointerEventArgs args)
		{
			try
			{
				Pointer.RaiseLeft(this, TranslatePointerEvent(args));	
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}


	}
}
