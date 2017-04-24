
using Uno;
using Uno.Compiler.ExportTargetInterop;
using OpenGL;

namespace Fuse.Controls.Native.Android
{
	extern(!Android) public abstract class GraphicsViewBase { }
	[TargetSpecificImplementation]
	extern(Android) public abstract class GraphicsViewBase : View, IGraphicsView, IViewHost
	{
		void IViewHost.Insert(ViewHandle child)
		{
			ViewGroup.AddView(Handle, child.NativeHandle);
		}

		void IViewHost.Remove(ViewHandle child)
		{
			ViewGroup.RemoveView(Handle, child.NativeHandle);
		}

		Java.Object _graphicsViewHandle;
		protected Java.Object GraphicsViewHandle
		{
			get { return _graphicsViewHandle; }
		}

		protected GraphicsViewBase(Java.Object handle) : base(ViewGroup.Create())
		{
			_graphicsViewHandle = handle;
			ViewGroup.AddView(Handle, _graphicsViewHandle, 0);
		}

		Java.Object _surfaceHandle;
		IntPtr _eglSurface = IntPtr.Zero;
		IntPtr _nativeWindow = IntPtr.Zero;

		[TargetSpecificImplementation]
		[Require("Source.Include", "Uno/Graphics/GLHelper.h")]
		protected void SetSurface(Java.Object surfaceHandle)
		{
			if (_surfaceHandle != null)
			{
				// dispose surfaceHandle
			}
			_surfaceHandle = surfaceHandle;
			_nativeWindow = extern<IntPtr>( ((global::Android.Base.Wrappers.JWrapper)_surfaceHandle)._GetJavaObject() ) "GLHelper::GetANativeWindowFromSurface($0)";
			extern "EGLSurface tempSurface";
			extern (_nativeWindow) "GLHelper::CreateNewSurfaceAndMakeCurrent( (ANativeWindow*)$0, tempSurface)";
			_eglSurface = extern<IntPtr> "tempSurface";
		}

		[TargetSpecificImplementation]
		[Require("Source.Include", "Uno/Graphics/GLHelper.h")]
		protected void DestroySurface()
		{
			extern(_eglSurface) "GLHelper::SwapBackToBackgroundSurface( (EGLSurface)$0 )";
			_eglSurface = IntPtr.Zero;
			extern(_nativeWindow) "ANativeWindow_release( (ANativeWindow*)$0 )";
			_nativeWindow = IntPtr.Zero;
			//_surface.Dispose(); implement
			_surfaceHandle = null;
		}

		[TargetSpecificImplementation]
		[Require("Source.Include", "Uno/Graphics/GLHelper.h")]
		public bool BeginDraw(int2 size)
		{
			if (_eglSurface == IntPtr.Zero)
				return false;

			double t;
			if defined(FUSELIBS_PROFILING)
			{
				t = Uno.Diagnostics.Clock.GetSeconds();
				Profiling.BeginRegion("Fuse.Controls.Native.Android.GraphicsView.BeginDraw");
			}

			extern(_eglSurface) "GLHelper::MakeCurrent( GLHelper::GetSurfaceContext(), (EGLSurface)$0 )";
			GL.Viewport(0, 0, size.X, size.Y);

			if defined(FUSELIBS_PROFILING)
				Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);

			return true;
		}

		[TargetSpecificImplementation]
		[Require("Source.Include", "Uno/Graphics/GLHelper.h")]
		public void EndDraw()
		{
			double t;
			if defined(FUSELIBS_PROFILING)
			{
				t = Uno.Diagnostics.Clock.GetSeconds();
				Profiling.BeginRegion("Fuse.Controls.Native.Android.GraphicsView.EndDraw");
			}

			extern(_eglSurface) "GLHelper::SwapBuffers( $0 )";

			if defined(FUSELIBS_PROFILING)
				Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);
		}
	}
}
