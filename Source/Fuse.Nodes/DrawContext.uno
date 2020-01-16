using Uno;
using Uno.Graphics;
using Uno.Collections;
using Uno.Compiler;
using Uno.Platform;
using OpenGL;

namespace Fuse
{
	internal class RenderTargetEntry
	{
		extern(OPENGL) public readonly GLFramebufferHandle GLFramebuffer;
		public readonly RenderTarget RenderTarget;
		public readonly int2 GLViewportPixelSize;
		public readonly int4 GLScissor;

		extern(OPENGL) public RenderTargetEntry(RenderTarget rt, int2 viewportPixelSize, int4 glScissor,
			GLFramebufferHandle handle)
		{
			RenderTarget = rt;
			GLViewportPixelSize = viewportPixelSize;
			GLScissor = glScissor;
			GLFramebuffer = handle;
		}
	}

	public sealed class DrawContext
	{
		IRenderViewport _viewport = null;

		public IRenderViewport Viewport
		{
			get { return _viewport; }
		}

		List<IRenderViewport> _viewports = new List<IRenderViewport>();
		public void PushViewport(IRenderViewport v)
		{
			OnRenderTargetChange();
			_viewports.Add(_viewport);
			_viewport = v;
		}

		public void PopViewport()
		{
			OnRenderTargetChange();
			_viewport = _viewports.RemoveLast();
		}

		public float4x4 GetLocalToClipTransform(Visual n)
		{
			var m = n.WorldTransform;
			var p = Matrix.Mul(m, _viewport.ViewProjectionTransform);
			return p;
		}

		GraphicsContextBackend _backend;
		RenderTarget _rootbuffer, _renderTarget;

		public DrawContext(IRenderViewport viewport)
		{
			if defined(!MOBILE)
				_backend = GraphicsContextBackend.Instance;
			_viewport = viewport;

			_rootbuffer = new RenderTarget();
			_renderTarget = _rootbuffer;
		}

		public event EventHandler RenderTargetChange;

		internal void OnRenderTargetChange()
		{
			if (RenderTargetChange != null)
				RenderTargetChange(this, EventArgs.Empty);
		}

		internal void CaptureRootbuffer()
		{
			if defined(OPENGL)
			{
				GL.Enable(GLEnableCap.ScissorTest);
				if defined(DEBUG) CheckGLError();

				_glScissor = GL.GetInteger(GLInteger4Name.ScissorBox);
				_glViewport = GL.GetInteger(GLInteger4Name.Viewport);
				_glFramebuffer = GL.GetFramebufferBinding();

				_rootbuffer.GLFramebufferHandle = _glFramebuffer;

				if defined(mobile)
				{
					float2 size = Fuse.Platform.SystemUI.Frame.Size;
					_rootbuffer.Size = int2((int)size.X, (int)size.Y);
				}
				else
				{
					_rootbuffer.Size = _backend.GetBackbufferSize();
				}
				_rootbuffer.HasDepth = true;
			}
		}

		internal void ReleaseRootbuffer()
		{
			//maybe we should actually bind back to the rootbuffer?

			if (_glScissors.Count > 0)
				Fuse.Diagnostics.InternalError("Unpopped Scissor", this);
			_glScissors.Clear();

			if (_cullFaces.Count > 0)
				Fuse.Diagnostics.InternalError("Unpopped CullFace", this);
			_cullFaces.Clear();

			if (_viewports.Count > 0)
				Fuse.Diagnostics.InternalError("Unpopped Viewport", this);
			_viewports.Clear();

			if (_renderTargets.Count > 0)
				Fuse.Diagnostics.InternalError("Unpopped RenderTarget", this);
			_renderTargets.Clear();
		}

		List<RenderTargetEntry> _renderTargets = new List<RenderTargetEntry>();

		public Uno.Graphics.RenderTarget RenderTarget
		{
			get { return _renderTarget; }
		}

		extern(OPENGL) GLFramebufferHandle _glFramebuffer;
		extern(OPENGL) GLFramebufferHandle GLFramebuffer
		{
			get
			{
				if defined(FUSELIBS_GLDEBUG)
				{
					var g = GL.GetFramebufferBinding();
					if (g != _glFramebuffer)
						GLInconsistent("GLFramebuffer");
				}
				return _glFramebuffer;
			}
			set
			{
				_glFramebuffer = value;
				GL.BindFramebuffer(GLFramebufferTarget.Framebuffer, value);
				if defined(DEBUG) CheckGLError();
			}
		}

		internal RenderTargetEntry GetRenderTargetEntry()
		{
			if defined(OPENGL)
				return new RenderTargetEntry(RenderTarget, GLViewportPixelSize, GLScissor,
					GLFramebuffer);
			return null;
		}

		public void PushRenderTarget(framebuffer fb)
		{
			PushRenderTarget(fb.RenderTarget);
		}

		public void PushRenderTarget(RenderTarget rt)
		{
			PushRenderTarget(rt, rt.Size, int4(0,0,rt.Size.X,rt.Size.Y));
		}

		void PushRenderTarget(RenderTarget rt, int2 viewportPixelSize, int4 glscissor)
		{
			OnRenderTargetChange();
			_renderTargets.Add(GetRenderTargetEntry());
			if defined(OPENGL)
			{
				GLFramebuffer = rt.GLFramebufferHandle;
				if defined(DEBUG) CheckGLError();
			}
			_renderTarget = rt;
			GLViewportPixelSize = viewportPixelSize;
			GLScissor = glscissor;
		}
		
