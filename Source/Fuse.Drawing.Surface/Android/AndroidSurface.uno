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
		"com.fusetools.drawing.surface.AndroidGraphicsContext",
		"com.fusetools.drawing.surface.LinearGradientStore"
	)]
	[ForeignInclude(Language.Java,
		"java.nio.ByteBuffer",
		"java.nio.IntBuffer",
		"java.nio.ByteOrder",
		"java.nio.FloatBuffer"
	)]
	[extern(Android) Require("Source.Include","XliPlatform/GL.h")]
	extern(Android)
	class AndroidSurface : Surface
	{
		Java.Object _context;
		framebuffer _buffer;
		float _pixelsPerPoint;
		float2 _size;
		DrawContext _drawContext;

		public AndroidSurface()
		{
			_context = NewContext();
			var impl = _context;
		}

		[Foreign(Language.Java)]
		static Java.Object NewContext()
		@{
			// create an empty canvas
			// this gets populated with a bitmap on `Begin`
			Canvas c = new Canvas();

			AndroidGraphicsContext context = new AndroidGraphicsContext();
			context.canvas = c;

			return context;
		@}

		public override void Dispose()
		{
			_gradientBrushes.Clear();

			foreach (var item in _imageBrushes)
				recycleBitmap(item.Value);
			_imageBrushes.Clear();

			_context = null;
		}

		void VerifyCreated()
		{
			if (_context == null)
				throw new Exception( "Object disposed" );
		}

		void VerifyBegun()
		{
			if (_buffer == null)
				throw new Exception( "Canvas.Begin was not called" );
		}

		public override void PushTransform( float4x4 t )
		{
			VerifyBegun();
			SaveContextState(_context);
			ConcatTransform(_context, ToMatrix(t, _pixelsPerPoint));
		}

		public override SurfacePath CreatePath( IList<LineSegment> segments, FillRule fillRule = FillRule.NonZero)
		{
			var path = PathCreateMutable();
			AddSegments( path, segments, float2(0) );
			return new AndroidCanvasPath{ Path = path, FillRule = fillRule };
		}

		/**
			Load a bitmap of given dimensions into the context and use it for the canvas
		*/
		[Foreign(Language.Java)]
		public static extern(Android) void LoadBitmap(Java.Object context, int width, int height)
		@{
			AndroidGraphicsContext impl = (AndroidGraphicsContext) context;
			Bitmap b = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);

			impl.canvas.setBitmap(b);
			impl.bitmap = b;

			impl.canvas.setMatrix(null);

			// invert our bitmap since the Android canvas is inversed when drawing
			impl.canvas.translate(0.0f, (float)height);
			impl.canvas.scale(1, -1);
		@}

		Dictionary<Brush, Java.Object> _imageBrushes = new Dictionary<Brush,Java.Object>();
		/*
			This approach is really bad now. When Erik refactors ImageSource we shouldn't
			need to do the round-trip to GL.
			We might end up not supporting ImageFill until this is fixed, but this is useful
			here now to complete/test the sizing/tiling support.
		*/
		void PrepareImageFill( ImageFill img )
		{
			var src = img.Source;

			if (src.PixelSize.X == 0 || src.PixelSize.Y == 0)
			{
				Fuse.Diagnostics.UserError( "Recieved an image with no width or height", src.PixelSize );
				return;
			}

			var tex = src.GetTexture();
			//probably still loading
			if (tex == null) return;

			var fb = FramebufferPool.Lock( src.PixelSize, Uno.Graphics.Format.RGBA8888, false );

			_drawContext.PushRenderTarget(fb);
			AndroidGraphicsDrawHelper.Singleton.DrawImageFill(tex);
			Java.Object imageRef = LoadImage(_context, (int)tex.GLTextureHandle, src.PixelSize.X, src.PixelSize.Y );
			FramebufferPool.Release(fb);
			_drawContext.PopRenderTarget();

			_imageBrushes[img] = imageRef;
		}

		[Foreign(Language.Java)]
		static Java.Object LoadImage(Java.Object cp, int glTextureId, int width, int height)
		@{
			AndroidGraphicsContext ctx = (AndroidGraphicsContext)cp;
			int size = width * height * 4;
			int[] pixels = new int[size];

			IntBuffer pixelData = IntBuffer.wrap(pixels);
			GLES20.glReadPixels(0, 0, width,height, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, pixelData);

			Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
			bitmap.copyPixelsFromBuffer(pixelData);

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
				FillPathSolidColor(_context, path, (int)Uno.Color.ToArgb(solidColor.Color), eoFill, paint);
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

				FillPathLinearGradient(_context, path, gradient, ends[0], ends[1], ends[2], ends[3], eoFill, paint);
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

				FillPathImage(_context, path, image,
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
			AndroidGraphicsContext context = (AndroidGraphicsContext) cp;
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
			AndroidGraphicsContext context = (AndroidGraphicsContext) cp;

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
			int index = context.canvas.save();
			context.canvas.drawPath((Path) path, paint);
			context.canvas.restoreToCount(index);
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

			AndroidGraphicsContext context = (AndroidGraphicsContext) cp;
			Bitmap image = (Bitmap) imageAsObject;
			Path path = (Path) pathAsObject;

			path.setFillType(eoFill ? Path.FillType.EVEN_ODD : Path.FillType.WINDING);

			int index = context.canvas.save();

			image.prepareToDraw();

			Paint paint = (Paint)paintAsObject;
			Bitmap scaledBitmap = Bitmap.createScaledBitmap(
				image,
				(int)tileSizeX,
				(int)tileSizeY,
				true
			);

			// flip the image so that it displays correctly
			Matrix matrix = new Matrix();
			matrix.preScale(1, -1);
			scaledBitmap = Bitmap.createBitmap(scaledBitmap, 0, 0, (int)tileSizeX, (int)tileSizeY, matrix, true);

			BitmapShader shader = new BitmapShader(scaledBitmap, Shader.TileMode.REPEAT, Shader.TileMode.REPEAT);
			paint.setShader(shader);
<<<<<<< HEAD
=======
			paint.setStyle(Paint.Style.FILL);

			// these measurements aren't actually used - but rect needs placeholder values
			RectF rect = new RectF((originX), (originY), originX + tileSizeX, originY + tileSizeY);

			// get the bounds of the clipping path which we will use for drawing
			path.computeBounds(rect, true);

			// if our picture path starts off screen, subtract from the bottom
			if (originY < 0)
			{
				rect.bottom -= originY;
			}
			// otherwise, the picture starts offset on the screen - so increase the top size
			else
			{
				rect.top -= originY;
			}

			// if our picture starts off the screen to the left, reduce the drawing space on the right
			if (originX < 0)
			{
				rect.right -= originX;
			}
			// otherwise, reduce the drawing space on the left
			else
			{
				rect.left -= originX;
			}
>>>>>>> Surface: Start moving some code around, preparing to spilt into GL and Native implementations

			context.canvas.clipPath(path);
			context.canvas.drawPath(path, paint);
			context.canvas.restoreToCount(index);
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
			Paint paint = new Paint();

			paint.setStrokeMiter(miterLimit);
			paint.setStrokeCap(Paint.Cap.BUTT);
			paint.setStrokeJoin(Paint.Join.MITER);
			paint.setStyle(Paint.Style.STROKE);
			paint.setStrokeWidth(width);
			paint.setFlags(Paint.ANTI_ALIAS_FLAG);

			return paint;
		@}

		public override void Begin(DrawContext dc, framebuffer fb, float pixelsPerPoint)
		{
			var impl = _context;
			_drawContext = dc;
			_buffer = fb;
			_pixelsPerPoint = pixelsPerPoint;
			_size = (float2)fb.Size / pixelsPerPoint;

			// return early if framebuffer has no size to prevent runtime crashes
			if (fb.Size.X == 0 || fb.Size.Y == 0)
			{
				_context = null;
				return;
			}
			LoadBitmap(impl, fb.Size.X, fb.Size.Y);
			BeginImpl(impl, fb.Size.X, fb.Size.Y, (int)fb.ColorBuffer.GLTextureHandle);
		}

		[Foreign(Language.Java)]
		static void BeginImpl(Java.Object _context, int width, int height, int glTextureId)
		@{
			AndroidGraphicsContext context = (AndroidGraphicsContext) _context;
			context.width = width;
			context.height = height;
			context.glTextureId = glTextureId;
		@}

		/**
			Ends drawing. All drawing called after `Begin` and to now must be completed by now. This copies the resulting image to the desired output setup in `Begin`.
		*/
		public override void End()
		{
			var impl = _context;

			if (impl == null) return;
			EndImpl(impl);
		}

		[Foreign(Language.Java)]
		static void EndImpl(Java.Object context)
		@{
			AndroidGraphicsContext realContext = (AndroidGraphicsContext) context;

			GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, realContext.glTextureId);

			// heat up the caches. not needed but good to have
			realContext.bitmap.prepareToDraw();

			GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, realContext.bitmap, 0);
			realContext.bitmap.recycle();
		@}

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
		static void SaveContextState(Java.Object cp)
		@{
			AndroidGraphicsContext ctx = (AndroidGraphicsContext) cp;
			ctx.saveCurrentMatrix();
		@}

		[Foreign(Language.Java)]
		static void ConcatTransform(Java.Object cp, Java.Object m)
		@{
			AndroidGraphicsContext ctx = (AndroidGraphicsContext) cp;
			Matrix matrix = (Matrix) m;

			Matrix currentMatrix = ctx.canvas.getMatrix();

			boolean something = currentMatrix.preConcat(matrix);

			ctx.canvas.setMatrix(currentMatrix);
		@}

		public override void PopTransform()
		{
			VerifyBegun();
			RestoreContextState(_context);
		}

		[Foreign(Language.Java)]
		static void RestoreContextState(Java.Object cp)
		@{
			AndroidGraphicsContext ctx = (AndroidGraphicsContext) cp;
			ctx.restoreCurrentMatrix();
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

	extern(Android)
	class AndroidGraphicsDrawHelper
	{
		static public AndroidGraphicsDrawHelper Singleton = new AndroidGraphicsDrawHelper();

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
	}
}
