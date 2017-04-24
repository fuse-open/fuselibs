using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Runtime.Implementation;
using Uno.Runtime.Implementation.Internal;

using Fuse.Input;

namespace Fuse
{

	public interface IFrame
	{
		event EventHandler FrameChanged;
		float2 Size { get; }
	}

	extern(Android || iOS)
	class SystemUIFrame : IFrame
	{
		public event EventHandler FrameChanged
		{
			add { Fuse.Platform.SystemUI.FrameChanged += value; }
			remove { Fuse.Platform.SystemUI.FrameChanged -= value; }
		}

		public float2 Size
		{
			get { return Fuse.Platform.SystemUI.Frame.Size; }
		}
	}

	public class RootViewport : Visual, IViewport, IDisposable
	{
		protected readonly Uno.Platform.Window Window;

		public event Action<float2> Resized;

		extern(Android || iOS)
		IFrame _frame;

		extern(Android || iOS)
		public RootViewport(IFrame frame)
		{
			_frame = frame;
			_frame.FrameChanged += OnResized;

			_overridePixelsPerPoint = 0;

			EstablishSize();

			_frustumViewport.Update(this, Frustum);

			RootInternal(null);

			// Hook up global layout
			UpdateManager.AddAction(PerformLayout, UpdateStage.Layout);
		}

		extern(Android || iOS)
		public RootViewport() : this(new SystemUIFrame()) { }

		extern(!Android && !iOS)
		public RootViewport(Uno.Platform.Window window, float overridePixelsPerPoint = 0)
		{
			_overridePixelsPerPoint = overridePixelsPerPoint;

			if defined(!MOBILE)
			{
				this.Window = window;
			}

			EstablishSize();

			if defined(!MOBILE)
			{
				Window.Resized += OnResized;
			}

			_frustumViewport.Update(this, Frustum);

			RootInternal(null);

			// Hook up global layout
			UpdateManager.AddAction(PerformLayout, UpdateStage.Layout);
		}
		
		void IDisposable.Dispose()
		{
			UpdateManager.RemoveAction(PerformLayout, UpdateStage.Layout);
			Children.Clear();
		}

		public override VisualContext VisualContext
		{
			get { return VisualContext.Graphics; }
		}

		public override void Draw(DrawContext dc)
		{
			for (int i = 0; i < Children.Count; i++)
			{
				var v = Children[i] as Visual;
				v.Draw(dc);
			}
		}

