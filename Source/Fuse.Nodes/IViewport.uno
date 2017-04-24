using Uno;
using Uno.Collections;

namespace Fuse
{
	public interface ICommonViewport
	{
		/**
			Defines the density of the viewport in pixels per point.
		*/
		float PixelsPerPoint { get; }
		
		/**
			The nominal 2-dimensionl size of the viewport in points.
		*/
		float2 Size { get; }
		
		/**
			The nominal 2-dimensional pixel size of the viewport in pixels.
		*/
		float2 PixelSize { get; }
		
		/**
			A transform from world space to view space for this viewport. This can be used
			to determine the camere relative location of items.
		*/
		float4x4 ViewTransform { get; }
	}
	
	/**
		Defines the current drawing viewports. This really has nothing to do with the IViewport but was
		historically connected to it.
	*/
	public interface IRenderViewport : ICommonViewport
	{
		/**
			A transform converting from view space into projection/clip space. This is expressed as relative
			to the most recently defined world.
		*/
		float4x4 ProjectionTransform { get; }
		
		/**
			A transform converting from world space to projection/clip space.  This is expressed as relative
			to the most recently defined world.
		*/
		float4x4 ViewProjectionTransform { get; }

		/**
			The origin of the view space (camera position).
		*/
		float3 ViewOrigin { get; }

		/**
			The depth range the camera is intending to project.
		*/
		float2 ViewRange { get; }
	}
	
	/**
		Defines the current logical viewport for input translation.

		Each viewport defines a new world.
	*/
	public interface IViewport : ICommonViewport
	{
		/**
			Obtain a Ray in the world defined by this Viewport from the position in the window.
		*/
		Ray PointToWorldRay(float2 pointPos);

		/**
			Transform a Ray from a world ray into a local ray.

			@param world The world from which this ray originates. Usually the object on which `PointToWorldRay` was called.
			@param worldRay The worldRay to transform
			@param where Into the local space of this Visual
		*/
		Ray WorldToLocalRay(IViewport world, Ray worldRay, Visual where);
	}

	public static class ViewportHelpers
	{
		static public Ray PointToWorldRay(IViewport viewport, float4x4 viewProjectionInverse, float2 pointPos)
		{
			float2 p = float2(pointPos.X / viewport.Size.X * 2 - 1,
				pointPos.Y / viewport.Size.Y * -2 + 1);

			var vpi = viewProjectionInverse; //iewport.ViewProjectionTransformInverse;

			var r0 = Vector.TransformCoordinate(float3(p,-1),vpi);
			var r1 = Vector.TransformCoordinate(float3(p,1),vpi);
			return new Ray(r0, Vector.Normalize(r1-r0));
		}

		/**
			Transfroms a `world` ray (relative to `viewport`) into the a local ray in `where`.
		*/
		static public Ray WorldToLocalRay(IViewport viewport, IViewport world, Ray worldRay, Visual where)
		{
			if (where == world)
				return worldRay;

			var wi = where.WorldTransformInverse;
			var r0 = Vector.TransformCoordinate(worldRay.Position, wi);
			var r1 = Vector.TransformCoordinate(worldRay.Position + worldRay.Direction, wi);
			return new Ray(r0, Vector.Normalize(r1-r0));
		}

		/**
			Calculates where a ray intsersects the local 2d-interface plane (Z=0).
		*/
		static public float2 LocalPlaneIntersection(Ray local)
		{
			var t = -local.Position.Z / local.Direction.Z;
			var plane = local.Position + local.Direction * t;
			return plane.XY;
		}
	}


	/**
		Implementation of an IViewport using a Frustum.
	*/
	class FrustumViewport
	{
		public float4x4 ProjectionTransform;
		public float4x4 ProjectionTransformInverse;
		public float4x4 ViewProjectionTransform;
		public float4x4 ViewProjectionTransformInverse;
		public float4x4 ViewTransform;
		public float4x4 ViewTransformInverse;
		
		public void Update( IViewport viewport, IFrustum frustum )
		{
			if (frustum.TryGetProjectionTransform(viewport, out ProjectionTransform) &&
			    frustum.TryGetProjectionTransformInverse(viewport, out ProjectionTransformInverse))
			{
				ViewTransform = frustum.GetViewTransform(viewport);
				ViewTransformInverse = frustum.GetViewTransformInverse(viewport);
				ViewProjectionTransform = Matrix.Mul(ViewTransform, ProjectionTransform);
				ViewProjectionTransformInverse = Matrix.Mul(ProjectionTransformInverse,
					ViewTransformInverse);
			}
			else
			{
				ProjectionTransform = float4x4.Identity;
				ProjectionTransformInverse = float4x4.Identity;
				ViewTransform = float4x4.Identity;
				ViewTransformInverse = float4x4.Identity;
				ViewProjectionTransform = float4x4.Identity;
				ViewProjectionTransformInverse = float4x4.Identity;
			}
		}

