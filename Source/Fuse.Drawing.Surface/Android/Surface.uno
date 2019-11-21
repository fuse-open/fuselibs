using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using OpenGL;

using Fuse.Elements;
using Fuse.Drawing;
using Fuse.Drawing.Primitives;

namespace Fuse.Drawing
{
	extern(Android)
	class AndroidCanvasPath : SurfacePath
	{
		public Java.Object Path;
		public FillRule FillRule;
	}

	[ForeignInclude(Language.Java,
		"android.graphics.Canvas",
		"android.graphics.Bitmap",
		"android.graphics.Shader",
		"android.graphics.BitmapShader",
		"android.graphics.drawable.BitmapDrawable",
		"android.graphics.Rect",
		"android.graphics.RectF",
		"android.graphics.Path",
		"android.opengl.GLUtils",
		"android.opengl.GLES20",
		"android.graphics.Paint",
		"android.graphics.LinearGradient",
		"android.graphics.Shader.TileMode",
		"android.graphics.Color",
		"android.graphics.PorterDuffXfermode",
		"android.graphics.Matrix",
		"android.graphics.PorterDuff.Mode",
		"com.fuse.drawing.surface.LinearGradientStore",
		"com.fuse.drawing.surface.GraphicsSurfaceContext"
	)]
	[ForeignInclude(Language.Java,
		"java.nio.ByteBuffer",
		"java.nio.IntBuffer",
		"java.nio.ByteOrder",
		"java.nio.FloatBuffer"
	)]
	[extern(Android) Require("Source.Include","XliPlatform/GL.h")]
	extern(Android)
	abstract class AndroidSurface : Surface
	{
		protected Java.Object SurfaceContext;

		public AndroidSurface()
		{
			SurfaceContext = NewContext();
		}

		[Foreign(Language.Java)]
		static Java.Object NewContext()
		@{
			return new GraphicsSurfaceContext();
		@}

		protected float _pixelsPerPoint;

		public override void Dispose()
		{
			SurfaceContext = null;
			_gradientBrushes.Clear();

			foreach (var item in _imageBrushes)
				recycleBitmap(item.Value);
			_imageBrushes.Clear();
		}

		void VerifyCreated()
		{
			if (SurfaceContext == null)
				throw new Exception( "Object disposed" );
		}

		protected abstract void VerifyBegun();

		public override void PushTransform( float4x4 t )
		{
			VerifyBegun();
			SaveContextState(SurfaceContext);
			ConcatTransform(SurfaceContext, ToMatrix(t, _pixelsPerPoint));
		}

		public override void PopTransform()
		{
			VerifyBegun();
			RestoreContextState(SurfaceContext);
		}

		public override SurfacePath CreatePath( IList<LineSegment> segments, FillRule fillRule = FillRule.NonZero)
		{
			var path = PathCreateMutable();
			AddSegments( path, segments, float2(0) );
			return new AndroidCanvasPath{ Path = path, FillRule = fillRule };
		}

		Dictionary<Brush, Java.Object> _imageBrushes = new Dictionary<Brush,Java.Object>();

		void PrepareImageFill( ImageFill fill )
		{
			var src = fill.Source;
			if (src.PixelSize.X == 0 || src.PixelSize.Y == 0)
			{
				Fuse.Diagnostics.UserError( "Recieved an image with no width or height", src.PixelSize );
				return;
			}

			var tex = src.GetTexture();
			//probably still loading
			if (tex == null)
				return;

			_imageBrushes[fill] = PrepareImageFillImpl(fill);
		}

		protected Java.Object PrepareImageFillImpl( ImageFill img )
		{
			var src = img.Source;
			Java.Object imageRef = CreateNativeImage(src.GetBytes());
			return imageRef;
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object CreateNativeImage(byte[] data)
		@{
			byte[] bytes = ((ByteArray)data).copyArray();
			android.graphics.BitmapFactory.Options options = new android.graphics.BitmapFactory.Options();
			android.graphics.Bitmap bitmap = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.length, options);
			return bitmap;
		@}

		public override void FillPath( SurfacePath path, Brush fill )
		{
			var cgPath = (AndroidCanvasPath)path;
			Java.Object paint = CreateFillPaint();
			DrawPath(cgPath.Path, fill, cgPath.FillRule, paint);
		}

