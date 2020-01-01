using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics.Utils.Text;
using Uno.Graphics.Utils;
using Uno.Graphics;
using Uno;

namespace Fuse.Text.Implementation
{
	[ForeignInclude(Language.ObjC, "CoreText/CoreText.h")]
	extern(iOS) class CoreTextFontFace : FontFace
	{
		ObjC.Object _descriptor; // UIFontDescriptor*

		public CoreTextFontFace(string fileName, int index, Predicate<string> stylePredicate)
		{
			_descriptor = Fuse.Internal.iOSSystemFont.GetMatchingUIFontDescriptor(fileName, index, stylePredicate);
		}

		public override void Dispose()
		{
			base.Dispose();
			_descriptor = null;
		}

		override Font GetOfPixelSizeInternal(int pixelSize)
		{
			var uiFont = CreateFont(_descriptor, pixelSize);
			var cgFont = CreateCGFont(uiFont);
			var hbFace = Harfbuzz.ct_face_create(cgFont);
			return new CoreTextFont(hbFace, cgFont, uiFont, pixelSize);
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateFont(ObjC.Object descriptor, int pixelSize)
		@{
			// float pointSize = (float)pixelSize * 0.75f;
			return [UIFont fontWithDescriptor:(UIFontDescriptor*)descriptor size:pixelSize];
		@}

		[Foreign(Language.ObjC)]
		static IntPtr CreateCGFont(ObjC.Object uiFont)
		@{
			return CTFontCopyGraphicsFont((__bridge CTFontRef)(UIFont*)uiFont, NULL);
		@}
	}

	[ForeignInclude(Language.ObjC, "CoreText/CoreText.h")]
	extern(iOS) class CoreTextFont : HarfbuzzFont
	{
		readonly ObjC.Object _uiFont; // UIFont*
		IntPtr _cgFont; // CGFontRef
		IntPtr _hbFace; // hb_face_t*
		readonly int _pixelSize;
		public override int PixelSize { get { return _pixelSize; } }
		protected override float Scale { get { return 64.f; } }

		// Note: Takes ownership of hbFace and cgFont
		internal CoreTextFont(IntPtr hbFace, IntPtr cgFont, ObjC.Object uiFont, int pixelSize)
			: base(Harfbuzz.font_create(hbFace))
		{
			_hbFace = hbFace;
			_cgFont = cgFont;
			_uiFont = uiFont;
			_pixelSize = pixelSize;
			Harfbuzz.font_set_scale(_hbFont, pixelSize, pixelSize);
		}

		public override void Dispose()
		{
			base.Dispose();
			if (_hbFace != IntPtr.Zero)
			{
				Harfbuzz.face_destroy(_hbFace);
				_hbFace = IntPtr.Zero;
			}
			if (_cgFont != IntPtr.Zero)
			{
				CGFontRelease(_cgFont);
				_cgFont = IntPtr.Zero;
			}
		}

		public override float Ascender { get { return GetAscender(_uiFont); } }
		public override float Descender { get { return GetDescender(_uiFont); } }
		public override float LineHeight { get { return GetLineHeight(_uiFont); } }
		public override int NumGlyphs { get { return GetNumGlyphs(_cgFont); } }

		[Foreign(Language.ObjC)]
		float GetAscender(ObjC.Object uiFont) @{ return ((UIFont*)uiFont).ascender; @}
		[Foreign(Language.ObjC)]
		float GetDescender(ObjC.Object uiFont) @{ return - ((UIFont*)uiFont).descender; @}
		[Foreign(Language.ObjC)]
		float GetLineHeight(ObjC.Object uiFont) @{ return ((UIFont*)uiFont).lineHeight; @}
		int GetNumGlyphs(IntPtr cgFont) @{ return (@{int})CGFontGetNumberOfGlyphs((CGFontRef)$0); @}


		public override RenderedGlyph Render(Glyph glyph)
		{
			int2 size;
			float2 offset;
			var data = Render(GetCTFont(_uiFont), glyph.Index, out size, out offset);
			var grayscale = TryConvertRGBAToL8(data);
			var bitmap = grayscale == null
				? new Bitmap(size, Format.RGBA8888, data)
				: new Bitmap(size, Format.L8, grayscale);
			return new RenderedGlyph(
				bitmap,
				float2(offset.X, LineHeight - Ascender - Descender - offset.Y - size.Y),
				1f);
		}

		[Foreign(Language.ObjC)]
		void CGFontRelease(IntPtr cgFont)
		@{
			::CGFontRelease((CGFontRef)cgFont);
		@}

		[Require("Source.Include", "@{Math:Include}")]
		byte[] Render(IntPtr rawFont, uint index, out int2 size, out float2 offset)
		@{
			CTFontRef font = (CTFontRef)$0;
			CGGlyph glyph = (CGGlyph)$1;
			CGRect boundingRect;

			CTFontGetBoundingRectsForGlyphs(font, kCTFontDefaultOrientation, &glyph, &boundingRect, 1);

			int width = (int)@{Math.Ceil(float):Call(boundingRect.size.width)} + 2;
			int height = (int)@{Math.Ceil(float):Call(boundingRect.size.height)} + 2;
			CGPoint originFloor = CGPointMake(
				@{Math.Floor(float):Call(boundingRect.origin.x)} - 1.0f,
				@{Math.Floor(float):Call(boundingRect.origin.y)} - 1.0f);

			*$2 = @{int2(int, int):New(width, height)};
			*$3 = @{float2(float, float):New(originFloor.x, originFloor.y)};

			int bytesPerRow = width * 4;
			int byteSize = bytesPerRow * height;
			@{byte[]} data = @{byte[]:New(byteSize)};

			if (width * height > 4)
			{
				CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

				CGContextRef context = CGBitmapContextCreate(
					data->Ptr(),
					width,
					height,
					8,
					bytesPerRow,
					colorSpace,
					kCGImageAlphaPremultipliedLast);

				CGPoint position = CGPointMake(-originFloor.x, -originFloor.y);
				CTFontDrawGlyphs(font, &glyph, &position, 1, context);

				CGColorSpaceRelease(colorSpace);
				CGContextRelease(context);
			}

			return data;
		@}

		[Foreign(Language.ObjC)]
		static IntPtr GetCTFont(ObjC.Object font)
		@{
			return (void*)(__bridge CTFontRef)(UIFont*)font;
		@}

		static byte[] TryConvertRGBAToL8(byte[] buffer)
		{
			var stride = 4;
			assert (buffer.Length % stride) == 0;

			var len = buffer.Length / 4;
			byte[] result = new byte[len];
			for (int i = 0; i < len; ++i)
			{
				var pos = i * stride;
				var r = buffer[pos + 0];
				var g = buffer[pos + 1];
				var b = buffer[pos + 2];
				var a = buffer[pos + 3];
				if (r != 0 || g != 0 || b != 0)
					return null;
				result[i] = a;
			}
			return result;
		}
	}
}
