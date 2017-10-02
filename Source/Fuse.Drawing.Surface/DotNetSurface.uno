using Uno;
using Uno.Collections;
using Uno.IO;
using Uno.Graphics;
using Uno.Compiler.ExportTargetInterop;
using Uno.Runtime.InteropServices;
using OpenGL;
using Fuse.Resources;

using Fuse.Elements;

namespace Fuse.Drawing
{
	using DotNetNative;
	/**
		An object used to refer to a created path.
		
		Each backend should derive from this type. The paths will not be used cross-implementation.
	*/
	extern(DOTNET)
	class DotNetCanvasPath : SurfacePath
	{
		public FillRule FillRule;
		public DotNetGraphicsPath Path;
	}
	
	/**
		The Surface is a path-based drawing API. A call to `CreatePath` is used to create a path, then one of `StrokePath` or `FillPath` is used to draw it.
		
		This allows the users of `Canvas` to optimize for animation of either the path or the stroke/fill objects independently.
		
		This also keeps the API minimal. There are no convenience functions in this class. Those are provided via higher-level classes, such as `LineSegments` or `SurfaceUtil`.
	*/
	
	[Require("Assembly", "System.Drawing.dll")]
	[extern(DOTNET) Require("Source.Include","XliPlatform/GL.h")]
	extern(DOTNET)
	internal class DotNetSurface : Surface
	{
		DrawContext _drawContext;
		framebuffer _buffer;
		float _pixelsPerPoint;
		float2 _size;
		OpenGL.GLTextureHandle _GLTextureHandle;
		
		Bitmap _bitmap;
		DotNetGraphics _graphics;
		List<DotNetNative.Matrix> _transformStates = new List<DotNetNative.Matrix>();


		public DotNetSurface()
		{
		}

		/**
			Frees up all resources associated with this surface, including paths and prepared objects.
			This surface cannot be used after `Dispose` is called, nor can any of the created paths.
		*/
		public override void Dispose()
		{
			// make sure to free the pinned array for each brush
			foreach (var item in _imageBrushes)
			{
				item.Value.Item1.Dispose();
				item.Value.Item2.Free();
			}
			_imageBrushes.Clear();

			foreach (var item in _tiledImages)
			{
				item.Value.Dispose();
			}

			_tiledImages.Clear();
			
			if (_graphics != null)
			{
				_graphics.Dispose();
				_graphics = null;
			}
			
			if (_bitmap != null)
			{
				_bitmap.Dispose();
				_bitmap = null;
			}
		}
		
		/**
			Concatenates a transform to be used for rendering paths (FillPath and StrokePath).
			
			This should really be a 2x3 transform:
				[ M11 M12 ]
				[ M21 M22 ]
				[ M31 M32 ]
			Only 2D translation, rotation, and scaling need should be supported.
		*/
		public override void PushTransform( float4x4 t )
		{
			VerifyBegun();
			var state = _graphics.Transform.Clone();
			_transformStates.Add(state);

			_graphics.MultiplyTransform(new DotNetNative.Matrix(t.M11, t.M12, t.M21, t.M22, 
				t.M41 * _pixelsPerPoint, t.M42 * _pixelsPerPoint), MatrixOrder.Prepend);
		}

		/**
			Removes the transform added via`PushTransform`
		*/
		public override void PopTransform()
		{
			VerifyBegun();

			var state = _transformStates[_transformStates.Count - 1];
			_graphics.Transform = state.Clone();
			_transformStates.RemoveAt(_transformStates.Count - 1);
		}
		
		/** 
			Creates a pth from the provided list of segments.
		*/
		public override SurfacePath CreatePath( IList<LineSegment> segments, FillRule fillRule = FillRule.NonZero )
		{
			var path = new DotNetGraphicsPath();
			AddSegments( path, segments, float2(0) );

			return new DotNetCanvasPath{ Path = path, FillRule = fillRule };
		}
		
		/**
			Disposes of a path object created by `CreatePath`.
		*/
		public override void DisposePath( SurfacePath path )
		{
			var cgPath = (DotNetCanvasPath)path;

			if (cgPath.Path == null)
			{
				Fuse.Diagnostics.InternalError( "Duplicate dispose of SurfacePath", path );
				return;
			}
			
			cgPath.Path.Dispose();
			cgPath.Path = null;
		}
	
		/**
			Fills the path with the given brush.
			
			This brush must have been passed to `Prepare` previously.
		*/
		public override void FillPath( SurfacePath path, Brush fill )
		{
			VerifyBegun();
			var actualPath = (DotNetCanvasPath)path;

			var graphicsPath = actualPath.Path.GetGraphicsPath();
			if (DotNetHelpers.IsEmptyPath(graphicsPath))
				return;

			bool eoFill = actualPath.FillRule == FillRule.EvenOdd;
			// set the path filling mode
			DotNetHelpers.SetEOFill(graphicsPath, eoFill);

			var solidColor = fill as ISolidColor;
			if (solidColor != null)
			{	
				DotNetHelpers.FillPathSolidColor(_graphics, graphicsPath, DotNetHelpers.ColorFromFloat4(solidColor.Color));
				return;
			}

			var linearGradient = fill as LinearGradient;
			if (linearGradient != null)
			{
				var ends = linearGradient.GetEffectiveEndPoints(ElementSize) * _pixelsPerPoint;

				DotNetHelpers.FillPathLinearGradient(_graphics, graphicsPath, linearGradient, ends[0], ends[1], ends[2], ends[3]);
				return;
			}
			
			var imageFill = fill as ImageFill;
			if (imageFill != null)
			{
				Tuple<Bitmap, GCHandle> bitPair;
				Bitmap image;
				if (!_imageBrushes.TryGetValue( fill, out bitPair ) )
				{
					Fuse.Diagnostics.InternalError( "Unprepared ImageFill", fill );
					return;
				}
				image = bitPair.Item1;
				
				var sizing = imageFill.SizingContainer;
				sizing.absoluteZoom = _pixelsPerPoint; 
				var imageSize = imageFill.Source.Size;
				var scale = sizing.CalcScale( ElementSize, imageSize );
				var origin = sizing.CalcOrigin( ElementSize, imageSize * scale );
				
				var tileSize = imageSize * _pixelsPerPoint * scale;
				var pixelOrigin = origin * _pixelsPerPoint;
				
				DotNetHelpers.FillPathImage(
					_graphics, graphicsPath, 
					image, pixelOrigin.X, pixelOrigin.Y, 
					tileSize.X, tileSize.Y, 
					ElementSize.X * _pixelsPerPoint, ElementSize.Y * _pixelsPerPoint
				);

				return;
			}

			Fuse.Diagnostics.UserError( "Unsupported brush", fill );
		}
		

