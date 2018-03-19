using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Elements;
using Fuse.Drawing;
using Fuse.Controls.Native;
using Fuse.Nodes;

namespace Fuse.Controls
{
	internal class DefaultTreeRenderer : ITreeRenderer
	{
		public static readonly DefaultTreeRenderer Instance = new DefaultTreeRenderer();

		public void RootingStarted(Element e) { }

		public void Rooted(Element e)
		{
			if (e is Control)
			{
				var visual = InstantiateGraphicsAppearance(e);
				if (visual != null)
				{
					var c = (Control)e;
					c.GraphicsVisual = visual;
					c.Children.Add(visual);
				}
			}
		}

		public void Unrooted(Element e)
		{
			if (e is Control)
			{
				var c = (Control)e;
				var visual = c.GraphicsVisual;
				if (visual != null)
				{
					c.Children.Remove(visual);
					c.GraphicsVisual = null;
				}
			}
		}

		Visual InstantiateGraphicsAppearance(Element e)
		{
			var t = e.FindTemplate("GraphicsAppearance");
			return t != null ? t.New() as Visual : null;
		}

		public void TransformChanged(Element e) { }
		public void Placed(Element e) { }
		public void IsVisibleChanged(Element e, bool isVisible) {}
		public void IsEnabledChanged(Element e, bool isEnabled) {}
		public void OpacityChanged(Element e, float opacity) {}
		public void ClipToBoundsChanged(Element e, bool clipToBounds) {}
		public void BackgroundChanged(Element e, Brush background) {}
		public void ZOrderChanged(Element e, Visual[] zorder) {}
		public void HitTestModeChanged(Element e, bool enabled) {}
		public void RenderBoundsChanged(Element e) {}
		public bool Measure(Element e, LayoutParams lp, out float2 size) { size = float2(0.0f); return false; }

	}

	interface IProxyHost
	{
		float4x4 WorldTransformInverse { get; }
		void Insert(ViewHandle viewHandle);
		void Remove(ViewHandle viewHandle);
	}

	internal static class IProxyHostExtensions
	{
		public static IProxyHost FindProxyHost(this Visual visual)
		{
			if (visual == null)
				return null;

			var parent = visual.Parent;
			if (parent == null)
				return null;

			if (parent is IProxyHost && parent.Parent.VisualContext == VisualContext.Native)
				return parent as IProxyHost;
			else
				return parent.FindProxyHost();
		}
	}

	/** A native view that hosts graphics-rendered UI controls.

		GraphicsView is the counterpart to @NativeViewHost and allows you to add Fuse views to a NativeViewHost-scope.

			<App>
				<NativeViewHost>
				    <StackPanel>
				        <Button Text="I'm a Native button!" />
				        <GraphicsView>
				            <Button Text="I'm a graphics-button!" />
				        </GraphicsView>
				    </StackPanel>
				</NativeViewHost>
			</App>

		As with the NativeViewHost note that depth ordering will behave differently when mixing Native and Fuse views.
	*/
	public partial class GraphicsView: IViewport, IRenderViewport, ITreeRenderer, IProxyHost
	{
		public override VisualContext VisualContext
		{
			get { return VisualContext.Graphics; }
		}

		public override ITreeRenderer TreeRenderer
		{
			get { return this; }
		}

		ITreeRenderer BaseTreeRenderer
		{
			get { return base.TreeRenderer; }
		}

		ITreeRenderer GetTreeRenderer(Element e)
		{
			if (e == this &&
				e.Parent != null &&
				e.Parent.VisualContext == VisualContext.Native)
				return BaseTreeRenderer;
			else
				return DefaultTreeRenderer.Instance;
		}

		float4x4 IProxyHost.WorldTransformInverse
		{
			get { return WorldTransformInverse; }
		}

		void IProxyHost.Insert(ViewHandle viewHandle)
		{
			if defined(Android || iOS)
			{
				var vh = NativeView as IViewHost;
				if (vh != null)
					vh.Insert(viewHandle);
				else
					Fuse.Diagnostics.InternalError(this + " does not have a NativeView: IViewHost");
			}
		}

		void IProxyHost.Remove(ViewHandle viewHandle)
		{
			if defined(Android || iOS)
			{
				var vh = NativeView as IViewHost;
				if (vh != null)
					vh.Remove(viewHandle);
				else
					Fuse.Diagnostics.InternalError(this + " does not have a NativeView: IViewHost");
			}
		}

