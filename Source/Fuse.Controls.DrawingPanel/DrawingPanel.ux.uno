using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Fuse.Input;
using Fuse.Scripting;
using Fuse.Controls.Internal;

namespace Fuse.Controls
{
	internal interface ICanvas : IDisposable
	{
		void Clear(float4 color);
		void Draw(Line line);
		void Draw(IList<Line> lines);
		void Draw(Internal.Circle circle);
		void Draw(IList<Internal.Circle> circles);
		void Draw(Stroke stroke);
	}

	internal interface ICanvasFactory
	{
		ICanvas Create(float2 size, float pixelsPerPoint);
	}

	internal interface ICanvasContext
	{
		void Draw(ICanvas canvas);
	}

	internal interface ICanvasViewHost
	{
		void OnDraw(ICanvasContext cc);
		float PixelsPerPoint { get; }
	}

	internal class DrawingInfo
	{
		public readonly float2 Size;
		public readonly float PixelsPerPoint;
		public readonly Stroke[] Strokes;

		public DrawingInfo(
			float2 size,
			float pixelsPerPoint,
			Stroke[] strokes)
		{
			Size = size;
			PixelsPerPoint = pixelsPerPoint;
			Strokes = strokes;
		}
	}

	/**
		A Panel that can be used to draw lines using your finger. As the DrawingPanel is native only, it must be contained in a @NativeViewHost.

		To use this control, You need to add a reference to `Fuse.Controls.DrawingPanel` and `Fuse.ImageTools` on your .unoproj file

		### Example:

		```XML
		<App Background="White">
			<JavaScript>
				var drawing = DrawingPanel

				module.exports = {
					undoClicked: function(args) {
						drawing.undo();
					},
					redoClicked: function(args) {
						drawing.redo();
					},
					clearClicked: function(args) {
						drawing.clear();
					},
					clearHistoryClicked: function(args) {
						drawing.clearHistory();
					}
				}
			</JavaScript>
			<ClientPanel>
				<DockPanel>
					<NativeViewHost>
						<DrawingPanel ux:Name="DrawingPanel" />
					</NativeViewHost>
					<StackPanel Height="70" ItemSpacing="10" Alignment="Center" Padding="10" Dock="Bottom" Orientation="Horizontal">
						<Button Text="Undo" Clicked="{undoClicked}" />
						<Button Text="Redo" Clicked="{redoClicked}"/>
						<Button Text="Clear Canvas" Clicked="{clearClicked}"/>
						<Button Text="Clear History" Clicked="{clearHistoryClicked}"/>
					</StackPanel>
				</DockPanel>
			</ClientPanel>
		</App>
		```
	*/
	public class DrawingPanelBase : Panel, ICanvasViewHost
	{
		static DrawingPanelBase()
		{
			ScriptClass.Register(typeof(DrawingPanelBase),
				new ScriptMethod<DrawingPanelBase>("undo", undo),
				new ScriptMethod<DrawingPanelBase>("redo", redo),
				new ScriptMethod<DrawingPanelBase>("clear", clear),
				new ScriptMethod<DrawingPanelBase>("clearHistory", clearHistory),
				new ScriptPromise<DrawingPanelBase,DrawingInfo,object>("getDrawingInfo", ExecutionThread.MainThread, getDrawingInfo, ConvertDrawingInfo));
		}

		static object ConvertDrawingInfo(Context c, DrawingInfo drawingInfo)
		{
			return c.Unwrap(drawingInfo);
		}

		static void undo(DrawingPanelBase self) { self.Undo(); }

		static void redo(DrawingPanelBase self) { self.Redo(); }

		static void clearHistory(DrawingPanelBase self) { self.ClearHistory(); }

		static void clear(DrawingPanelBase self) { self.ClearCanvas(); }

		static Future<DrawingInfo> getDrawingInfo(Context context, DrawingPanelBase self, object[] args) { return self.GetDrawingInfo(); }

		Future<DrawingInfo> GetDrawingInfo()
		{
			var p = new Promise<DrawingInfo>();
			if (!IsRootingCompleted)
				p.Reject(new Exception(this + " is not rooted!"));
			else
				p.Resolve(new DrawingInfo(ActualSize, Viewport.PixelsPerPoint, _history.ToArray()));
			return p;
		}

		float _strokeWidth = 10.0f;
		public float StrokeWidth
		{
			get { return _strokeWidth; }
			set { _strokeWidth = value; }
		}

		float4 _strokeColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
		public float4 StrokeColor
		{
			get { return _strokeColor; }
			set { _strokeColor = value; }
		}

		ICanvas _canvas;
		ICanvas Canvas { get { return _canvas ?? DummyCanvas.Instance; } }

		protected override void OnRooted()
		{
			base.OnRooted();
			Pointer.AddHandlers(this, OnPointerPressed, OnPointerMoved, OnPointerReleased);
			Placed += OnPlaced;
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			Pointer.RemoveHandlers(this, OnPointerPressed, OnPointerMoved, OnPointerReleased);
			Placed -= OnPlaced;
			if (_canvas != null)
			{
				_canvas.Dispose();
				_canvas = null;
			}
		}