		Dictionary<Tuple<Brush, Int, Int>, Bitmap> _tiledImages = new Dictionary<Tuple<Brush, Int, Int>, Bitmap>();

		/**
			Strokes the path with the given stroke.
			
			This stroke, and it's brush, must have been passed to `Prepare` previously.
		*/
		public override void StrokePath( SurfacePath path, Stroke stroke )
		{
			// TODO: this is definitely wrong, just doing this for now so I can see it show up

			VerifyBegun();
			var actualPath = (DotNetCanvasPath)path;

			var graphicsPath = actualPath.Path.GetGraphicsPath();
			if (DotNetHelpers.IsEmptyPath(graphicsPath))
				return;

			bool eoFill = actualPath.FillRule == FillRule.EvenOdd;
			// set the path filling mode
			DotNetHelpers.SetEOFill(graphicsPath, eoFill);

			var fill = stroke.Brush;


			var solidColor = fill as ISolidColor;
			if (solidColor != null)
			{
				DotNetHelpers.StrokePathSolidColor(
					_graphics, 
					graphicsPath, 
					DotNetHelpers.ColorFromFloat4(solidColor.Color), 
					stroke.Width, 
					stroke.LineJoinMiterLimit, 
					stroke.LineJoin,
					stroke.LineCap
				);
				return;
			}

			var linearGradient = fill as LinearGradient;
			if (linearGradient != null)
			{
				var ends = linearGradient.GetEffectiveEndPoints(ElementSize) * _pixelsPerPoint;

				DotNetHelpers.StrokePathLinearGradient(
					_graphics, 
					graphicsPath, 
					linearGradient, 
					ends[0], 
					ends[1], 
					ends[2], 
					ends[3], 
					stroke.Width, 
					stroke.LineJoinMiterLimit,
					stroke.LineJoin,
					stroke.LineCap
				);

				return;
			}

			var imageFill = fill as ImageFill;
			if (imageFill != null)
			{
				var sizing = imageFill.SizingContainer;
				sizing.absoluteZoom = _pixelsPerPoint; 
				var imageSize = imageFill.Source.Size;
				var scale = sizing.CalcScale( ElementSize, imageSize );
				var origin = sizing.CalcOrigin( ElementSize, imageSize * scale );
				
				var tileSize = imageSize * _pixelsPerPoint * scale;
				var pixelOrigin = origin * _pixelsPerPoint;

				var tileSizeX = (int)tileSize.X;
				var tileSizeY = (int)tileSize.Y;
				var tuple = Tuple.Create(fill, tileSizeX, tileSizeY);
				Bitmap newImage;

				if (!_tiledImages.TryGetValue(tuple, out newImage))
				{
					Tuple<Bitmap, GCHandle> bitPair;
					Bitmap image;
					if (!_imageBrushes.TryGetValue( fill, out bitPair ) )
					{
						Fuse.Diagnostics.InternalError( "Unprepared ImageFill", fill );
						return;
					}
					image = bitPair.Item1;
					
					newImage = new Bitmap(image, tileSizeX, tileSizeY);
					_tiledImages[tuple] = newImage;
				}

				DotNetHelpers.StrokePathImage(
					_graphics, graphicsPath, 
					newImage,
					pixelOrigin.X, pixelOrigin.Y,
					stroke.Width, 
					stroke.LineJoinMiterLimit,
					stroke.LineJoin,
					stroke.LineCap
				);

				return;
			}

			Fuse.Diagnostics.UserError( "Unsupported stroke brush", fill );
		}

		public override void Begin(DrawContext dc, framebuffer fb, float pixelsPerPoint)
		{
			_drawContext = dc;
			_buffer = fb;
			_pixelsPerPoint = pixelsPerPoint;

			_size = (float2)fb.Size;

			_bitmap = new Bitmap(fb.Size.X, fb.Size.Y, PixelFormat.Format32bppPArgb);

			_graphics = DotNetGraphics.FromImage(_bitmap);
			_graphics.SmoothingMode = SmoothingMode.AntiAlias;

			// Our coordinate system is upside down
			_graphics.TranslateTransform(0, fb.Size.Y);
			_graphics.ScaleTransform(1, -1);

			_GLTextureHandle = fb.ColorBuffer.GLTextureHandle;
		}

		
		/**
			Ends drawing. All drawing called after `Begin` and to now must be completed by now. This copies the resulting image to the desired output setup in `Begin`.
		*/
		public override void End()
		{
			Rectangle rect = new Rectangle(0, 0, _bitmap.Width, _bitmap.Height);
			var bitmapData = _bitmap.LockBits(rect, ImageLockMode.ReadOnly, _bitmap.PixelFormat);
			IntPtr ptr = bitmapData.Scan0;
			int bytes  = Math.Abs(bitmapData.Stride) * _bitmap.Height;
			byte[] rgbValues = new byte[bytes];
			byte[] outputValues = new byte[bytes];

			Marshal.Copy(ptr, rgbValues, 0, bytes);

			// copy the bulk of pixels
			for (var i = 0; i < bytes; i += 1)
			{
				outputValues[i] = rgbValues[i];
			}

			// swap R and B
			for (var i = 0; i < bytes; i += 4)
			{
				outputValues[i + 2] = rgbValues[i];
				outputValues[i] = rgbValues[i + 2];
			}

			DotNetHelpers.Render(_size, new Buffer(outputValues), _GLTextureHandle);
			_bitmap.UnlockBits(bitmapData);
		}
		