		/*
			## Implementation details

			In order to create a stroke effect on a path in Android, you must draw the path twice.
			First you must draw it filled, then you must draw it with stroke-only. There is no way
			of drawing both at once

			Since Android's API is less stateful than iOS's, then we need to pass in a `Paint`
			object which then gets used in order to draw. Note that this method is shared between
			different path types. For example, it gets used both by `Stroke` paths and `Filled` paths.
		*/
		void DrawPath( Java.Object path, Brush fill, FillRule fillRule, Java.Object paint)
		{
			bool eoFill = fillRule == FillRule.EvenOdd;

			var solidColor = fill as ISolidColor;

			if (solidColor != null)
			{
				FillPathSolidColor(SurfaceContext, path, (int)Uno.Color.ToArgb(solidColor.Color), eoFill, paint);
				return;
			}

			var linearGradient = fill as LinearGradient;
			if (linearGradient != null)
			{
				Java.Object gradient;
				if (!_gradientBrushes.TryGetValue( fill, out gradient ))
				{
					Fuse.Diagnostics.InternalError( "Unprepared LinearGradient", fill );
					return;
				}

				var ends = linearGradient.GetEffectiveEndPoints(ElementSize) * _pixelsPerPoint;

				FillPathLinearGradient(SurfaceContext, path, gradient, ends[0], ends[1], ends[2], ends[3], eoFill, paint);
				return;
			}

			var imageFill = fill as ImageFill;
			if (imageFill != null)
			{
				Java.Object image;
				if (!_imageBrushes.TryGetValue( fill, out image ) )
				{
					Fuse.Diagnostics.InternalError( "Unprepared ImageFill", fill );
					return;
				}

				var sizing = imageFill.SizingContainer;
				sizing.absoluteZoom = _pixelsPerPoint; //TODO: probably not good to modify sizing here...?
				var imageSize = imageFill.Source.Size;
				var scale = sizing.CalcScale( ElementSize, imageSize );
				var origin = sizing.CalcOrigin( ElementSize, imageSize * scale );

				var tileSize = imageSize * _pixelsPerPoint * scale;
				var pixelOrigin = origin * _pixelsPerPoint;

				FillPathImage(SurfaceContext, path, image,
					pixelOrigin.X, pixelOrigin.Y,
					tileSize.X, tileSize.Y,
					ElementSize.X * _pixelsPerPoint, ElementSize.Y * _pixelsPerPoint,
					eoFill, paint);
				return;
			}

			Fuse.Diagnostics.UserError( "Unsupported brush", fill );
		}

		[Foreign(Language.Java)]

		static void FillPathSolidColor(Java.Object cp, Java.Object pathAsObject, int color, bool eoFill, Java.Object pretendPaint)
		@{
			GraphicsSurfaceContext context = (GraphicsSurfaceContext) cp;
			Path path = (Path) pathAsObject;

			path.setFillType(eoFill ? Path.FillType.EVEN_ODD : Path.FillType.WINDING);

			Paint paint = (Paint) pretendPaint;
			if (paint == null)
			{
				paint = new Paint();
			}

			paint.setColor(color);
			context.canvas.drawPath(path, paint);
		@}

		[Foreign(Language.Java)]
		static void FillPathLinearGradient(
			Java.Object cp, Java.Object path,
			Java.Object gradientStore, float startX,
			float startY, float endX,
			float endY, bool eoFill,
			Java.Object pretendPaint
		)
		@{
			GraphicsSurfaceContext context = (GraphicsSurfaceContext) cp;

			Paint paint = null;

			paint = (Paint) pretendPaint;
			if (paint == null) paint = new Paint();

			LinearGradientStore store = (LinearGradientStore) gradientStore;

			LinearGradient gradient = new LinearGradient(
				startX, startY,
				endX, endY,
				store.colors, store.stops,
			TileMode.CLAMP);

			paint.setShader(gradient);

			// this is different from iOS
			// iOS draws relative to the _entire_ canvas
			// and therefore needs to clip to the path before drawing
			// On Android, we can just call `drawPath` which clips
			// to the right area for us
			Canvas canvas = context.canvas;
			int index = canvas.save();
			canvas.drawPath((Path) path, paint);
			canvas.restoreToCount(index);
		@}

