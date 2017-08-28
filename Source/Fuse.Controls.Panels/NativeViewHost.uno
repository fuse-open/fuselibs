using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Elements;
using Fuse.Drawing;

namespace Fuse.Controls
{

	using Fuse.Controls.Native;
	/** Creates a layer of native @Controls on top of a @GraphicsView.
		@Controls in its subtree will be mapped to the native controls provided by the OS.

		A Fuse @App contains an implicit @GraphicsView at the root level, which ensures that UI components are renderered using high performance OpenGL graphics by default.

		To display native stock controls that are bundled with the platform's OS, you can use a @NativeViewHost.
		Some @Controls are only available as native @Controls (e.g. @WebView or @MapView), while others are available as both native and graphics @Controls (e.g. @ScrollView or @Rectangle).

		> **Note**: Native @Controls are *always* rendered in front of graphics controls.
		>
		> The only exception is when @Fuse.Controls.NativeViewHost.RenderToTexture is enabled, which comes with its own set of limitations.

		## Examples

		@WebView is only available as a native view. Here's how to display one:

			<Panel>
				<NativeViewHost>
					<WebView Url="http://example.com" />
				</NativeViewHost>
			</Panel>

		We can also layer native @Controls over each other and form heirarchies within the `NativeViewHost`, just like with regular UX markup:

			<Panel>
				<NativeViewHost>
					<Panel Alignment="Top" Padding="15" Color="#0006">
						<Text>This text is layered on top of the WebView</Text>
					</Panel>
					<WebView Url="http://example.com" />
				</NativeViewHost>
			</Panel>

		You can use the `RenderToTexture` property to render the native view to a texture to enable correct layer-compositing with
		other graphics-based @Visuals. Note that this comes at a performance cost, and *native views are not interactive while being
		rendered to texture*.

			<Text Alignment="Center">This text is layered on top of the NativeViewHost</Text>
			<NativeViewHost RenderToTexture="true">
				<Rectangle Color="#324" />
			</NativeViewHost>

		To make an app consisting solely of native components, place a `<NativeViewHost>` at the root level of your app:

			<App>
				<NativeViewHost>
					<!-- entire app goes here -->
				</NativeViewHost>
			</App>
	*/
	public class NativeViewHost : LayoutControl, ITreeRenderer, IOffscreenRendererHost
	{
		public enum InitialState
		{
			Enabled,
			Disabled
		}

		class Enable : IDisposable
		{
			NativeViewHost _host;
			public Enable(NativeViewHost host)
			{
				_host = host;
				_host._draw = true;
				_host.InvalidateVisual();
				_host.InvalidateRenderBounds();
				UpdateManager.PerformNextFrame(NextFrame);
			}
			bool _canceled = false;
			void NextFrame()
			{
				if (_canceled)
					return;
				_host.EnableOffscreen();
				_host._toggeling = null;
				_host = null;
			}
			void IDisposable.Dispose()
			{
				_canceled = true;
			}
		}

		class Disable : IDisposable
		{
			NativeViewHost _host;
			public Disable(NativeViewHost host)
			{
				_host = host;
				if defined(Android)
					_host.DisableOffscreen();
				UpdateManager.PerformNextFrame(NextFrame);

				if defined(Android || iOS)
					_host.PostUpdateTransform();
			}
			extern(iOS)
			bool _disabled = false;
			bool _canceled = false;
			void NextFrame()
			{
				if (_canceled)
					return;

				if defined(iOS)
				{
					if (!_disabled)
					{
						_host.DisableOffscreen();
						UpdateManager.PerformNextFrame(NextFrame);
						_disabled = true;
						return;
					}
				}
				_host._draw = false;
				_host._toggeling = null;
				_host.InvalidateVisual();
				_host = null;
			}
			void IDisposable.Dispose()
			{
				_canceled = true;
			}
		}

		public NativeViewHost() : this(InitialState.Disabled) { }

		public NativeViewHost(InitialState initialState)
		{
			var renderToTexture = initialState == InitialState.Enabled;
			_draw = renderToTexture;
			_renderToTexture = renderToTexture;
			_offscreenEnabled = renderToTexture;
		}