		/**
			Prepares this brush for drawing. If this is called a second time with the same `Brush` it indicates the properties of that brush have changed.
		*/
		public override void Prepare( Brush brush )
		{
			VerifyCreated();
			Unprepare(brush);
			if (brush is ISolidColor)
				return;
			else if (brush is LinearGradient)
				return;
			else if (brush is ImageFill)
				PrepareImageFill(brush as ImageFill);
			else
				Fuse.Diagnostics.UserError( "Unsupported brush", brush );
		}
		/**
			Indicates the brush will no longer be used for drawing. It's resources can be freed.
		*/
		public override void Unprepare( Brush brush )
		{
			Tuple<Bitmap, GCHandle> image;
			if (_imageBrushes.TryGetValue( brush, out image ))
			{
				VerifyCreated();
				image.Item1.Dispose();
				image.Item2.Free();
				_imageBrushes.Remove(brush);
			}
		}


		float2 PixelFromPoint( float2 point )
		{
			return point * _pixelsPerPoint;
		}

		/* prevPoint _must_ be multipled by `_pixelsPerPoint` before being passed here
		*/
		List<LineSegment> _temp = new List<LineSegment>();
		float2 AddSegments( DotNetGraphicsPath path, IList<LineSegment> segments, float2 prevPoint )
		{
			for (int i=0; i < segments.Count; ++i )
			{
				var seg = segments[i];
				var to = PixelFromPoint(seg.To);

				switch (seg.Type)
				{
					case LineSegmentType.Move:
						path.CloseFigure();
						prevPoint = to;
						break;
						
					case LineSegmentType.Straight:
						path.AddLine(prevPoint, to);
						prevPoint = to;
						break;
						
					case LineSegmentType.BezierCurve:
					{
						var a = PixelFromPoint(seg.A);
						var b = PixelFromPoint(seg.B);
						path.CurveTo(prevPoint, a, b, to);
						prevPoint = to;
						break;
					}
					
					case LineSegmentType.EllipticArc:
					{
						_temp.Clear();
						SurfaceUtil.EllipticArcToBezierCurve(prevPoint / _pixelsPerPoint, seg, _temp);
						prevPoint = AddSegments( path, _temp, prevPoint );
						break;
					}
					
					case LineSegmentType.Close:
					{
						path.CloseFigure();
						prevPoint = to;
						break;
					}
				}
			}
			
			return prevPoint;
		}

		Dictionary<Brush, Tuple<Bitmap, GCHandle>> _imageBrushes = new Dictionary<Brush, Tuple<Bitmap, GCHandle>>();
		void PrepareImageFill( ImageFill img )
		{
			var src = img.Source;
			var tex = src.GetTexture();

			//probably still loading
			if (tex == null) return;

			var fb = FramebufferPool.Lock( src.PixelSize, Uno.Graphics.Format.RGBA8888, false );

			//TODO: this is not entirely correct since _drawContext could be null now -- but it isn't
			//in any of our use cases, but the contract certainly allows for it
			_drawContext.PushRenderTarget(fb);
			DrawImageFill(tex);
			var imageRef = LoadImage(src.PixelSize.X, src.PixelSize.Y );
			FramebufferPool.Release(fb);
			_drawContext.PopRenderTarget();
			
			_imageBrushes[img] = imageRef;
		}


		static Tuple<Bitmap, GCHandle> LoadImage(int width, int height)
		{
			int size = width * height * 4;
			var pixelData = new byte[size];

			GL.PixelStore(GLPixelStoreParameter.PackAlignment, 1);
			GL.ReadPixels(0,0, width, height, GLPixelFormat.Rgba, GLPixelType.UnsignedByte, pixelData);

			// flip r and b
			for (var i = 0; i < size; i += 4)
			{
				var a = pixelData[i];
				var b = pixelData[i + 2];
				pixelData[i] = b;
				pixelData[i + 2] = a;
			}

			var handle = GCHandle.Alloc(pixelData, GCHandleType.Pinned);
			IntPtr buffer =  Marshal.UnsafeAddrOfPinnedArrayElement((CilArray)(object)pixelData, 0);

			var image = new Bitmap(width, height, width * 4, PixelFormat.Format32bppPArgb, buffer);			

			return Tuple.Create(image, handle);
		}

		public void DrawImageFill( texture2D texture )
		{
			draw
			{
				float2[] Vertices: new []
				{
					float2(0, 0), float2(1, 0), float2(1, 1),
					float2(1, 1), float2(0, 1), float2(0, 0)
				};
				float2 VertexData: vertex_attrib(Vertices);
				VertexCount : 6;

				ClipPosition: float4(VertexData*2 -1, 0,1);

				DepthTestEnabled: false;
				PixelColor: sample(texture, float2(VertexData.X,1-VertexData.Y), Uno.Graphics.SamplerState.LinearClamp);
			};
		}