		[Foreign(Language.Java)]
		static void FillPathImage(Java.Object cp, Java.Object pathAsObject, Java.Object imageAsObject,
			float originX, float originY, float tileSizeX, float tileSizeY,
			float width, float height,
			bool eoFill, Java.Object paintAsObject)
		@{
			// TODO: reimplement - should wait for upstream changes first
			// see comments on this function in the CoreGraphicsSurface implementation
			// of this function


			if (tileSizeX == 0 || tileSizeY == 0)
				return;

			GraphicsSurfaceContext context = (GraphicsSurfaceContext) cp;
			Canvas canvas = context.canvas;
			Bitmap image = (Bitmap) imageAsObject;
			Path path = (Path) pathAsObject;

			path.setFillType(eoFill ? Path.FillType.EVEN_ODD : Path.FillType.WINDING);

			int index = canvas.save();

			image.prepareToDraw();

			Paint paint = (Paint)paintAsObject;
			Bitmap scaledBitmap = Bitmap.createScaledBitmap(
				image,
				(int)tileSizeX,
				(int)tileSizeY,
				true
			);

			BitmapShader shader = new BitmapShader(scaledBitmap, Shader.TileMode.REPEAT, Shader.TileMode.REPEAT);
			paint.setShader(shader);

			canvas.clipPath(path);
			canvas.drawPath(path, paint);
			canvas.restoreToCount(index);
		@}

		/*
			`colors` _must_ be the same length as `stops`.
		*/
		[Foreign(Language.Java)]
		static Java.Object CreateLinearGradient(
			int[] colors,
			float[] stops
		)
		@{
			LinearGradientStore store = new LinearGradientStore();
			store.colors = colors.copyArray();
			store.stops = stops.copyArray();
			return store;
		@}

		public override void StrokePath( SurfacePath path, Stroke stroke )
		{
			VerifyBegun();

			var cgPath = (AndroidCanvasPath)path;

			var strokedPaint = CreateStrokedPaint(stroke.Width * _pixelsPerPoint,
					(int)stroke.LineJoin, (int)stroke.LineCap, stroke.LineJoinMiterLimit);
			DrawPath(cgPath.Path, stroke.Brush, FillRule.NonZero, strokedPaint);
		}

		[Foreign(Language.Java)]
		static Java.Object CreateStrokedPaint(float width,
			int fjoin, int fcap, float miterLimit)
		@{
			//supported by test SurfaceTest.EnumChecks
			Paint.Join[] joinMap = { Paint.Join.MITER, Paint.Join.ROUND, Paint.Join.BEVEL };
			Paint.Join join = joinMap[Math.max(0,Math.min(2,fjoin))];
			Paint.Cap[] capMap = { Paint.Cap.BUTT, Paint.Cap.ROUND, Paint.Cap.SQUARE };
			Paint.Cap cap = capMap[Math.max(0,Math.min(2,fcap))];

			Paint paint = new Paint();

			paint.setStrokeMiter(miterLimit);
			paint.setStrokeCap(cap);
			paint.setStrokeJoin(join);
			paint.setStyle(Paint.Style.STROKE);
			paint.setStrokeWidth(width);
			paint.setFlags(Paint.ANTI_ALIAS_FLAG);

			return paint;
		@}

		public override void Begin(DrawContext dc, framebuffer fb, float pixelsPerPoint)
		{
			_pixelsPerPoint = pixelsPerPoint;
		}

		/**
			Prepares this brush for drawing. If this is called a second time with the same `Brush` it indicates the properties of that brush have changed.
		*/
		public override void Prepare( Brush brush )
		{
			VerifyCreated();
			Unprepare(brush);

			if (brush is ISolidColor)
			{
				return;
			}

			var linearGradient = brush as LinearGradient;
			if (linearGradient != null)
			{
				PrepareLinearGradient(linearGradient);
				return;
			}

			var imageFill = brush as ImageFill;
			if (imageFill != null)
			{
				PrepareImageFill(imageFill);
				return;
			}

			Fuse.Diagnostics.UserError( "Unsupported brush", brush );
		}
		/**
			Indicates the brush will no longer be used for drawing. It's resources can be freed.
		*/
		public override void Unprepare( Brush brush )
		{
			Java.Object ip;
			if (_gradientBrushes.TryGetValue( brush, out ip ))
			{
				VerifyCreated();

				_gradientBrushes.Remove(brush);
			}
			if (_imageBrushes.TryGetValue( brush, out ip ))
			{
				VerifyCreated();
				recycleBitmap(ip);
				_imageBrushes.Remove(brush);
			}
		}

		float2 PixelFromPoint( float2 point )
		{
			return point * _pixelsPerPoint;
		}