		bool _draw = false;
		bool _renderToTexture = false;
		IDisposable _toggeling;
		/** Whether to render the contents to a texture to enable layered compositing with graphics.

			Defaults to false. Enabling this property can have a performance cost and disables interaction
			with the content.
		*/
		public bool RenderToTexture
		{
			get { return _renderToTexture; }
			set
			{
				if (_renderToTexture == value)
					return;
				_renderToTexture = value;

				if (_toggeling != null)
					_toggeling.Dispose();

				if (_renderToTexture)
					_toggeling = new Enable(this);
				else
					_toggeling = new Disable(this);
			}
		}

		extern(Android || iOS)
		protected override void OnInvalidateVisual()
		{
			base.OnInvalidateVisual();
			if (_glRenderer != null)
				_glRenderer.Invalidate();
		}

		extern(Android || iOS)
		protected override void DrawWithChildren(DrawContext dc)
		{
			if (!IsInGraphicsContext)
				base.DrawWithChildren(dc);
			else if (_draw && _glRenderer != null)
				_glRenderer.Draw(
					_root,
					dc.GetLocalToClipTransform(this),
					float2(0.0f),
					ActualSize,
					Viewport.PixelsPerPoint);
		}

		protected override VisualBounds CalcRenderBounds()
		{
			var b = base.CalcRenderBounds();
			if (_draw)
				b = b.AddRect(float2(0),ActualSize);
			return b;
		}

		protected virtual IOffscreenRenderer Renderer
		{
			get { return (NativeView as IOffscreenRenderer) ?? (DummyRenderer.Instance); }
		}

		public override VisualContext VisualContext
		{
			get
			{
				return defined(!Android && !iOS)
					? VisualContext.Graphics
					: VisualContext.Native;
			}
		}

		bool IsInGraphicsContext
		{
			get { return base.VisualContext == VisualContext.Graphics; }
		}

		public override ITreeRenderer TreeRenderer
		{
			get
			{
				if defined(!Android && !iOS)
					return base.TreeRenderer;
				else
					return IsInGraphicsContext ? (ITreeRenderer)this : base.TreeRenderer;
			}
		}

		ITreeRenderer _nativeRenderer;

		void ITreeRenderer.RootingStarted(Element e) { _nativeRenderer.RootingStarted(e); }

		void ITreeRenderer.Rooted(Element e) { _nativeRenderer.Rooted(e); }

		void ITreeRenderer.Unrooted(Element e) { _nativeRenderer.Unrooted(e); }

		void ITreeRenderer.BackgroundChanged(Element e, Brush background) { _nativeRenderer.BackgroundChanged(e, background); }

		bool ITreeRenderer.Measure(Element e, LayoutParams lp, out float2 size) { return _nativeRenderer.Measure(e, lp, out size); }

		bool _isVisible = true;
		void ITreeRenderer.IsVisibleChanged(Element e, bool isVisible)
		{
			if (e == this)
			{
				_isVisible = isVisible;
				if (_isVisible)
					DisableOffscreen();
				else
					EnableOffscreen();
			}
			else
			{
				_nativeRenderer.IsVisibleChanged(e, isVisible);
			}
		}

		void ITreeRenderer.IsEnabledChanged(Element e, bool isEnabled) { _nativeRenderer.IsEnabledChanged(e, isEnabled); }

		void ITreeRenderer.OpacityChanged(Element e, float opacity) { _nativeRenderer.OpacityChanged(e, opacity);  }

		void ITreeRenderer.ClipToBoundsChanged(Element e, bool clipToBounds) { _nativeRenderer.ClipToBoundsChanged(e, clipToBounds);  }

		void ITreeRenderer.HitTestModeChanged(Element e, bool enabled) { _nativeRenderer.HitTestModeChanged(e, enabled); }

		void ITreeRenderer.ZOrderChanged(Element e, Visual[] zorder) { _nativeRenderer.ZOrderChanged(e, zorder); }

		void ITreeRenderer.TransformChanged(Element e)
		{
			if (e == this)
				UpdateHostViewTransform();
			else
				_nativeRenderer.TransformChanged(e);
		}

		extern(!iOS)
		void ITreeRenderer.Placed(Element e)
		{
			if (e == this)
				UpdateHostViewTransform();
			else
				_nativeRenderer.Placed(e);
		}

		// Because of iOS layout rules weirdness we have to
		// set the size ourselves. There are no sensible layout
		// rules on iOS that makes a view fill the parent like we want
		extern(iOS)
		void ITreeRenderer.Placed(Element e)
		{
			if (e == this)
				UpdateHostViewTransform();
			_nativeRenderer.Placed(e);
		}