		void VerifyCreated()
		{
			if (_graphics == null)
				throw new Exception( "Object disposed" );
		}
		
		void VerifyBegun()
		{
			if (_buffer == null)
				throw new Exception( "Surface.Begin was not called" );
		}
	}


	extern(DOTNET) internal class DotNetHelpers
	{
		public static Point PointFromFloat2(float2 point)
		{
			return new Point((int)point.X, (int)point.Y);
		}

		public static PointF PointFFromFloat2(float2 point)
		{
			return new PointF(point.X, point.Y);
		}

		/** Render a given buffer into a size window on the given GLBuffer 

		*/
		public static extern void Render (float2 size, Buffer buffer, OpenGL.GLTextureHandle GLBuffer)
		{
			GL.BindTexture(GLTextureTarget.Texture2D, GLBuffer);
			GL.PixelStore(GLPixelStoreParameter.UnpackAlignment, 1);
			GL.TexImage2D(
				GLTextureTarget.Texture2D, 0, 
				GLPixelFormat.Rgba, (int)size.X, (int)size.Y, 0, 
				GLPixelFormat.Rgba, GLPixelType.UnsignedByte, 
				buffer
			);
			return;
		}

		public static extern bool IsEmptyPath(GraphicsPath path)
		{
			return path.GetBounds().Width == 0 && path.GetBounds().Height == 0;
		}

		public static extern void SetEOFill(GraphicsPath path, bool eoFill)
		{
			path.FillMode = eoFill ? FillMode.Alternative : FillMode.Winding;
		}

		static float mapPoint(float value, float leftMin, float leftMax, float rightMin, float rightMax)
		{

			var leftSpan = leftMax - leftMin;
			var rightSpan = rightMax - rightMin;
			var valueScaled = (value - leftMin) / leftSpan;

			return rightMin + (valueScaled * rightSpan);
		}

		/* identify the start and end of the gradient, along with the start of bounds and end of bounds
		*/
		static float4 CalcGradientPoints(RectangleF bounds, float startX, float startY, float endX, float endY) 
		{
			var finalBoundX = bounds.X + bounds.Width;
			var finalBoundY = bounds.Y + bounds.Height;

			var xDiff = endX - startX;
			var yDiff = endY - startY;

			// this is the "best case" gradient of the line
			// in the cases where the diff is not best case, we adjust it
			// accordingly 
			var finalBoundDiff = xDiff / yDiff;

			// this is the point the gradient _should_ start at
			// Sometimes it may not if the gradient only goes in one direction, or equally in two directions
			var startBoundPoint = - ( (finalBoundDiff * bounds.X) - bounds.Y  );
			var endBoundPoint = - ( (finalBoundDiff * (bounds.X + bounds.Width)) - (bounds.Y + bounds.Height));


			// when our gradient only changes in the y
			if (Math.Round(xDiff) == 0)
			{
				finalBoundDiff = 0;
				startBoundPoint = bounds.Y;
				endBoundPoint = bounds.Y + bounds.Height;
			} 
			// when our gradient only changes in the x
			else if (Math.Round(yDiff) == 0)
			{
				finalBoundDiff = 0;
				startBoundPoint = bounds.X;
				endBoundPoint = bounds.X + bounds.Width;
			}
			// when our gradient goes equally in X and Y
			else if (Math.Round(finalBoundDiff) == 1) 
			{
				finalBoundDiff = 0;

				// this should not matter, but accounts for rounding errors that may occur
				if (yDiff <= xDiff)
				{
					startBoundPoint = startY;
					endBoundPoint = endY;
				}
				else 
				{
					startBoundPoint = startX;
					startBoundPoint = endX;
				}
			}
			else 
			{
				// catch either bound point being 0 - default to X
				if (startBoundPoint == 0)
				{
					startBoundPoint = startX;
				}

				if (endBoundPoint == 0)
				{
					endBoundPoint = endX;
				}	
			}


			var gradientStartPoint = - ( (finalBoundDiff * startX) - startY);
			var gradientEndPoint = - ( (finalBoundDiff * endX) - endY);

			// when we failed to calculate the right gradient start point
			if (gradientStartPoint == 0)
			{
				gradientStartPoint = xDiff == 0 ? startY : startX;
			} 

			if (gradientEndPoint == 0)
			{
				gradientEndPoint = xDiff == 0 ? endY : endX;
			}

			return float4(gradientStartPoint, gradientEndPoint, startBoundPoint, endBoundPoint);
		}

		static ColorBlend CreateColorBlend(LinearGradient lg, RectangleF bounds, float startX, float startY, float endX, float endY)
		{

			var calculatedPoints = CalcGradientPoints(bounds, startX, startY, endX, endY);

			var stops = lg.SortedStops;

			// we have 2 extra points, one at each end. This enables clamping
			var numberOfColorPoints = stops.Length + 2;

			var colors = new DotNetNative.Color[numberOfColorPoints];
			var offsets	= new float[numberOfColorPoints];

			// our first color always has an offset of 0
			var firstColor = ColorFromFloat4(stops[0].Color);
			colors[0] = firstColor;
			offsets[0] = 0;

			// our last color must always have an offset of 1
			var endColor = ColorFromFloat4(stops[stops.Length - 1].Color);
			colors[numberOfColorPoints - 1] = endColor;
			offsets[numberOfColorPoints - 1] = 1.0f;


			for (int i=0; i < stops.Length; ++i)
			{
				var stop = stops[i];

				// our indexes in the storing array are offset by 1
				// since we have manually filled the first spot
				colors[i + 1] = ColorFromFloat4(stop.Color);
				offsets[i + 1] = stop.Offset;

				// map the point between the two gradient coordinates
				var mappedPoint = mapPoint(stop.Offset, 0, 1, calculatedPoints.X, calculatedPoints.Y);
				// then map it onto the entire line of the path bounds
				var backMapped = mapPoint(mappedPoint, calculatedPoints.Z, calculatedPoints.W, 0, 1);

				offsets[i + 1] = backMapped;
			}

			ColorBlend blend = new ColorBlend();
			blend.Positions = offsets; 
			blend.Colors = colors; 

			return blend;
		}

		/** Strokes a path with a solid color and the given settings

			Does nothing if the path has no width or height
		*/
		public static extern void StrokePathSolidColor(
			DotNetGraphics graphics, GraphicsPath path, 
			DotNetNative.Color color, float width, 
			float miterLimit, 
			LineJoin lineJoin, LineCap lineCap
		)
		{
			var bounds = path.GetBounds();
			bounds.Inflate(width, width);
			if (bounds.IsEmpty)
				return;

			SolidBrush brush = new SolidBrush(color);
			Pen pen = new Pen(brush, width);
			pen.MiterLimit = miterLimit;
			pen.LineJoin = DotNetHelpers.LineJoinToDotNet(lineJoin);
			pen.StartCap = DotNetHelpers.LineCapToDotNet(lineCap);
			pen.EndCap = DotNetHelpers.LineCapToDotNet(lineCap);

			graphics.SetClip(bounds, CombineMode.Replace);
			graphics.SmoothingMode = SmoothingMode.AntiAlias;
			graphics.DrawPath(pen, path);
			brush.Dispose();
		}

		public static extern void StrokePathImage(
			DotNetGraphics graphics, GraphicsPath path, 
			Bitmap image, 
			float originX, float originY,
			float width,
			float miterLimit, 
			LineJoin lineJoin, LineCap lineCap
		)
		{
			var bounds = path.GetBounds();
			bounds.Inflate(width, width);
			if (bounds.IsEmpty)
				return;

			var brush = new TextureBrush(image, DotNetWrapMode.Tile);
			
			brush.ScaleTransform(1, -1);
			brush.TranslateTransform(originX, originY);

			Pen pen = new Pen(brush, width);
			pen.MiterLimit = miterLimit;
			pen.LineJoin = DotNetHelpers.LineJoinToDotNet(lineJoin);
			pen.StartCap = DotNetHelpers.LineCapToDotNet(lineCap);
			pen.EndCap = DotNetHelpers.LineCapToDotNet(lineCap);

			graphics.SetClip(bounds, CombineMode.Replace);
			graphics.SmoothingMode = SmoothingMode.AntiAlias;
			graphics.DrawPath(pen, path);

			brush.Dispose();
		}

		/** Stroke a path with a linear color. 

			Does nothing if the path has no width or height
		*/
		public static extern void StrokePathLinearGradient(
			DotNetGraphics graphics, GraphicsPath path, 
			LinearGradient lg, 
			float startX, float startY, 
			float endX, float endY, 
			float width, float miterLimit, 
			LineJoin lineJoin, LineCap lineCap
		)
		{
			var bounds = path.GetBounds();
			bounds.Inflate(width, width);
			if (bounds.IsEmpty)
				return;

			var state = graphics.Save();
			ColorBlend blend = CreateColorBlend(lg, bounds, startX, startY, endX, endY);

			var brush = new LinearGradientBrush(
				new PointF(bounds.X, bounds.Y),
				new PointF(bounds.X + bounds.Width, bounds.Y + bounds.Height),
				DotNetNative.Color.Black,
				DotNetNative.Color.Black
			);

			brush.InterpolationColors = blend;
			
			Pen pen = new Pen(brush, width);
			pen.MiterLimit = miterLimit;
			pen.LineJoin = DotNetHelpers.LineJoinToDotNet(lineJoin);
			pen.StartCap = DotNetHelpers.LineCapToDotNet(lineCap);
			pen.EndCap = DotNetHelpers.LineCapToDotNet(lineCap);
			
			graphics.SetClip(bounds, CombineMode.Replace);
			graphics.SmoothingMode = SmoothingMode.AntiAlias;
			graphics.DrawPath(pen, path);

			brush.Dispose();
			graphics.Restore(state);
		}
		
		public static extern void FillPathSolidColor(DotNetGraphics graphics, GraphicsPath path, DotNetNative.Color color) 
		{
			SolidBrush brush = new SolidBrush(color);

			graphics.ResetClip();
			graphics.SmoothingMode = SmoothingMode.AntiAlias;
			graphics.FillPath(brush, path);

			brush.Dispose();
		}
		
		public static extern void FillPathLinearGradient(
			DotNetGraphics graphics, GraphicsPath path, 
			LinearGradient lg, 
			float startX, float startY, 
			float endX, float endY
		)
		{
			var bounds = path.GetBounds();
			if (bounds.IsEmpty)
				return;

			var blend = CreateColorBlend(lg, bounds, startX, startY, endX, endY);

			var startPoint = new PointF(bounds.X, bounds.Y);
			var endPoint = new PointF(bounds.X + bounds.Width, bounds.Y + bounds.Height);

			// when our gradient is only in the Y 
			if (startX == endX)
			{
				startPoint = new PointF(0, bounds.Y);
				endPoint = new PointF(0, bounds.Y + bounds.Height);
			} 
			// when our gradient is only in the X
			else if (startY == endY)
			{
				startPoint = new PointF(bounds.X, 0);
				endPoint = new PointF(bounds.X + bounds.Width, 0);
			}

			var brush = new LinearGradientBrush(
				startPoint,
				endPoint,
				DotNetNative.Color.Black,
				DotNetNative.Color.Black
			);

			brush.InterpolationColors = blend;
			graphics.SetClip(bounds, CombineMode.Replace);
			
			var state = graphics.Save();
			graphics.SmoothingMode = SmoothingMode.AntiAlias;
			graphics.FillPath(brush, path);

			graphics.Restore(state);

			brush.Dispose();
		}


		public static void FillPathImage(
			DotNetGraphics graphics, GraphicsPath path, Bitmap image, 
			float originX, float originY, 
			float tileSizeX, float tileSizeY,
			float width, float height
			)
		{
			var bounds = path.GetBounds();
			if (bounds.IsEmpty)
				return;

			var newImage = new Bitmap(image, (int)tileSizeX, (int)tileSizeY);

			var brush = new TextureBrush(newImage, DotNetWrapMode.Tile);
			brush.ScaleTransform(1, -1);
			brush.TranslateTransform(originX, originY);

			graphics.SetClip(bounds, CombineMode.Replace);
			graphics.FillPath(brush, path);
			brush.Dispose();
			newImage.Dispose();
		}


		public static DotNetLineJoin LineJoinToDotNet(LineJoin lj)
		{
			switch (lj)
			{
				case LineJoin.Miter:
					return DotNetLineJoin.Miter;

				case LineJoin.Round:
					return DotNetLineJoin.Round;

				case LineJoin.Bevel:
					return DotNetLineJoin.Bevel;
			}

			return DotNetLineJoin.Miter;
		}

		public static DotNetLineCap LineCapToDotNet(LineCap lc)
		{
			switch (lc)
			{
				case LineCap.Butt:
					return DotNetLineCap.Flat;

				case LineCap.Round:
					return DotNetLineCap.Round;

				case LineCap.Square:
					return DotNetLineCap.Square;
			}

			return DotNetLineCap.Flat;
		}

		public static DotNetNative.Color ColorFromFloat4(float4 color)
		{
			return DotNetNative.Color.FromArgb((int)Uno.Color.ToArgb(color));
		}
	}