		float4x4 GetClipToVisualSpace(float2 size)
		{
			var mx = float4x4.Identity;
			mx.M11 = size.X/2;
			mx.M22 = -size.Y/2;
			mx.M41 = size.X/2;
			mx.M42 = size.Y/2;
			return mx;
		}
		
		public float4x4 GetFlatWorldToVisualTransform(float2 size)
		{
			var mx = GetClipToVisualSpace(size);
			return Matrix.Mul(ViewProjectionTransform,mx);
		}
		
		public float4x4 LocalViewProjectionTransform;
		public void Update( IViewport viewport, IFrustum frustum, Visual where )
		{
			Update( viewport, frustum );

			LocalViewProjectionTransform =GetFlatWorldToVisualTransform(viewport.Size);
		}
	}

	//helper class to create quick viewports
	class FixedViewport : IRenderViewport, IViewport
	{
		float _pixelsPerPoint;
		public float PixelsPerPoint { get {return _pixelsPerPoint; } }
		
		public float2 Size { get { return PixelSize / PixelsPerPoint; } }
		
		float2 _pixelSize;
		public float2 PixelSize { get { return _pixelSize; } }
		
		FrustumViewport _frustumViewport = new FrustumViewport();
		
		public float4x4 ProjectionTransform
		{ get { return _frustumViewport.ProjectionTransform; } }
		public float4x4 ProjectionTransformInverse
		{ get { return _frustumViewport.ProjectionTransformInverse; } }
		public float4x4 ViewProjectionTransform
		{ get { return _frustumViewport.ViewProjectionTransform; } }
		public float4x4 ViewProjectionTransformInverse
		{ get { return _frustumViewport.ViewProjectionTransformInverse; } }
		public float4x4 ViewTransform
		{ get { return _frustumViewport.ViewTransform; } }
		public float4x4 ViewTransformInverse
		{ get { return _frustumViewport.ViewTransformInverse; } }
		
		public float3 ViewOrigin { get { return _frustum.GetWorldPosition(this); } }
		public float2 ViewRange { get { return _frustum.GetDepthRange(this); } }
		
		public Ray PointToWorldRay(float2 pointPos)
		{
			return ViewportHelpers.PointToWorldRay(this, _frustumViewport.ViewProjectionTransformInverse, pointPos);
		}
		public Ray WorldToLocalRay(IViewport world, Ray worldRay, Visual where)
		{
			return ViewportHelpers.WorldToLocalRay(this, world, worldRay, where);
		}
		
		IFrustum _frustum;
		
		public FixedViewport( int2 pixelSize, float pixelsPerPoint, IFrustum frustum )
		{
			_frustum = frustum;
			_pixelSize = float2(pixelSize.X,pixelSize.Y);
			_pixelsPerPoint = pixelsPerPoint;
			_frustumViewport.Update(this, frustum);
		}
	}
	
	class InheritViewport : IRenderViewport
	{
		IRenderViewport _baseView;
		FrustumViewport _childView;
		Visual _child;
		
		public InheritViewport( IRenderViewport baseView, FrustumViewport childView, Visual child )
		{
			_baseView = baseView;
			_childView = childView;
			_child = child;
		}
		public float PixelsPerPoint { get { return _baseView.PixelsPerPoint; } }
		
		//in points
		public float2 Size { get { return _baseView.Size; } }
		
		public float2 PixelSize { get { return _baseView.PixelSize; } }
		
		public float4x4 ProjectionTransform { get { return _baseView.ProjectionTransform; } }
		public float4x4 ViewProjectionTransform
		{
			get
			{
				return Matrix.Mul(Matrix.Mul(_childView.LocalViewProjectionTransform,
					_child.WorldTransform), _baseView.ViewProjectionTransform );
			}
		}
		public float4x4 ViewTransform { get { return _baseView.ViewTransform; } }
		public float3 ViewOrigin { get { return _baseView.ViewOrigin; } }
		public float2 ViewRange { get { return _baseView.ViewRange; } }
	}
}