		void InvalidateCanvas()
		{
			if (_canvas != null)
			{
				_canvas.Dispose();
				_canvas = null;
			}
			if (ActualSize.X <= 0 || ActualSize.Y <= 0)
				return;

			var cf = CanvasFactory;
			if (cf != null)
			{
				_canvas = cf.Create(ActualSize, Viewport.PixelsPerPoint);
			}
			ClearAndDraw();
		}

		ICanvasFactory CanvasFactory
		{
			get { return ViewHandle as ICanvasFactory; }
		}

		void OnPlaced(object sender, PlacedArgs args)
		{
			InvalidateCanvas();
		}

		float2 _previousCoord = float2(0.0f);

		int _down = -1;
		void OnPointerPressed(object sender, PointerPressedArgs args)
		{
			if (_down != -1)
				return;

			if (Focus.IsWithin(this))
				args.TryHardCapture(this, OnLostCapture);
			else
				args.TrySoftCapture(this, OnLostCapture);

			_down = args.PointIndex;
			_history.Add(new Stroke());
			_previousCoord = WindowToLocal(args.WindowPoint);
			DrawCircle(_previousCoord);

			InvalidateVisual();
		}

		const float MinDistanceSquared = 5 * 5;

		List<Stroke> _undoHistory = new List<Stroke>();
		List<Stroke> _history = new List<Stroke>();
		void OnPointerMoved(object sender, PointerMovedArgs args)
		{
			if (_down != args.PointIndex)
				return;

			var currentCoord = WindowToLocal(args.WindowPoint);
			if (Vector.LengthSquared(_previousCoord - currentCoord) < MinDistanceSquared)
				return;

			DrawLine(_previousCoord, currentCoord);
			_previousCoord = currentCoord;
			InvalidateVisual();

			if (args.IsHardCapturedTo(this))
			{
				args.IsHandled = true;
			}
		}

		void OnPointerReleased(object sender, PointerReleasedArgs args)
		{
			if (_down != args.PointIndex)
				return;

			if (args.IsHardCapturedTo(this))
			{
				args.ReleaseCapture(this);
				args.IsHandled = true;
			}
			else if (args.IsSoftCapturedTo(this))
			{
				args.ReleaseCapture(this);
			}

			_down = -1;
		}

		void DrawLine(float2 from, float2 to)
		{
			var line = new Line(from, to, StrokeWidth, StrokeColor);
			_history.LastOrDefault().Lines.Add(line);
			Canvas.Draw(line);
		}

		void DrawCircle(float2 center)
		{
			var circle = new Internal.Circle(center, StrokeWidth * 0.5f, StrokeColor);
			_history.LastOrDefault().Circles.Add(circle);
			Canvas.Draw(circle);
		}

		void OnLostCapture()
		{
			_down = -1;
		}

		void ICanvasViewHost.OnDraw(ICanvasContext cc)
		{
			if (_canvas != null)
				cc.Draw(_canvas);
		}

		float ICanvasViewHost.PixelsPerPoint
		{
			get { return Viewport.PixelsPerPoint; }
		}

		public void Undo()
		{
			if (_history.Count == 0)
				return;

			_undoHistory.Add(_history[_history.Count - 1]);
			_history.RemoveAt(_history.Count - 1);
			ClearAndDraw();
		}

		public void Redo()
		{
			if (_undoHistory.Count == 0)
				return;

			var stroke = _undoHistory[_undoHistory.Count - 1];
			_undoHistory.RemoveAt(_undoHistory.Count - 1);
			_history.Add(stroke);
			Canvas.Draw(stroke);
			InvalidateVisual();
		}

		public void ClearHistory()
		{
			_undoHistory.Clear();
			_history.Clear();
			Canvas.Clear(float4(0.0f));
			InvalidateVisual();
		}

		public void ClearCanvas()
		{
			Canvas.Clear(float4(0.0f));
			InvalidateVisual();
		}

		void ClearAndDraw()
		{
			Canvas.Clear(float4(0.0f));
			foreach (var stroke in _history)
				Canvas.Draw(stroke);
			InvalidateVisual();
		}

		protected override VisualBounds HitTestLocalVisualBounds
		{
			get
			{
				var nb = base.HitTestLocalVisualBounds;
				nb = nb.AddRect( float2(0), ActualSize );
				return nb;
			}
		}

		protected override void OnHitTestLocalVisual(HitTestContext htc)
		{
			if (IsPointInside(htc.LocalPoint))
				htc.Hit(this);

			base.OnHitTestLocalVisual(htc);
		}

		protected override VisualBounds CalcRenderBounds()
		{
			var b = base.CalcRenderBounds();
			b = b.AddRect( float2(0), ActualSize );
			return b;
		}
	}

	internal class DummyCanvas : ICanvas, IDisposable
	{
		public static readonly ICanvas Instance = new DummyCanvas();
		void ICanvas.Clear(float4 color) {}
		void ICanvas.Draw(Line line) {}
		void ICanvas.Draw(IList<Line> lines) {}
		void ICanvas.Draw(Internal.Circle circle) {}
		void ICanvas.Draw(IList<Internal.Circle> circles) {}
		void ICanvas.Draw(Stroke stroke) {}
		void IDisposable.Dispose() {}
		DummyCanvas() {}
	}
}