	extern (DOTNET) internal class DotNetGraphicsPath
	{
		GraphicsPath _internalGraphicsPath; 

		public DotNetGraphicsPath ()
		{
			_internalGraphicsPath = new GraphicsPath();
		}

		public void AddLine(float2 prevPoint, float2 newPoint)
		{
			AddLine(DotNetHelpers.PointFFromFloat2(prevPoint), DotNetHelpers.PointFFromFloat2(newPoint));
		}

		public void AddLine(PointF prevPoint, PointF newPoint)
		{
			_internalGraphicsPath.AddLine(prevPoint, newPoint);
		}


		public void CurveTo(float2 startPoint, float2 point1, float2 point2, float2 endPoint)
		{
			_internalGraphicsPath.AddBezier(
				DotNetHelpers.PointFFromFloat2(startPoint), 
				DotNetHelpers.PointFFromFloat2(point1), 
				DotNetHelpers.PointFFromFloat2(point2),
				DotNetHelpers.PointFFromFloat2(endPoint) 
			);
		}


		public void CloseFigure()
		{
			_internalGraphicsPath.CloseFigure();
		}

		public void StartFigure()
		{
			_internalGraphicsPath.StartFigure();
		}

		public GraphicsPath GetGraphicsPath()
		{
			return _internalGraphicsPath;
		}

		public void Dispose()
		{
			_internalGraphicsPath.Dispose();
		}

		public void CloseAllFigures()
		{
			_internalGraphicsPath.CloseAllFigures();
		}	
	}