		public void PushEmptyRenderTarget()
		{
			OnRenderTargetChange();
			_renderTargets.Add(GetRenderTargetEntry());
		}		
		
		public void PopRenderTarget()
		{
			OnRenderTargetChange();
			var old = _renderTargets.RemoveLast();
			_renderTarget = old.RenderTarget;
			if defined(OPENGL)
			{
				GLFramebuffer = old.GLFramebuffer;
				if defined(DEBUG) CheckGLError();
			}
			GLViewportPixelSize = old.GLViewportPixelSize;
			GLScissor = old.GLScissor;
		}

		public void PushRenderTargetFrustum(framebuffer fb, IFrustum frustum)
		{
			PushRenderTarget(fb.RenderTarget, fb.Size, int4(int2(0,0), fb.Size));
			PushViewport(new FixedViewport(fb.Size, Viewport.PixelsPerPoint, frustum));
		}

		public void PushRenderTargetViewport(framebuffer fb, IRenderViewport viewport)
		{
			PushRenderTarget(fb.RenderTarget, fb.Size, int4(int2(0,0), fb.Size));
			PushViewport(viewport);
		}

		public void PopRenderTargetFrustum()
		{
			PopViewport();
			PopRenderTarget();
		}

		public void PopRenderTargetViewport()
		{
			PopViewport();
			PopRenderTarget();
		}

		public void Clear(float4 color, float depth = 1.0f)
		{
			if defined(OPENGL)
			{
				OpenGL.GL.ClearDepth(depth);
				OpenGL.GL.ClearColor(color.X, color.Y, color.Z, color.W);
				OpenGL.GL.Clear(GLClearBufferMask.ColorBufferBit | GLClearBufferMask.DepthBufferBit |
				GLClearBufferMask.StencilBufferBit);
				if defined(DEBUG) CheckGLError();
			}
		}

		public Recti Scissor
		{
			get
			{
				var vsz = GLViewportPixelSize;
				var gl = GLScissor;
				var x = gl.X;
				var y = -gl.W-(gl.Y-vsz.Y);
				return new Recti(x, y, x + gl.Z, y + gl.W);
			}
			internal set
			{
				var vsz = GLViewportPixelSize;
				GLScissor = int4(value.Left,vsz.Y-(value.Top+value.Size.Y),value.Size.X,value.Size.Y);
			}
		}

		int4 _glScissor;
		int4 GLScissor
		{
			get
			{
				if defined(OpenGL && FUSELIBS_GLDEBUG)
				{
					var s = GL.GetInteger(GLInteger4Name.ScissorBox);
					if (s != _glScissor)
						GLInconsistent("GLScissor: " + s + " != " + _glScissor);
				}

				return _glScissor;
			}
			private set
			{
				_glScissor = value;
				if defined(OpenGL)
				{
					OpenGL.GL.Scissor(value[0],value[1],value[2],value[3]);
					if defined(DEBUG) CheckGLError();
				}
			}
		}

		List<int4> _glScissors = new List<int4>();

		public void PushScissor(Recti scissor)
		{
			_glScissors.Add(GLScissor);
			Scissor = scissor;
		}

		public void PopScissor()
		{
			var s = _glScissors.RemoveLast();
			GLScissor = s;
		}

		int4 _glViewport;
		/*
			TODO: review what uses this since `Viewport.PixelSize` should probably be used instead
			as this is a "hidden" detail. Any uses of this are also very likely wrong without considering
			the origin as well (nothing in Fuselibs uses anything non-0,0 at the moment though)
		*/
		public int2 GLViewportPixelSize
		{
			get
			{
				if defined(FUSELIBS_GLDEBUG && OpenGL)
				{
					var vpp = GL.GetInteger(GLInteger4Name.Viewport);
					if (_glViewport != vpp)
						GLInconsistent("GLViewport: " + vpp + " != " + _glViewport);
				}

				return _glViewport.ZW;
			}
			private set
			{
				_glViewport = int4(0,0,value.X,value.Y);
				if defined(OPENGL)
				{
					OpenGL.GL.Viewport(0, 0, value.X, value.Y);
					if defined(DEBUG) CheckGLError();
				}
			}
		}

		public float2 GLViewportPointSize
		{
			get
			{
				var rsz = (float2)GLViewportPixelSize;
				return rsz / ViewportPixelsPerPoint;
			}
		}

		public float ViewportPixelsPerPoint
		{
			get
			{
				return Viewport.PixelsPerPoint;
			}
		}

		public bool IsCaching { get; set; }

		List<PolygonFace> _cullFaces = new List<PolygonFace>();
		PolygonFace _cullFace = PolygonFace.None;
		public PolygonFace CullFace
		{
			get { return _cullFace; }
		}

		public void PushCullFace(PolygonFace cf)
		{
			_cullFaces.Add(_cullFace);
			_cullFace = cf;
		}

		public void PopCullFace()
		{
			_cullFace = _cullFaces.RemoveLast();
		}

		void CheckGLError([CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			if defined(OPENGL)
			{
				var e = GL.GetError();
				if (e != GLError.NoError)
					Fuse.Diagnostics.InternalError("" + e, this, filePath, lineNumber, memberName);
			}
		}

		void GLInconsistent(string msg)
		{
			Fuse.Diagnostics.InternalError("Inconsistent GL state: " + msg, this);
		}
	}
}
