using Uno;
using Uno.Graphics;
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
				OverdrawHaxxorz.StartFrame();

				Internal.DrawManager.PrepareDraw(_dc);

				EnsureSortedZOrder();

				for (int i = 0; i < ZOrder.Count; i++)
					ZOrder[i].Draw(_dc);

				AppBase.Current.DrawSelection(_dc);

				// Fade out app by drawing a semi-transparent rect on top of it
				draw
				{
					float2[] Vertices: new[]
					{
						float2(0, 0), float2(0, 1), float2(1, 1),
						float2(0, 0), float2(1, 1), float2(1, 0)
					};

					float2 Coord: vertex_attrib(Vertices);

					ClipPosition: float4(Coord * 2 - 1, 0, 1);

					PixelColor: float4(0, 0, 0, 0.5f);

					CullFace : PolygonFace.None;
					DepthTestEnabled: false;

					BlendEnabled: true;
					BlendSrcRgb: BlendOperand.SrcAlpha;
					BlendDstRgb: BlendOperand.OneMinusSrcAlpha;

					BlendSrcAlpha: BlendOperand.SrcAlpha;
					BlendDstAlpha: BlendOperand.OneMinusSrcAlpha;
				};

				foreach (var r in OverdrawHaxxorz.DrawRects)
				{
					debug_log "Get rekt: " + r;

					draw
					{
						float2[] Vertices: new[]
						{
							float2(0, 0), float2(0, 1), float2(1, 1),
							float2(0, 0), float2(1, 1), float2(1, 0)
						};

						float2 Coord: vertex_attrib(Vertices);

						ClipPosition: float4(r.Position + Coord * r.Size, 0, 1);

						PixelColor: float4(1, 0, 0, 0.2f);

						CullFace : PolygonFace.None;
						DepthTestEnabled: false;

						BlendEnabled: true;
						BlendSrcRgb: BlendOperand.SrcAlpha;
						BlendDstRgb: BlendOperand.One;

						BlendSrcAlpha: BlendOperand.SrcAlpha;
						BlendDstAlpha: BlendOperand.One;
					};
				}
				
				Internal.DrawManager.EndDraw(_dc);

				OverdrawHaxxorz.EndFrame();
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