	namespace DotNetNative
	{

		[DotNetType("System.Drawing.Imaging.ImageFormat")]
		extern(DOTNET) internal class ImageFormat
		{
			public static extern ImageFormat Bmp { get; }
		}

		[DotNetType("System.Drawing.Drawing2D.GraphicsPath")]
		extern(DOTNET) internal class GraphicsPath
		{
			public extern GraphicsPath();
			public extern GraphicsPath(FillMode fillMode);
			public extern void AddLine(Point a, Point b);
			public extern void AddLine(PointF a, PointF b);
			public extern void AddPath(GraphicsPath path, bool connect);
			public extern void StartFigure();
			public extern void CloseFigure();
			public extern void AddBezier(Point pt1, Point pt2, Point pt3, Point pt4);
			public extern void AddBezier(PointF pt1, PointF pt2, PointF pt3, PointF pt4);
			public extern void Dispose();
			public extern FillMode FillMode { get; set; }
			public extern PointF[] PathPoints { get; }
			public extern RectangleF GetBounds();
			public extern void CloseAllFigures();
			public extern void Widen(Pen pen);
			public extern object Clone();
		}

		[DotNetType("System.Drawing.Drawing2D.FillMode")]
		extern(DOTNET) internal enum FillMode
		{
			Alternative = 0,
			Winding = 1,
		}

		[DotNetType("System.Drawing.Imaging.PixelFormat")]
		extern(DOTNET) internal enum PixelFormat
		{
			Format32bppArgb = 2498570,
			Format32bppPArgb = 925707,
			Format32bppRgb = 139273,
			PAlpha = 524288,
			Alpha = 262144
		}

		[DotNetType("System.Drawing.Drawing2D.WrapMode")]
		extern(DOTNET) internal enum DotNetWrapMode
		{
			Tile = 0,
			TileFlipX = 1,
			TileFlipY = 2,
			TileFlipXY = 3,
			Clamp = 4
		}