		IProxyHost _proxyHost;

		extern(Android || iOS)
		NativeViewRenderer _glRenderer;

		extern(Android || iOS)
		ViewHandle _root;

		extern(Android || iOS)
		protected override void OnRooted()
		{
			WorldTransformInvalidated += OnInvalidateWorldTransform;

			if (IsInGraphicsContext)
			{
				_glRenderer = new NativeViewRenderer();
				_root = ViewFactory.InstantiateViewGroup();

				_proxyHost = this.FindProxyHost();
				if (_proxyHost == null)
					Fuse.Diagnostics.InternalError(this + " could not find an IProxyHost");

				_nativeRenderer = new Fuse.Controls.TreeRenderer(SetRoot, ClearRoot);

				if (_proxyHost != null)
				{
					if (!_offscreenEnabled)
						_proxyHost.Insert(_root);
				}
				else
					Fuse.Diagnostics.InternalError(this + " does not have an IProxyHost and will malfunction");
			}
			base.OnRooted();
		}

		extern(Android || iOS)
		void SetRoot(ViewHandle viewHandle)
		{
			_root.InsertChild(viewHandle);
		}

		extern(Android || iOS)
		void ClearRoot(ViewHandle viewHandle)
		{
			_root.RemoveChild(viewHandle);
		}

		bool _offscreenEnabled = false;
		void EnableOffscreen()
		{
			if (!_offscreenEnabled && !_isVisible)
			{
				if defined(Android || iOS)
					_proxyHost.Remove(_root);
				_offscreenEnabled = true;
			}
		}
		void DisableOffscreen()
		{
			if (_offscreenEnabled && _isVisible)
			{
				if defined(Android || iOS)
					_proxyHost.Insert(_root);
				_offscreenEnabled = false;
			}
		}

		extern(!Android && !iOS) void UpdateHostViewTransform() { }
		extern(Android || iOS) void UpdateHostViewTransform()
		{
			_updateTransform = false;
			if (_root == null)
				return;

			var transform = CalcTransform();
			var size = ActualSize;
			var density = Viewport.PixelsPerPoint;

			var p = Parent;
			if (p is Control)
				((Control)p).CompensateForScrollView(ref transform);

			_root.UpdateViewRect(transform, size, density);
		}

		float4x4 CalcTransform()
		{
			return IsInGraphicsContext
				? Uno.Matrix.Mul(_proxyHost.WorldTransformInverse, WorldTransform)
				: LocalTransform;
		}

		extern(Android || iOS)
		protected override void OnUnrooted()
		{
			WorldTransformInvalidated -= OnInvalidateWorldTransform;

			if (IsInGraphicsContext && _proxyHost != null && !_offscreenEnabled)
				_proxyHost.Remove(_root);

			if (IsInGraphicsContext)
				_glRenderer.Dispose();

			base.OnUnrooted();
			_root = null;
			_nativeRenderer = null;
			_proxyHost = null;
			_glRenderer = null;
		}

		/**
			We need to react to world transform changes since we have no native container tree
			that responds to all local transform changes.
		*/
		extern(Android || iOS)
		void OnInvalidateWorldTransform(object sender, EventArgs args)
		{
			if (RenderToTexture || !IsInGraphicsContext)
				return;
			PostUpdateTransform();
		}

		bool _updateTransform = false;
		extern(Android || iOS)
		void PostUpdateTransform()
		{
			if (!_updateTransform)
			{
				UpdateManager.AddDeferredAction(UpdateHostViewTransform, UpdateStage.Layout, LayoutPriority.Post);
				_updateTransform = true;
			}
		}

		class DummyRenderer : IOffscreenRenderer
		{
			static DummyRenderer _instance;
			public static DummyRenderer Instance
			{
				get { return _instance ?? (_instance = new DummyRenderer()); }
			}
			void IOffscreenRenderer.EnableOffscreen() { }
			void IOffscreenRenderer.DisableOffscreen() { }
			void INativeViewRenderer.Draw(float4x4 localToClipTransform, float2 position, float2 size, float density) { }
			void INativeViewRenderer.Invalidate() { }
			void IDisposable.Dispose() { }
		}

	}
}