		void ITreeRenderer.RootingStarted(Element e) { GetTreeRenderer(e).RootingStarted(e); }

		void ITreeRenderer.Rooted(Element e) { GetTreeRenderer(e).Rooted(e); }

		void ITreeRenderer.Unrooted(Element e) { GetTreeRenderer(e).Unrooted(e); }

		void ITreeRenderer.BackgroundChanged(Element e, Brush background) { DefaultTreeRenderer.Instance.BackgroundChanged(e, background); }

		void ITreeRenderer.TransformChanged(Element e) { GetTreeRenderer(e).TransformChanged(e); }

		void ITreeRenderer.Placed(Element e) { GetTreeRenderer(e).Placed(e); }

		void ITreeRenderer.IsVisibleChanged(Element e, bool isVisible) { GetTreeRenderer(e).IsVisibleChanged(e, isVisible); }

		void ITreeRenderer.IsEnabledChanged(Element e, bool isEnabled) { GetTreeRenderer(e).IsEnabledChanged(e, isEnabled); }

		void ITreeRenderer.OpacityChanged(Element e, float opacity) { GetTreeRenderer(e).OpacityChanged(e, opacity); }

		void ITreeRenderer.ClipToBoundsChanged(Element e, bool clipToBounds) { GetTreeRenderer(e).ClipToBoundsChanged(e, clipToBounds); }

		void ITreeRenderer.HitTestModeChanged(Element e, bool enabled) { GetTreeRenderer(e).HitTestModeChanged(e, enabled); }

		void ITreeRenderer.RenderBoundsChanged(Element e) { GetTreeRenderer(e).RenderBoundsChanged(e); }

		void ITreeRenderer.ZOrderChanged(Element e, Visual[] zorder) { /*GetTreeRenderer(e).ZOrderChanged(e, zorder);*/ }

		bool ITreeRenderer.Measure(Element e, LayoutParams lp, out float2 size) { return GetTreeRenderer(e).Measure(e, lp, out size); }

		FrustumViewport _frustumViewport;
		OrthographicFrustum _frustum = new OrthographicFrustum();

		//allows using a different implementation when covering the full screen
		public bool IsFullScreen;

		DrawContext _dc;

		public GraphicsView()
		{
			InitializeUX();
			_frustumViewport = new FrustumViewport();
			_frustumViewport.Update(this, _frustum);
		}