		[DotNetType("System.Drawing.Brush")]
		extern(DOTNET) internal abstract class DotNetBrush
		{
			public abstract extern void Dispose();
		}

		[DotNetType("System.Drawing.TextureBrush")]
		extern(DOTNET) internal class TextureBrush : DotNetBrush
		{
			public extern TextureBrush(Image image);
			public extern TextureBrush(Image image, Rectangle rect);
			public extern TextureBrush(Image image, RectangleF rect);
			public extern TextureBrush(Image image, DotNetWrapMode wrapMode);
			public extern TextureBrush(Image image, DotNetWrapMode wrapMode, RectangleF rect);
			public extern void TranslateTransform(float dx,float dy);
			public extern void ScaleTransform(float dx,float dy);

			public override extern void Dispose();
		}
				

		[DotNetType("System.Drawing.Drawing2D.LinearGradientBrush")]
		extern(DOTNET) internal class LinearGradientBrush : DotNetBrush
		{
			public extern LinearGradientBrush(Point point1,Point point2, Color color1, Color color2);
			public extern LinearGradientBrush(PointF point1,PointF point2, Color color1, Color color2);
			public extern LinearGradientBrush(RectangleF rect, Color color1, Color color2, float angle, bool isAngleScaleable);
			public extern ColorBlend InterpolationColors { get; set; }
			public extern Color[] LinearColors { get; set; }
			public extern DotNetWrapMode WrapMode { get; set; }
			public extern Matrix Transform { get; set; }
			public extern void RotateTransform(float angle);
			public extern void MultiplyTransform(Matrix matrix);
			public override extern void Dispose();
		}

		[DotNetType("System.Drawing.Drawing2D.PathGradientBrush")]
		extern(DOTNET) internal class PathGradientBrush  : DotNetBrush
		{
			public extern PathGradientBrush(Point[] points);
			public extern PathGradientBrush(GraphicsPath path);
			public extern ColorBlend InterpolationColors { get; set; }
			public extern Color[] SurroundColors { get; set; }
			public override extern void Dispose();
		}
				

		[DotNetType("System.Drawing.SolidBrush")]
		extern(DOTNET) internal class SolidBrush : DotNetBrush
		{
			public extern SolidBrush(Color color);
			public override extern void Dispose();
		}

		[DotNetType("System.Drawing.Image")]
		extern(DOTNET) internal class Image
		{
		}

		[DotNetType("System.Drawing.Bitmap")]
		extern(DOTNET) internal class Bitmap : Image
		{
			public extern Bitmap (int width, int height);
			public extern Bitmap (Bitmap bitmap, int width, int height);
			public extern Bitmap (int width, int height, PixelFormat format);
			public extern Bitmap(Stream stream);
			public extern Bitmap(int width, int height, int stride, PixelFormat format, IntPtr scan0);
			public extern int Width { get; }
			public extern int Height { get; }
			public extern void Save(Stream stream, ImageFormat format);
			public extern void Dispose();
			public extern PixelFormat PixelFormat { get; }
			public extern BitmapData LockBits( Rectangle rect, ImageLockMode flags, PixelFormat format );
			public extern void UnlockBits(BitmapData bitmapdata);
			public extern void SetResolution(float xDpi, float yDpi);
		}

		[DotNetType("System.Drawing.Imaging.BitmapData")]
		extern(DOTNET) internal class BitmapData
		{
			// constructors
			public extern BitmapData();


			// properties
			public extern int Height { get; set; }
			public extern PixelFormat PixelFormat { get; set; }
			public extern IntPtr Scan0 { get; set; }
			public extern int Stride { get; set; }
			public extern int Width { get; set; }
		}


		[DotNetType("System.Drawing.Graphics")]
		extern(DOTNET) internal class DotNetGraphics
		{
			public static extern DotNetGraphics FromImage (Bitmap bitmap);
			public extern void DrawPath(Pen pen, GraphicsPath path);
			public extern void DrawImage(Bitmap bitmap, RectangleF rect);
			public extern void DrawRectangle(Pen pen, float x, float y, float width, float height);
			public extern void DrawLine(Pen pen, float x, float y, float width, float height);
			public extern void FillPolygon(DotNetBrush brush, Point[] points);
			public extern void FillPolygon(DotNetBrush brush, PointF[] points);
			public extern void FillPath(DotNetBrush brush, GraphicsPath path);
			public extern void FillRectangle(DotNetBrush brush, RectangleF rect);
			public extern void FillRectangle(DotNetBrush brush, Rectangle rect);
			public extern void Clear(Color color);
			public extern void Dispose();
			public extern GraphicsState Save();
			public extern void Restore(GraphicsState state);
			public extern void MultiplyTransform(Matrix matrix);
			public extern void MultiplyTransform(Matrix matrix, MatrixOrder order);
			public extern void SetClip (GraphicsPath path);
			public extern void SetClip (GraphicsPath path, CombineMode combineMode);
			public extern void SetClip (RectangleF bounds, CombineMode combineMode);
			public extern void ResetClip ();
			public extern void ScaleTransform(float sx, float sy);
			public extern void TranslateTransform(float dx, float dy);
			public extern void ResetTransform();
			public extern SmoothingMode SmoothingMode { get; set; }
			public extern Matrix Transform { get; set; }
			public GraphicsUnit PageUnit { get; set; }
			public extern void RotateTransform(float angle);
		}

		[DotNetType("System.Drawing.GraphicsUnit")]
		extern(DOTNET) internal enum GraphicsUnit
		{
			World      = 0,
			Display    = 1,
			Pixel      = 2,
			Point      = 3,
			Inch       = 4,
			Document   = 5,
			Millimeter = 6
		}

