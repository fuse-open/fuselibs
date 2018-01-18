using Uno;
using Uno.Collections;

using Fuse.Common;
using Fuse.Elements;

namespace Fuse.Drawing
{
	/**
		An object used to refer to a created path.
		
		Each backend should derive from this type. The paths will not be used cross-implementation.
	*/
	abstract public class SurfacePath
	{
	}
	
	/**
		The Surface is a path-based drawing API. A call to `CreatePath` is used to create a path, then one of `StrokePath` or `FillPath` is used to draw it.
		
		This allows the users of `Canvas` to optimize for animation of either the path or the stroke/fill objects independently.
		
		This also keeps the API minimal. There are no convenience functions in this class. Those are provided via higher-level classes, such as `LineSegments` or `SurfaceUtil`.
		
		@experimental
		@advanced
	*/
	abstract public class Surface : IDisposable
	{
		internal object Owner;
		internal Surface()
		{
		}

		protected float2 ElementSize { get; private set; }
		
		public void SetElementSize( float2 size )
		{
			ElementSize = size;
		}
	
		/**
			Frees up all resources associated with this surface. All paths and prepared objects are invalid after a call to this method. However, whethere they are actually freed now, or when `Unprepare` or `DisposePath` is called is undefined. This means it must always be safe to call those two fucntions, even on an disposed Surface.
		*/
		abstract public void Dispose();
		
		/**
			Concatenates a transform to be used for rendering paths (FillPath and StrokePath).
			
			This should really be a 2x3 transform:
				[ M11 M12 ]
				[ M21 M22]
				[ M31 M32 ]
			Only 2D translation, rotation, and scaling need should be supported.
		*/
		
		public abstract void PushTransform( float4x4 transform );
		/**
			Removes the transform added via`PushTransform`
		*/
		public abstract void PopTransform();
		
		/** 
			Creates a pth from the provided list of segments.
		*/
		abstract public SurfacePath CreatePath( IList<LineSegment> segments, FillRule fillRule = FillRule.NonZero );
		
		/**
			Disposes of a path object created by `CreatePath`.
		*/
		abstract public void DisposePath( SurfacePath path );
	
		/**
			Fills the path with the given brush.
			
			This brush must have been passed to `Prepare` previously.
		*/
		abstract public void FillPath( SurfacePath path, Brush fill );
		
		/**
			Strokes the path with the given stroke.
			
			This stroke, and it's brush, must have been passed to `Prepare` previously.
		*/
		abstract public void StrokePath( SurfacePath path, Stroke stroke );
		
		/**
			(TEMPORARY)
			This is the GL entrypoint to start drawing to a framebuffer.
			
			`pixelsPerPoint` is the density to use when converting path points to pixels.
			
			It is undefined if the framebuffer is updated prior to `End` being called.
		*/
		abstract public void Begin(DrawContext dc, framebuffer fb, float pixelsPerPoint);
		
		/**
			Ends drawing. All drawing called after `Begin` and to now must be completed by now. This copies the resulting image to the desired output setup in `Begin`.
		*/
		abstract public void End();
		
		/**
			Prepares this brush for drawing. If this is called a second time with the same `Brush` it indicates the properties of that brush have changed.
		*/
		abstract public void Prepare( Brush brush );
		/**
			Indicates the brush will no longer be used for drawing. It's resources can be freed.
		*/
		abstract public void Unprepare( Brush brush );

		/*
			The GL drawing interface for an element on a DrawContext.
			
			@hide
		*/
		public void Draw( DrawContext dc, Element elm, ISurfaceDrawable drawable )
		{
			if (elm != drawable)
				Fuse.Diagnostics.InternalError( "GLDraw called with mismatched elements", this );
				
			var pixelsPerPoint = elm.Viewport.PixelsPerPoint;
			var bounds = elm.RenderBoundsWithoutEffects;

			const float zeroTolerance = 1e-05f;
			var pixelSize = (int2)Math.Ceil(bounds.Size.XY*pixelsPerPoint - zeroTolerance);
 			var fb = FramebufferPool.Lock(pixelSize.X,pixelSize.Y, Uno.Graphics.Format.RGBA8888, true);
 			
 			Begin(dc, fb, pixelsPerPoint);
 			
			var m = float4x4.Identity;
			m.M41 = -bounds.AxisMin.X;
			m.M42 = -bounds.AxisMin.Y;
			PushTransform(m);
			DrawLocal(drawable);
 			End();

			Blitter.Singleton.Blit(fb.ColorBuffer, new Rect(bounds.AxisMin.XY, (float2)pixelSize / pixelsPerPoint), dc.GetLocalToClipTransform(elm), 1.0f, true);
			FramebufferPool.Release(fb);
		}
		
		/**
			Call this method instead of `drawable.Draw` directly. This will configure the canvas correctly.
			
			This assumes the canvas has been configured to have coordinates local to the drawable already.
		*/
		public void DrawLocal( ISurfaceDrawable drawable )
		{
			//This is needed for brushes as they are relative to the element size.
			SetElementSize(drawable.ElementSize);
			drawable.Draw(this);
		}
	}
	
	/**
		@advanced
		@experimental
	*/
	public interface ISurfaceDrawable
	{
		/**
			The visual should be drawn to this `Surface`.
			
			The `surface` will either be the one provided by `SurfaceManager` during rooting or a compatible sub-surface. The actual drawing should be done via the surface provided here.
		*/
		void Draw(Surface surface);
		
		/**
			Conveys if a surface is the primary method for drawing, or whether it can be drawn without using the surface (such as a Panel's background).
			
			@experimental It's not clear what Rectangle/Circle should return, it's false if on GL since they can draw without a surface, but false if in a NativeView. For now they'll ignore the GL aspect and just return true: that drawing path doesn't use this function anyway. This problem is that same as the TODO about `Shape.NeedSurface` in Shape.uno
		*/
		bool IsPrimary { get; }
		
		/**
			The size of the element being drawn. Maps to `ElementSize` on elements.
		*/
		float2 ElementSize { get; }
	}
	
}