		float4 _color = float4(0,0,0,0);
		/** The clear-color of the graphics view.

			For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).

			@default Black
		*/
		public float4 Color
		{
			get { return _color; }
			set
			{
				if (_color != value)
				{
					_color = value;
					InvalidateVisual();
				}
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			_dc = new DrawContext(this);
			if defined(Android)
			{
				Fuse.Platform.SystemUI.FrameChanged += OnResized;
				rotationHackRedrawCount = 5;
			}

			if defined(Android || iOS)
			{
				Fuse.Platform.Lifecycle.EnteringForeground += OnEnteringForeground;
				Fuse.Platform.Lifecycle.EnteringBackground += OnEnteringBackground;
			}
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			if defined(Android) Fuse.Platform.SystemUI.FrameChanged -= OnResized;
			_dc = null;

			if defined(Android || iOS)
			{
				Fuse.Platform.Lifecycle.EnteringForeground -= OnEnteringForeground;
				Fuse.Platform.Lifecycle.EnteringBackground -= OnEnteringBackground;
			}
		}

		public float PixelsPerPoint
		{
			get
			{
				if (Parent != null)
					return Parent.Viewport.PixelsPerPoint;
				else
				{
					// this only happens during testing
					if (AppBase.Current == null)
						return 1;

					return AppBase.Current.PixelsPerPoint;
				}
			}
		}

		[Obsolete]
		/** Deprecated use ActualSize instead. 2018-01-02 */
		public new float2 Size
		{
			get { return ActualSize; }
		}

		[Obsolete]
		/** Deprecated use ActualPixelSize instead. 2018-01-02 */
		public float2 PixelSize
		{
			get { return ActualPixelSize; }
		}
		public float2 ActualPixelSize
		{
			get { return ActualSize * PixelsPerPoint; }
		}

		bool _frameScheduled = false;
		protected override void OnInvalidateVisual()
		{
			base.OnInvalidateVisual();
			ScheduleFrame();
		}

		bool _inBackground = false;
		void OnEnteringForeground(Fuse.Platform.ApplicationState s)
		{
			rotationHackRedrawCount = 2;
			_inBackground = false;
			_frameScheduled = false;
			ScheduleFrame();
			UpdateManager.PerformNextFrame(InvalidateVisual);
		}

		void OnEnteringBackground(Fuse.Platform.ApplicationState s)
		{
			_inBackground = true;
		}

		int rotationHackRedrawCount = 0;
		void OnResized(object sender, EventArgs args)
		{
			rotationHackRedrawCount = 5;
		}

		void ScheduleFrame()
		{
			if (!_frameScheduled)
			{
				UpdateManager.AddOnceAction(DrawFrame, UpdateStage.Draw);
				_frameScheduled = true;
			}
		}

		// used on platforms with native graphics views
		void DrawFrame()
		{
			if (_inBackground || !IsRootingCompleted)
				return;

			_frameScheduled = false;

			var gv = NativeView as IGraphicsView;
			if (gv != null)
			{
				_frustum.LocalFromWorld = WorldTransformInverse;
				_frustumViewport.Update(this, _frustum);

				var size = int2((int)(ActualSize.X*PixelsPerPoint), (int)(ActualSize.Y*PixelsPerPoint));

				if defined(FUSELIBS_PROFILING)
					Profiling.BeginDraw();

				if (gv.BeginDraw(size))
				{
					extern double t;
					if defined(FUSELIBS_PROFILING)
					{
						t = Uno.Diagnostics.Clock.GetSeconds();
						Profiling.BeginRegion("Clearing");
					}

					Internal.DrawManager.PrepareDraw(_dc);

					_dc.PushViewport(this);
					_dc.PushScissor( new Recti(0, 0, size.X, size.Y) );
					_dc.Clear(Color);

					if defined(FUSELIBS_DEBUG_DRAW_RECTS)
						DrawRectVisualizer.StartFrame(_dc.RenderTarget);

					if defined(FUSELIBS_PROFILING)
						Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);

					Draw(_dc);

					_dc.PopScissor();
					_dc.PopViewport();

					if defined(FUSELIBS_DEBUG_DRAW_RECTS)
						DrawRectVisualizer.EndFrameAndVisualize(_dc);

					Internal.DrawManager.EndDraw(_dc);

					gv.EndDraw();
				}

				if defined(FUSELIBS_PROFILING)
					Profiling.EndDraw();

				if (rotationHackRedrawCount > 0)
				{
					ScheduleFrame();
					rotationHackRedrawCount-=1;
				}
			}
		}

		protected override void DrawWithChildren(DrawContext dc)
		{
			if (!_inBackground)
				base.DrawWithChildren(dc);
		}

		protected override VisualBounds CalcRenderBounds()
		{
			return base.CalcRenderBounds().AddRect(float2(0),ActualSize);
		}

		public float4x4 ProjectionTransform { get { return _frustumViewport.ProjectionTransform; } }
		public float4x4 ProjectionTransformInverse { get { return _frustumViewport.ProjectionTransformInverse; } }
		public float4x4 ViewProjectionTransform { get { return _frustumViewport.ViewProjectionTransform; } }
		public float4x4 ViewProjectionTransformInverse { get { return _frustumViewport.ViewProjectionTransformInverse; } }
		public float4x4 ViewTransformInverse { get { return _frustumViewport.ViewTransformInverse; } }
		public float4x4 ViewTransform { get { return _frustumViewport.ViewTransform; } }
		public float3 ViewOrigin { get { return _frustum.GetWorldPosition(this); } }
		public float2 ViewRange { get { return _frustum.GetDepthRange(this); } }
		public Ray PointToWorldRay(float2 pixelPos)
		{
			return ViewportHelpers.PointToWorldRay(this, _frustumViewport.ViewProjectionTransformInverse, pixelPos);
		}
		public Ray WorldToLocalRay(IViewport world, Ray worldRay, Visual where)
		{
			return ViewportHelpers.WorldToLocalRay(this, world, worldRay, where);
		}
	}
}