		[DotNetType("System.Drawing.Drawing2D.MatrixOrder")]
		extern(DOTNET) internal enum MatrixOrder
		{
			Append = 1,
			Prepend = 0
		}

		[DotNetType("System.Drawing.Drawing2D.GraphicsState")]
		extern(DOTNET) internal class GraphicsState
		{
		}

		[DotNetType("System.Runtime.InteropServices.Marshal")]
		internal extern(CIL) static class Marshal
		{
			public static extern IntPtr UnsafeAddrOfPinnedArrayElement(CilArray arr, int index);
			public static extern void Copy(IntPtr source, byte[] destination, int start, int length);
		}

		[DotNetType("System.Array")]
		internal extern(CIL) class CilArray
		{
		}

		[DotNetType("System.Drawing.Point")]
		extern(DOTNET) internal struct Point
		{
			public extern Point (int x, int y);
			public extern int X { get; set; }
			public extern int Y { get; set; }
		}

		[DotNetType("System.Drawing.Drawing2D.ColorBlend")]
		extern(DOTNET) internal class ColorBlend
		{
			public extern ColorBlend();
			public extern ColorBlend (int numberOfPoints);
			public extern Color[] Colors { get; set; }
			public extern float[] Positions { get; set; }
		}

		[DotNetType("System.Drawing.Color")]
		extern(DOTNET) internal struct Color
		{
			IntPtr _dummy;
			public extern static readonly Color Empty;
			public extern byte A { get; }
			public extern byte R { get; }
			public extern byte G { get; }
			public extern byte B { get; }


			public static extern Color Blue { get; }
			public static extern Color Black { get; }
			public static extern Color Orange { get; }
			public static extern Color Yellow { get; }
			public static extern Color Green { get; }
			public static extern Color Indigo { get; }
			public static extern Color Violet { get; }
			public static extern Color Red { get; }
			public static extern Color FromArgb(int argb);
		}

		[DotNetType("System.Drawing.RectangleF")]
		extern(DOTNET) internal struct RectangleF
		{
			public extern RectangleF(float a, float b, float x, float y);
			public extern float Height { get; set; }
			public extern float Width { get; set; }
			public extern float X { get; set; }
			public extern float Y { get; set; }
			public extern void Inflate(float x,float y);
			public extern bool IsEmpty { get; }
		}

		[DotNetType("System.Drawing.Rectangle")]
		extern(DOTNET) internal struct Rectangle
		{
			public extern Rectangle(int a, int b, int x, int y);
			public extern int Height { get; set; }
			public extern int Width { get; set; }
		}

		[DotNetType("System.Drawing.PointF")]
		extern(DOTNET) internal struct PointF
		{
			// constructors
			public extern PointF(float x, float y);


			// properties
			public extern bool IsEmpty { get; }
			public extern float X { get; set; }
			public extern float Y { get; set; }
		}

		[DotNetType("System.Drawing.Imaging.ImageLockMode")]
		extern(DOTNET) internal enum ImageLockMode
		{
			ReadOnly = 1,
			ReadWrite = 3,
			UserInputBuffer = 4,
			WriteOnly = 2
		}

		[DotNetType("System.Drawing.Drawing2D.SmoothingMode")]
		extern(DOTNET) internal enum SmoothingMode
		{
			AntiAlias = 4,
			Default = 0,
			HighQuality = 2,
			HighSpeed = 1,
			Invalid = -1,
			None = 3
		}

		[DotNetType("System.Drawing.Drawing2D.Matrix")]
		extern(DOTNET) internal class Matrix
		{
			// constructors
			public extern Matrix();
			public extern Matrix(Rectangle rect , Point[] points );
			public extern Matrix(RectangleF rect, PointF[] points);
			public extern Matrix(float m11, float m12, float m21, float m22, float dx, float dy);
			public extern String IsIdentity { get; }
			public extern Matrix Clone();
		}
			
		[DotNetType("System.Drawing.Pen")]
		extern(DOTNET) internal class Pen
		{
			// constructors
			public extern Pen(DotNetBrush b);
			public extern Pen(DotNetBrush b, float width);
			public extern Pen(Color c);
			public extern Pen(Color c, float width);


			// properties
			public extern DotNetBrush Brush { get; set; }
			public extern Color Color { get; set; }
			public extern float MiterLimit { get; set; }
			public extern DotNetLineCap StartCap { get; set; }
			public extern DotNetLineCap EndCap { get; set; }
			public extern DotNetLineJoin LineJoin { get; set; }
			public extern Matrix Transform { get; set; }
			public extern float Width { get; set; }
		}

		[DotNetType("System.Drawing.Drawing2D.LineJoin")]
		extern(DOTNET) internal enum DotNetLineJoin
		{
			Bevel = 1,
			Miter = 0,
			MiterClipped = 3,
			Round = 2
		}

		[DotNetType("System.Drawing.Drawing2D.LineCap")]
		extern(DOTNET) internal enum DotNetLineCap
		{
			AnchorMask = 240,
			ArrowAnchor = 20,
			Custom = 255,
			DiamondAnchor = 19,
			Flat = 0,
			NoAnchor = 16,
			Round = 2,
			RoundAnchor = 18,
			Square = 1,
			SquareAnchor = 17,
			Triangle = 3
		}

		[DotNetType("System.Drawing.Drawing2D.CombineMode")]
		extern(DOTNET) internal enum CombineMode
		{
			Complement = 5,
			Exclude = 4,
			Intersect = 1,
			Replace = 0,
			Union = 2,
			Xor = 3
		}
	}
}