		void OnGotFocus(object sender, EventArgs args)
		{
			try
			{
				Focus.OnWindowGotFocus(sender, args);
			}
			catch (Exception e)
			{
				AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		void OnLostFocus(object sender, EventArgs args)
		{
			try
			{
				Focus.OnWindowLostFocus(sender, args);
			}
			catch (Exception e)
			{
				AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		internal void OnResized(object s, object a)
		{
			EstablishSize();
			_frustumViewport.Update(this, Frustum);
		}

		IFrustum Frustum = new OrthographicFrustum();
		FrustumViewport _frustumViewport = new FrustumViewport();

		bool _sizeOverridden;
		internal void OverrideSize( float2 pixelSize, float pixelsPerPoint, float pixelsPerOSPoint )
		{
			_pixelSize = pixelSize;
			_pixelsPerPoint = pixelsPerPoint;
			_pixelsPerOSPoint = pixelsPerOSPoint;
			_sizeOverridden = true;
			InvalidateLayout();
		}

		void EstablishSize()
		{
			if (!_sizeOverridden)
			{
				EstablishSizeInternals();
			}
			if (Resized != null)
				Resized(_pixelSize);
		}

		extern(!MOBILE) void EstablishSizeInternals()
		{
			//for test support
			if (Window == null || Fuse.AppBase.Current == null)
			{
				_pixelsPerPoint = 1;
				_pixelsPerOSPoint = 1;
				return;
			}

			var wnd = WindowHelpers.GetPlatformWindowHandle(Window);
			var osPointSize = (float2)Window.ClientSize;
			var pixelSize = (float2)Application.Current.GraphicsController.Backbuffer.Size;

			//workaround for empty size on some platforms while minimized
			//https://github.com/fusetools/fuselibs/issues/1772
			if (osPointSize.X < 1 || osPointSize.Y < 1)
			{
				_pixelSize = float2(0);
				//use old value, or try to guess correct density anyway (in case something uses it for off-screen drawing)
				if (_pixelsPerOSPoint == 0 || _pixelsPerPoint ==0) 
				{
					_pixelsPerOSPoint = PlatformWindowImpl.GetDensity(wnd);
					_pixelsPerPoint = _pixelsPerOSPoint;
				}
				return;
			}
			
			//WORKAROUND: https://github.com/fusetools/Uno/issues/327
			var pointAspect = (float)osPointSize.X / (float)osPointSize.Y;
			var pixelAspect = (float)pixelSize.X / (float)pixelSize.Y;
			var aspectFlip = false;
			if ( (pointAspect > 1 && pixelAspect < 1) || (pointAspect < 1 && pixelAspect > 1))
			{
				pixelSize = pixelSize.YX;
				aspectFlip = true;
			}

			var pixelsPerOSPoint = pixelSize / osPointSize;
			if (Math.Abs(pixelsPerOSPoint.X - pixelsPerOSPoint.Y) > float.ZeroTolerance)
				Fuse.Diagnostics.InternalError( "non-square pixelsPerOSPoint: " + pixelsPerOSPoint );

			var osWindowDensity = PlatformWindowImpl.GetDensity(wnd);
			_pixelsPerPoint = pixelsPerOSPoint.X * osWindowDensity;
			if (_pixelsPerPoint <= float.ZeroTolerance)
				throw new Exception("A Window cannot have zero density.");

			_pixelSize = pixelSize;
			_pixelsPerOSPoint = _pixelsPerPoint / osWindowDensity;
		}

		extern(MOBILE) void EstablishSizeInternals()
		{
			//for test support
			if (Fuse.AppBase.Current == null)
			{
				_pixelsPerPoint = 1;
				_pixelsPerOSPoint = 1;
				return;
			}

			_pixelSize = _frame.Size;
			_pixelsPerOSPoint = Uno.Platform.Displays.MainDisplay.Density;
			_pixelsPerPoint = _pixelsPerOSPoint;
		}

		float _pixelsPerPoint;
		float _pixelsPerOSPoint;
		float _overridePixelsPerPoint;

		internal float PixelsPerOSPoint
		{
			get { return _pixelsPerOSPoint; }
		}

		public float PixelsPerPoint
		{
			get { return _overridePixelsPerPoint > 0 ? _overridePixelsPerPoint : _pixelsPerPoint; }
		}

		//it's unclear why these need to be marked "virtual" here as they are part of the IViewport interface
		//(need to be virtual for some tests)
		public virtual float2 Size
		{
			get { return PixelSize / PixelsPerPoint; }
		}

		float2 _pixelSize;
		public virtual float2 PixelSize
		{
			get { return _pixelSize; }
		}

		public float4x4 ProjectionTransform
		{ get { return _frustumViewport.ProjectionTransform; } }
		public float4x4 ProjectionTransformInverse
		{ get { return _frustumViewport.ProjectionTransformInverse; } }
		public float4x4 ViewProjectionTransform
		{ get { return _frustumViewport.ViewProjectionTransform; } }
		public float4x4 ViewProjectionTransformInverse
		{ get { return _frustumViewport.ViewProjectionTransformInverse; } }
		public float4x4 ViewTransformInverse
		{ get { return _frustumViewport.ViewTransformInverse; } }
		public float4x4 ViewTransform
		{ get { return _frustumViewport.ViewTransform; } }
		public float3 ViewOrigin { get { return Frustum.GetWorldPosition(this); } }
		public float2 ViewRange { get { return Frustum.GetDepthRange(this); } }
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
