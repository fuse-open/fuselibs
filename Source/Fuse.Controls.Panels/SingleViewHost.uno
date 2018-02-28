using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Elements;
using Fuse.Drawing;

namespace Fuse.Controls
{
	using Fuse.Controls.Native;
	extern(Android || iOS) public class SingleViewHost : Control, ITreeRenderer, IDisposable
	{
		public enum RenderState
		{
			Enabled,
			Disabled,
		}

		class Enable : IDisposable
		{
			SingleViewHost _host;
			public Enable(SingleViewHost host)
			{
				_host = host;
				_host._draw = true;
				_host.InvalidateVisual();
				_host.InvalidateRenderBounds();
				UpdateManager.PerformNextFrame(NextFrame);
			}

			void NextFrame()
			{
				if (_canceled)
					return;
				_host.SetOffscreen();
				_host._changingState = null;
				_host = null;
			}

			bool _canceled;
			void IDisposable.Dispose() { _canceled = true; }
		}

		class Disable : IDisposable
		{
			SingleViewHost _host;
			public Disable(SingleViewHost host)
			{
				_host = host;
				_host.SetOnscreen();

				var delay = defined(ANDROID) ? 2 : 1;
				// Delay disabling of draw for 2 frames on android. In testing I observed that
				// there often were a 2 frame delay for the native view to show up on screen.
				UpdateManager.PerformNextFrame(NextFrame, UpdateStage.Primary, delay);
			}

			void NextFrame()
			{
				if (_canceled)
					return;
				_host._draw = false;
				_host.InvalidateVisual();
				_host._changingState = null;
				_host = null;
			}

			bool _canceled;
			void IDisposable.Dispose() { _canceled = true; }
		}

		RenderState _renderState;
		public RenderState RenderToTexture
		{
			get { return _renderState; }
			set
			{
				if (_renderState == value)
					return;

				_renderState = value;

				if (_changingState != null)
					_changingState.Dispose();

				if (_renderState == RenderState.Enabled)
					_changingState = new Enable(this);
				else
					_changingState = new Disable(this);
			}
		}

		IDisposable _changingState;

		ViewHandle _viewHandle;
		IViewHandleRenderer _renderer;

		public SingleViewHost(RenderState initialState, ViewHandle viewHandle, IViewHandleRenderer renderer)
		{
			_renderState = initialState;
			_viewHandle = viewHandle;
			_renderer = renderer;
			_draw = initialState == RenderState.Enabled;
		}

		IProxyHost _proxyHost;

		protected override void OnRooted()
		{
			base.OnRooted();
			_proxyHost = this.FindProxyHost();
			if (RenderToTexture == RenderState.Disabled)
				SetOnscreen();

			WorldTransformInvalidated += OnInvalidateWorldTransform;
		}

		protected override void OnUnrooted()
		{
			WorldTransformInvalidated -= OnInvalidateWorldTransform;

			base.OnUnrooted();
			SetOffscreen();
			_proxyHost = null;
		}

		bool _offscreen = true;
		void SetOnscreen()
		{
			if (_offscreen && _proxyHost != null)
			{
				_proxyHost.Insert(_viewHandle);
				_offscreen = false;
			}
		}

		void SetOffscreen()
		{
			if (!_offscreen && _proxyHost != null)
			{
				_proxyHost.Remove(_viewHandle);
				_offscreen = true;
			}
		}

		bool _updateTransform = false;
		void OnInvalidateWorldTransform(object sender, EventArgs args)
		{
			if (!_updateTransform)
			{
				UpdateManager.AddDeferredAction(UpdateHostViewTransform, UpdateStage.Layout, LayoutPriority.Post);
				_updateTransform = true;
			}
		}

		protected override void OnInvalidateVisual()
		{
			base.OnInvalidateVisual();
			if (_renderer != null)
				_renderer.Invalidate();
		}

		bool _draw;
		protected override void DrawWithChildren(DrawContext dc)
		{
			if (_draw)
				_renderer.Draw(
					_viewHandle,
					dc.GetLocalToClipTransform(this),
					float2(0.0f),
					ActualSize,
					Viewport.PixelsPerPoint);
		}

		protected override VisualBounds CalcRenderBounds()
		{
			return (_draw)
				? base.CalcRenderBounds().AddRect(float2(0.0f),ActualSize)
				: base.CalcRenderBounds();
		}

		void UpdateHostViewTransform()
		{
			if (!IsRootingCompleted)
				return;
			_updateTransform = false;
			var transform = CalcTransform();
			var size = ActualSize;
			var density = Viewport.PixelsPerPoint;

			var p = Parent;
			if (p is Control)
				((Control)p).CompensateForScrollView(ref transform);

			_viewHandle.UpdateViewRect(transform, size, density);
		}

		float4x4 CalcTransform()
		{
			return Uno.Matrix.Mul(_proxyHost.WorldTransformInverse, WorldTransform);
		}

		protected override float2 GetContentSize(LayoutParams lp)
		{
			if (_viewHandle.IsLeafView)
				return _viewHandle.Measure(lp, Viewport.PixelsPerPoint);
			else
				return base.GetContentSize(lp);
		}

		public override ITreeRenderer TreeRenderer
		{
			get { return this; }
		}

		void ITreeRenderer.RootingStarted(Element e) {}
		void ITreeRenderer.Rooted(Element e) {}
		void ITreeRenderer.Unrooted(Element e) {}
		void ITreeRenderer.BackgroundChanged(Element e, Brush background) {}
		void ITreeRenderer.ClipToBoundsChanged(Element e, bool clipToBounds) {}
		void ITreeRenderer.ZOrderChanged(Element e, Visual[] zorder) {}
		void ITreeRenderer.RenderBoundsChanged(Element e) { }

		bool _isVisible = true;
		void ITreeRenderer.IsVisibleChanged(Element e, bool isVisible)
		{
			_isVisible = isVisible;
			_viewHandle.SetOpacity(isVisible ? e.Opacity : 0.0f);
		}
		void ITreeRenderer.OpacityChanged(Element e, float opacity)
		{
			if (_isVisible)
				_viewHandle.SetOpacity(opacity);
		}
		void ITreeRenderer.HitTestModeChanged(Element e, bool enabled)
		{
			_viewHandle.SetHitTestEnabled(enabled);
		}
		void ITreeRenderer.IsEnabledChanged(Element e, bool isEnabled)
		{
			_viewHandle.SetEnabled(isEnabled);
		}
		bool ITreeRenderer.Measure(Element e, LayoutParams lp, out float2 size) { size = float2(0.0f); return false; }

		void ITreeRenderer.TransformChanged(Element e)
		{
			if (e == this)
				UpdateHostViewTransform();
		}

		void ITreeRenderer.Placed(Element e)
		{
			if (e == this)
				UpdateHostViewTransform();
		}

		public void Dispose()
		{
			_renderer.Dispose();
			_renderer = null;
			_viewHandle = null;
		}
	}
}