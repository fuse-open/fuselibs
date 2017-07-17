using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using OpenGL;

using Fuse.Drawing.Primitives;

namespace Fuse.Drawing
{
	extern(iOS||OSX)
	class CoreGraphicsSurfacePath : SurfacePath
	{
		public IntPtr Path;
		public FillRule FillRule;
	}
	
	[Require("Xcode.Framework","CoreGraphics")]
	[Require("Source.Include", "CoreGraphicsLib.h")]
	[Require("Xcode.Framework","GLKit")]
	[extern(OSX) Require("Source.Include","XliPlatform/GL.h")]
	[extern(iOS) Require("Source.Include","OpenGLES/ES2/gl.h")]
	extern(iOS||OSX)
	class GraphicsSurface : CoreGraphicsSurface
	{
		DrawContext _drawContext;
		framebuffer _buffer;
		float2 _size;

		public override void Begin( DrawContext dc, framebuffer fb, float pixelsPerPoint )
		{
			VerifyCreated();
			_drawContext = dc;
			_buffer = fb;
			_pixelsPerPoint = pixelsPerPoint;
			_size = (float2)fb.Size / pixelsPerPoint;
			if (!BeginImpl(_context, fb.Size.X, fb.Size.Y, (int)fb.ColorBuffer.GLTextureHandle))
				throw new Exception("Failed to create Surface object");
		}
		
		[Foreign(Language.CPlusPlus)]
		static bool BeginImpl(IntPtr cp, int width, int height, int glTexture)
		@{
			auto ctx = (CGLib::Context*)cp;
			auto bytesPerRow = width * 4;
			auto byteCount = bytesPerRow * height;

			ctx->GLTexture = glTexture;
			
			//can we reuse the last context?
			if (ctx->Context && ctx->Width == width && ctx->Height == height)
			{
				memset(ctx->BitmapData, 0, byteCount);
				if (!ctx->ResetState())
				{
					@{Fuse.Diagnostics.InternalError(string, object, string, int, string):Call(uString::Utf8("Failed to reset  state"), NULL, uString::Utf8(__FILE__), __LINE__, uString::Utf8(""))};
				}
				ctx->SaveState();
				return true;
			}
			else if (ctx->Context)
			{
				ctx->ReleaseContext();
			}
			
			ctx->Width = width;
			ctx->Height = height;
			
			ctx->BitmapData = malloc(byteCount);
			if (!ctx->BitmapData)
			{
				@{Fuse.Diagnostics.InternalError(string, object, string, int, string):Call(uString::Utf8("Failed to allocate bitmap data"), NULL, uString::Utf8(__FILE__), __LINE__, uString::Utf8(""))};
				return false;
			}
			memset(ctx->BitmapData, 0, byteCount);
			
			ctx->Context = CGBitmapContextCreate(ctx->BitmapData, ctx->Width, ctx->Height, 8,
				bytesPerRow, ctx->ColorSpace, kCGImageAlphaPremultipliedLast);
			if (!ctx->Context) 
			{
				@{Fuse.Diagnostics.InternalError(string, object, string, int, string):Call(uString::Utf8("Failed to create CGBitmapContext"), NULL, uString::Utf8(__FILE__), __LINE__, uString::Utf8(""))};
				return false;
			}
			ctx->SaveState();
			return true;
		@}
		
		public override void End()
		{
			VerifyBegun();
			EndImpl(_context);
			_buffer = null;
		}
		
		[Foreign(Language.CPlusPlus)]
		static void EndImpl(IntPtr cp)
		@{
			auto ctx = (CGLib::Context*)cp;
			glBindTexture(GL_TEXTURE_2D, ctx->GLTexture);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ctx->Width, ctx->Height, 0, GL_RGBA, 
				GL_UNSIGNED_BYTE, ctx->BitmapData);
				
			//There's no indication the context reuse is actually faster, and since it keeps resources
			//around it's been disabled for now
			ctx->ReleaseContext();
		@}

		protected override void VerifyBegun()
		{
			if (_buffer == null)
				throw new Exception( "Surface.Begin was not called" );
		}