		List<LineSegment> _temp = new List<LineSegment>();
		float2 AddSegments( Java.Object path, IList<LineSegment> segments, float2 prevPoint )
		{
			for (int i=0; i < segments.Count; ++i )
			{
				var seg = segments[i];
				var to = PixelFromPoint(seg.To);
				switch (seg.Type)
				{
					case LineSegmentType.Move:
						PathMoveTo( path, to.X, to.Y );
						break;

					case LineSegmentType.Straight:
						PathLineTo( path, to.X, to.Y );
						break;

					case LineSegmentType.BezierCurve:
					{
						var a = PixelFromPoint(seg.A);
						var b = PixelFromPoint(seg.B);
						PathCurveTo( path, to.X, to.Y, a.X, a.Y, b.X, b.Y );
						break;
					}

					case LineSegmentType.EllipticArc:
					{
						_temp.Clear();
						SurfaceUtil.EllipticArcToBezierCurve(prevPoint, seg, _temp);
						prevPoint = AddSegments( path, _temp, prevPoint );
						break;
					}

					case LineSegmentType.Close:
					{
						PathClose( path );
						break;
					}
				}
				prevPoint = seg.To;
			}

			return prevPoint;
		}


		/* This function is different to the core implementation:
			we do not store a cache of the gradient brushes here as we need
			the dimensions at draw time on android since linear gradients can't
			be updated
		*/
		Dictionary<Brush, Java.Object> _gradientBrushes = new Dictionary<Brush,Java.Object>();
		void PrepareLinearGradient(LinearGradient lg)
		{
			var stops = lg.SortedStops;

			int[] colors = new int[stops.Length];
			float[] offsets = new float[stops.Length];


			for (int i=0; i < stops.Length; ++i)
			{
				var stop = stops[i];
				colors[i] = (int)Uno.Color.ToArgb(stop.Color);
				offsets[i] = stop.Offset;
			}

			_gradientBrushes[lg] = CreateLinearGradient(
				colors,
				offsets
			);
		}

		public override void DisposePath( SurfacePath path )
		{
			var cgPath = (AndroidCanvasPath)path;

			if (cgPath.Path == null)
			{
				Fuse.Diagnostics.InternalError( "Duplicate dispose of SurfacePath", path );
				return;
			}

			cgPath.Path = null;
		}

		[Foreign(Language.Java)]
		static Java.Object PathCreateMutable()
		@{
			return new Path();
		@}

		[Foreign(Language.Java)]
		static void PathMoveTo( Java.Object pathAsObject, float x, float y )
		@{
			Path path = (Path) pathAsObject;
			path.moveTo( x, y );
		@}

		[Foreign(Language.Java)]
		static void PathCurveTo( Java.Object pathAsObject, float x, float y, float ax, float ay, float bx, float by )
		@{
			Path path = (Path) pathAsObject;
			path.cubicTo(ax, ay, bx, by, x, y);
		@}

		[Foreign(Language.Java)]
		static void PathLineTo( Java.Object pathAsObject, float x, float y )
		@{
			Path path = (Path) pathAsObject;
			path.lineTo(x, y);
		@}

		[Foreign(Language.Java)]
		static void PathClose( Java.Object pathAsObject)
		@{
			Path path = (Path) pathAsObject;
			path.close();
		@}

		[Foreign(Language.Java)]
		static int SaveContextState(Java.Object cp)
		@{
			GraphicsSurfaceContext ctx = (GraphicsSurfaceContext) cp;
			return ctx.canvas.save();
		@}

		[Foreign(Language.Java)]
		static void ConcatTransform(Java.Object cp, Java.Object m)
		@{
			GraphicsSurfaceContext ctx = (GraphicsSurfaceContext) cp;
			Canvas canvas = ctx.canvas;
			Matrix matrix = (Matrix) m;

			canvas.concat(matrix);
		@}

		[Foreign(Language.Java)]
		static void RestoreContextState(Java.Object cp)
		@{
			GraphicsSurfaceContext ctx = (GraphicsSurfaceContext) cp;
			ctx.canvas.restore();
		@}

		[Foreign(Language.Java)]
		static void recycleBitmap(Java.Object bit)
		@{
			((Bitmap) bit).recycle();
		@}

		/*
			Convert a given transform to a matrix to be used with Android's canvas

			pixelPerPoint will be used to multiply rotations and translations, but
			not scaling, as the scaling is done for segments in `AddSegment`
		*/

		Java.Object ToMatrix(float4x4 transform, float pixelsPerPoint)
		{
			var matrix = new []
			{
				transform.M11, transform.M21, transform.M41 * pixelsPerPoint,
				transform.M12, transform.M22, transform.M42 * pixelsPerPoint,
				transform.M14, transform.M24, transform.M44
			};
			return ToMatrix(matrix);
		}

		[Foreign(Language.Java)]
		Java.Object ToMatrix(float[] matrix)
		@{
			android.graphics.Matrix m = new android.graphics.Matrix();
			m.setValues(matrix.copyArray());
			return m;
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateFillPaint()
		@{
			Paint paint = new Paint();
			paint.setFlags(Paint.ANTI_ALIAS_FLAG);
			return paint;
		@}

	}
}