		/*
			This approach is really bad now. When Erik refactors ImageSource we shouldn't
			need to do the round-trip to GL.
			We might end up not supporting ImageFill until this is fixed, but this is useful
			here now to complete/test the sizing/tiling support.
		*/
		protected override void PrepareImageFill( ImageFill img )
		{
			var src = img.Source;
			var tex = src.GetTexture();
			if (tex == null) //probably still loading
				return;

			IntPtr imageRef;

			if defined(OSX)
			{
				imageRef = LoadImage(_context, (int)tex.GLTextureHandle, src.PixelSize.X, src.PixelSize.Y );
			}
			else
			{
				var fb = FramebufferPool.Lock( src.PixelSize, Uno.Graphics.Format.RGBA8888, false );

				//TODO: this is not entirely correct since _drawContext could be null now -- but it isn't
				//in any of our use cases, but the contract certainly allows for it
				_drawContext.PushRenderTarget(fb);
				CoreGraphicsDrawHelper.Singleton.DrawImageFill(tex);
				imageRef = LoadImagePoor(_context, src.PixelSize.X, src.PixelSize.Y );
				FramebufferPool.Release(fb);
				_drawContext.PopRenderTarget();
			}
			_imageBrushes[img] = imageRef;
		}

		[Foreign(Language.CPlusPlus)]
		static IntPtr LoadImagePoor(IntPtr cp, int width, int height)
		@{
			auto ctx = (CGLib::Context*)cp;
			int size = width * height * 4;
			auto pixelData = new UInt8[size];
			glReadPixels(0,0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixelData);

			CFDataRef data = CFDataCreate(NULL, pixelData, size);
			CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
			CGImageRef imageRef = CGImageCreate(width, height, 8, 32, width * 4, ctx->ColorSpace,
				kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);

			CGDataProviderRelease(provider);
			CFRelease(data);
			delete[] pixelData;
			return imageRef;
		@}
	}

	extern(iOS||OSX)
	class NativeSurface : CoreGraphicsSurface
	{

		IntPtr _cgContext = IntPtr.Zero;

		public void Begin(IntPtr cgContext, float pixelsPerPoint)
		{
			// The CGContext is already scaled
			_pixelsPerPoint = 1.0f;//pixelsPerPoint;
			_cgContext = cgContext;
			SetCGContext(_context, _cgContext);
		}

		public override void Begin( DrawContext dc, framebuffer fb, float pixelsPerPoint )
		{
			throw new NotSupportedException();
		}

		public override void End()
		{
			_cgContext = IntPtr.Zero;
		}

		protected override void VerifyBegun()
		{
			if (_cgContext == IntPtr.Zero)
				throw new Exception("NativeSurface.Begin was not called");
		}

		protected override void PrepareImageFill( ImageFill img ) { }

		[Foreign(Language.CPlusPlus)]
		static void SetCGContext(IntPtr cp, IntPtr cgContext)
		@{
			auto ctx = (CGLib::Context*)cp;
			ctx->Context = (CGContextRef)cgContext;
		@}
	}

	[Require("Xcode.Framework","CoreGraphics")]
	[Require("Source.Include", "CoreGraphicsLib.h")]
	[Require("Xcode.Framework","GLKit")]
	[extern(OSX) Require("Source.Include","XliPlatform/GL.h")]
	[extern(iOS) Require("Source.Include","OpenGLES/ES2/gl.h")]
	extern(iOS||OSX)
	abstract class CoreGraphicsSurface : Surface
	{
		protected float _pixelsPerPoint;
		protected IntPtr _context;

		public CoreGraphicsSurface()
		{
			_context = NewContext();
		}

		public override void Dispose()
		{
			foreach (var item in _gradientBrushes)
				ReleaseGradient(_context, item.Value);
			_gradientBrushes.Clear();

			foreach (var item in _imageBrushes)
			{
				ReleaseImage(_context, item.Value);
			}
			_imageBrushes.Clear();

			DeleteContext(_context);
			_context = IntPtr.Zero;
		}

		protected void VerifyCreated()
		{
			if (_context == IntPtr.Zero)
				throw new Exception( "Object disposed" );
		}

		protected abstract void VerifyBegun();

		[Foreign(Language.CPlusPlus)]
		static IntPtr NewContext()
		@{
			auto c = new CGLib::Context();
			c->ColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
			return c;
		@}

		[Foreign(Language.CPlusPlus)]
		static void DeleteContext(IntPtr cp)
		@{
			auto ctx = (CGLib::Context*)cp;
			CGColorSpaceRelease(ctx->ColorSpace);

			if (ctx->Context)
				ctx->ReleaseContext();
			delete ctx;
		@}

		float2 PixelFromPoint( float2 point )
		{
			//return (point + Area.Minimum) * _pixelsPerPoint;
			return point * _pixelsPerPoint;
		}

		public override SurfacePath CreatePath(IList<LineSegment> segments, FillRule fillRule = FillRule.NonZero )
		{
			var path = PathCreateMutable();
			AddSegments( path, segments, float2(0) );
			return new CoreGraphicsSurfacePath{ Path = path, FillRule = fillRule };
		}
		
		List<LineSegment> _temp = new List<LineSegment>();
		float2 AddSegments( IntPtr path, IList<LineSegment> segments, float2 prevPoint )
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
		
		public override void DisposePath( SurfacePath path )
		{
			var cgPath = path as CoreGraphicsSurfacePath;
			if (cgPath == null)
			{
				Fuse.Diagnostics.InternalError( "Non CoreGraphicSurfacePath used", path );
				return;
			}
			
			if (cgPath.Path == IntPtr.Zero)
			{
				Fuse.Diagnostics.InternalError( "Duplicate dipose of SurfacePath", path );
				return;
			}
			
			PathRelease(cgPath.Path);
			cgPath.Path = IntPtr.Zero;
		}

		[Foreign(Language.CPlusPlus)]
		static IntPtr PathCreateMutable()
		@{
			return CGPathCreateMutable();
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void PathRelease(IntPtr path)
		@{
			return CGPathRelease((CGPathRef)path);
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void PathMoveTo( IntPtr path, float x, float y )
		@{
			CGPathMoveToPoint( (CGMutablePathRef)path, nullptr, x, y );
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void PathLineTo( IntPtr path, float x, float y )
		@{
			CGPathAddLineToPoint( (CGMutablePathRef)path, nullptr, x, y );
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void PathCurveTo( IntPtr path, float x, float y, float ax, float ay, float bx, float by )
		@{
			CGPathAddCurveToPoint( (CGMutablePathRef)path, nullptr, ax, ay, bx, by, x, y );
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void PathClose( IntPtr path)
		@{
			CGPathCloseSubpath( (CGMutablePathRef)path );
		@}
		
		public override void Prepare( Brush brush )
		{
			VerifyCreated();
			Unprepare(brush);
			if (brush is ISolidColor)
				return;

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
			
		Dictionary<Brush, IntPtr> _gradientBrushes = new Dictionary<Brush,IntPtr>();
		void PrepareLinearGradient(LinearGradient lg)
		{
			var stops = lg.SortedStops;
			
			var colors = CGFloatNewArray(stops.Length*4);
			var offsets = CGFloatNewArray(stops.Length);
			for (int i=0; i < stops.Length; ++i)
			{
				var stop = stops[i];
				CGFloatSet(colors,i*4 + 0, stop.Color.X);
				CGFloatSet(colors,i*4 + 1, stop.Color.Y);
				CGFloatSet(colors,i*4 + 2, stop.Color.Z);
				CGFloatSet(colors,i*4 + 3, stop.Color.W);
				CGFloatSet(offsets, i, Math.Clamp(stop.Offset, 0.0f, 1.0f));

				if (stop.Offset > 1.0f || stop.Offset < 0.0f)
					Fuse.Diagnostics.UserWarning( "iOS/OSX does not support gradient stops outside of 0.0 to 1.0", stop.Offset );
			}
			_gradientBrushes[lg] = CreateLinearGradient(_context, colors, offsets, stops.Length );
				
			CGFloatDeleteArray(colors);
			CGFloatDeleteArray(offsets);
		}

		protected Dictionary<Brush, IntPtr> _imageBrushes = new Dictionary<Brush,IntPtr>();
		protected abstract void PrepareImageFill( ImageFill img );

		[Foreign(Language.CPlusPlus)]
		extern(OSX) static IntPtr LoadImage(IntPtr cp, int glTexture, int width, int height)
		@{
			auto ctx = (CGLib::Context*)cp;
			int rowSize = width * 4;
			int size = rowSize * height;
			auto pixelData = new UInt8[size];
			glBindTexture(GL_TEXTURE_2D, glTexture);
			glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixelData);
			
			//flip the image
			auto tempRow = new UInt8[rowSize];
			for (int y=0; y < height/2; ++y)
			{
				memcpy( tempRow, pixelData + y * rowSize, rowSize );
				memcpy( pixelData + y * rowSize, pixelData + (height-y-1) * rowSize, rowSize );
				memcpy( pixelData + (height-y-1) * rowSize, tempRow, rowSize );
			}
			
			CFDataRef data = CFDataCreate(NULL, pixelData, size);
			CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
			CGImageRef imageRef = CGImageCreate(width, height, 8, 32, width * 4, ctx->ColorSpace,
				kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault); 

			CGDataProviderRelease(provider);
			CFRelease(data);
			delete[] pixelData;
			delete[] tempRow;
			return imageRef;
		@}

		public override void Unprepare( Brush brush )
		{
			IntPtr ip;
			if (_gradientBrushes.TryGetValue( brush, out ip ))
			{
				VerifyCreated();
				ReleaseGradient(_context, ip);
				_gradientBrushes.Remove(brush);
			}
			if (_imageBrushes.TryGetValue( brush, out ip ))
			{
				VerifyCreated();
				ReleaseImage(_context, ip);
				_imageBrushes.Remove(brush);
			}
		}
		
		public override void FillPath( SurfacePath path, Brush fill )
		{
			VerifyBegun();
			var cgPath = path as CoreGraphicsSurfacePath;
			if (cgPath == null)
			{
				Fuse.Diagnostics.InternalError( "Non CoreGraphicSurfacePath used", path );
				return;
			}
			FillPathImpl(cgPath.Path, fill, cgPath.FillRule);
		}
		
		void FillPathImpl( IntPtr path, Brush fill, FillRule fillRule)
		{
			bool eoFill = fillRule == FillRule.EvenOdd;

			var solidColor = fill as ISolidColor;
			if (solidColor != null)
			{
				var color = solidColor.Color;
				FillPathSolidColor(_context, path, color.X, color.Y, color.Z, color.W, eoFill);
				return;
			}

			var linearGradient = fill as LinearGradient;
			if (linearGradient != null)
			{
				IntPtr gradient;
				if (!_gradientBrushes.TryGetValue( fill, out gradient ))
				{
					Fuse.Diagnostics.InternalError( "Unprepared LinearGradient", fill );
					return;
				}
				
				var ends = linearGradient.GetEffectiveEndPoints(ElementSize) * _pixelsPerPoint;
				FillPathLinearGradient(_context, path, gradient, ends[0], ends[1], ends[2], ends[3], eoFill);
				return;
			}

			var imageFill = fill as ImageFill;
			if (imageFill != null)
			{
				IntPtr image;
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
				
				FillPathImage(_context, path, image, pixelOrigin.X, pixelOrigin.Y, tileSize.X, tileSize.Y, eoFill);
				return;
			}

			Fuse.Diagnostics.UserError( "Unsupported brush", fill );
		}
		
		static bool _strokeWarning;
		public override void StrokePath( SurfacePath path, Stroke stroke )
		{
			VerifyBegun();
		
			//TODO: Adjust for stroke alignment, CoreGraphics supports only centered
			if ((stroke.Offset != 0 || stroke.Alignment != StrokeAlignment.Center)
				&& !_strokeWarning)
			{
				_strokeWarning = true;
				Fuse.Diagnostics.UserWarning( "iOS/OSX does not support non-center alignment strokes", stroke );
			}
			
			var cgPath = path as CoreGraphicsSurfacePath;
			if (cgPath == null)
			{
				Fuse.Diagnostics.InternalError( "Non CoreGraphicSurfacePath used", path );
				return;
			}
			
			var strokedPath = CreateStrokedPath(cgPath.Path, stroke.Width * _pixelsPerPoint,
				(int)stroke.LineJoin, (int)stroke.LineCap, stroke.LineJoinMiterLimit);
			FillPathImpl(strokedPath, stroke.Brush, FillRule.NonZero);
			PathRelease(strokedPath);
		}

		[Foreign(Language.CPlusPlus)]
		static IntPtr CreateStrokedPath(IntPtr path, float width,
			int fjoin, int fcap, float miterLimit)
		@{
			//supported by test SurfaceTest.EnumChecks
			CGLineJoin joinMap[] = { kCGLineJoinMiter, kCGLineJoinRound, kCGLineJoinBevel };
			auto join = joinMap[std::max(0,std::min(2,fjoin))];
			CGLineCap capMap[] = { kCGLineCapButt, kCGLineCapRound, kCGLineCapSquare };
			auto cap = capMap[std::max(0,std::min(2,fcap))];
			
			auto res = CGPathCreateCopyByStrokingPath( (CGPathRef)path, nullptr, 
				width, cap, join, miterLimit);
			return (void*)res;
		@}
		
		[Foreign(Language.CPlusPlus)]
		static IntPtr CGFloatNewArray(int size)
		@{
			return new CGFloat[size];
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void CGFloatDeleteArray(IntPtr a)
		@{
			return delete[]((CGFloat*)a);
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void CGFloatSet(IntPtr a, int index, double value)
		@{
			((CGFloat*)a)[index] = (CGFloat)value;
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void FillPathSolidColor(IntPtr cp, IntPtr path, float r, float g, float b, float a, bool eoFill)
		@{
			auto ctx = (CGLib::Context*)cp;
			CGFloat color[] = {r,g,b,a};
			CGContextSetFillColorWithColor(ctx->Context, CGColorCreate(ctx->ColorSpace, color));

			ctx->FillPath((CGPathRef)path, eoFill);
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void FillPathLinearGradient(IntPtr cp, IntPtr path, IntPtr gradient,
			float sx, float sy, float ex, float ey, bool eoFill)
		@{
			auto ctx = (CGLib::Context*)cp;

			//clip to path
			ctx->ClipPath((CGPathRef)path, eoFill);

			CGContextDrawLinearGradient(ctx->Context, (CGGradientRef)gradient, CGPoint{sx,sy}, CGPoint{ex,ey},
				kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void FillPathImage(IntPtr cp, IntPtr path, IntPtr image, 
			float originX, float originY, float tileSizeX, float tileSizeY,
			bool eoFill)
		@{
			auto ctx = (CGLib::Context*)cp;
			ctx->SaveState(); //no other way to restore clip

			ctx->ClipPath((CGPathRef)path, eoFill);

			CGContextDrawTiledImage(ctx->Context, 
				CGRectMake(originX, originY, tileSizeX, tileSizeY), (CGImageRef)image );

			ctx->RestoreState();
		@}
		
		[Foreign(Language.CPlusPlus)]
		static IntPtr CreateLinearGradient(IntPtr cp, IntPtr colors, IntPtr stops, int count)
		@{
			auto ctx = (CGLib::Context*)cp;
			return CGGradientCreateWithColorComponents(ctx->ColorSpace, 
				(CGFloat*)colors, (CGFloat*)stops, count);
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void ReleaseGradient(IntPtr cp, IntPtr gradient)
		@{
			CGGradientRelease((CGGradientRef)gradient);
		@}
		
		[Foreign(Language.CPlusPlus)]
		static void ReleaseImage(IntPtr cp, IntPtr gradient)
		@{
			CGImageRelease((CGImageRef)gradient);
		@}
		
		static bool _transformWarn;
		public override void PushTransform( float4x4 t )
		{
			VerifyBegun();
			SaveContextState(_context);

			//these matrix entries aren't used, so warn if they aren't the identity value
			const float zeroTolerance = 1e-05f;
			if (!_transformWarn && (Math.Abs(t.M13) > zeroTolerance ||
				Math.Abs(t.M14) > zeroTolerance ||
				Math.Abs(t.M23) > zeroTolerance ||
				Math.Abs(t.M24) > zeroTolerance ||
				Math.Abs(t.M31) > zeroTolerance ||
				Math.Abs(t.M32) > zeroTolerance ||
				Math.Abs(t.M34) > zeroTolerance ||
				Math.Abs(t.M43) > zeroTolerance ||
				Math.Abs(t.M44-1) > zeroTolerance))
			{
				//skip M33 since Z scaling of flat objects is okay and common
				Fuse.Diagnostics.UserWarning( 
					"iOS/OSX does not support 3d or shear transforms for vector graphics", this );
				_transformWarn = true;
			}
				
			ConcatTransform(_context, t.M11, t.M12, t.M21, t.M22, 
				t.M41 * _pixelsPerPoint, t.M42 * _pixelsPerPoint);
		}

		[Foreign(Language.CPlusPlus)]
		static void SaveContextState(IntPtr cp)
		@{
			auto ctx = (CGLib::Context*)cp;
			ctx->SaveState();
		@}

		[Foreign(Language.CPlusPlus)]
		static void ConcatTransform(IntPtr cp, float m11, float m12, float m21, float m22, float m31, float m32)
		@{
			auto ctx = (CGLib::Context*)cp;
			auto ctm = CGAffineTransformMake(m11, m12, m21, m22, m31, m32);
			CGContextConcatCTM(ctx->Context, ctm);
		@}
		
		public override void PopTransform()
		{
			VerifyBegun();
			RestoreContextState(_context);
		}
		
		[Foreign(Language.CPlusPlus)]
		static void RestoreContextState(IntPtr cp)
		@{
			auto ctx = (CGLib::Context*)cp;
			if (!ctx->RestoreState())
			{
				@{Fuse.Diagnostics.InternalError(string, object, string, int, string):Call(uString::Utf8("Failed to restore state"), NULL, uString::Utf8(__FILE__), __LINE__, uString::Utf8(""))};
			}
		@}
	}
	
	extern(iOS||OSX)
	class CoreGraphicsDrawHelper
	{
		static public CoreGraphicsDrawHelper Singleton = new CoreGraphicsDrawHelper();
		
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
