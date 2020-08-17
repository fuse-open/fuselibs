using Uno;
using Uno.Graphics;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using OpenGL;
using Fuse.Common;
using Fuse.Controls.Graphics;
using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.iOS.Bindings
{
	internal extern (iOS) class TextLayout
	{
		ObjC.Object _font; // UIFont*
		bool _layoutValid, _layoutMin;
		ObjC.Object _textStorage; // NSTextStorage*
		float2 _layoutSize;
		ObjC.Object _textColor; // UIColor*
		ObjC.Object _style; // NSMutableParagraphStyle*
		public float TextOpacity;

		public ObjC.Object LayoutManager; // NSLayoutManager*
		public ObjC.Object TextContainer; // NSTextContainer*
		public Uno.Rect PixelBounds;

		public void Invalidate()
		{
			_layoutValid = false;
		}

		[Foreign(Language.ObjC)]
		public TextLayout()
		@{
			NSLayoutManager* lm = [[NSLayoutManager alloc] init];
			@{TextLayout:Of(_this).LayoutManager:Set(lm)};

			NSMutableParagraphStyle* ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			@{ObjC.Object:Of(_this)._style:Set(ps)};
		@}

		public bool UpdateLayout(Fuse.Controls.TextControl control, float2 size, bool useMin=false)
		{
			size = Math.Ceil(size * control.Viewport.PixelsPerPoint);
			bool valid = _layoutValid && _layoutSize == size && _layoutMin == useMin;
			if (valid)
				return false;

			_font = Fuse.Controls.Native.iOS.FontCache.Get(control.Font.Descriptors[0], control.FontSizeScaled * control.Viewport.PixelsPerPoint);

			//iOS Text rendering fails to apply opacity to emoji, therefore we apply opacity on our own
			_textColor = ToUIColor(float4(control.TextColor.XYZ,1));
			TextOpacity = control.TextColor.W;

			ClearTextContainers(LayoutManager);

			var width = size.X;
			if (control.TextTruncation == Fuse.Controls.TextTruncation.None &&
				control.TextWrapping == TextWrapping.NoWrap)
				width = 0;
			TextContainer = CreateNSTextContainer(width, size.Y);
			AddNSTextContainer(LayoutManager, TextContainer);

			SetNSParagraphStyleProperties(
				_style,
				control.TextAlignment,
				control.TextWrapping,
				control.LineSpacing * control.Viewport.PixelsPerPoint);

			//OPT: This storage, along with the style and its bits, could be shared between the
			//two TextLayout in TextRenderer, they will always be the same
			_textStorage = CreateNSTextStorage(
				control.Value,
				_font,
				_textColor,
				_style);
			SetNSTextStorage(LayoutManager, _textStorage);

			_layoutSize = size;
			_layoutValid = true;
			_layoutMin = useMin;

			PixelBounds = UsedRectForTextContainer(LayoutManager, TextContainer);
			return true;
		}

		[Foreign(Language.ObjC)]
		public static ObjC.Object ToUIColor(float4 color)
		@{
			return [UIColor colorWithRed:(CGFloat)color.X
				green:(CGFloat)color.Y
				blue:(CGFloat)color.Z
				alpha:(CGFloat)color.W];
		@}

		[Foreign(Language.ObjC)]
		public static void ClearTextContainers(ObjC.Object layoutManager)
		@{
			NSLayoutManager* lm = (NSLayoutManager*)layoutManager;
			while (lm.textContainers.count > 0)
				[lm removeTextContainerAtIndex:0];
		@}

		[Foreign(Language.ObjC)]
		public static ObjC.Object CreateNSTextContainer(float width, float height)
		@{
			NSTextContainer* result = [[NSTextContainer alloc] initWithSize:CGSizeMake(width, height)];
			result.lineFragmentPadding = 0;
			return result;
		@}

		[Foreign(Language.ObjC)]
		public static void SetNSParagraphStyleProperties(
			ObjC.Object style,
			Fuse.Controls.TextAlignment alignment,
			Fuse.Controls.TextWrapping wrapping,
			float lineSpacing)
		@{
			NSMutableParagraphStyle* s = (NSMutableParagraphStyle*)style;
			switch (alignment)
			{
				case @{Fuse.Controls.TextAlignment.Left}:
					s.alignment = NSTextAlignmentLeft;
					break;
				case @{Fuse.Controls.TextAlignment.Center}:
					s.alignment = NSTextAlignmentCenter;
					break;
				case @{Fuse.Controls.TextAlignment.Right}:
					s.alignment = NSTextAlignmentRight;
					break;
				default: break;
			}
			switch (wrapping)
			{
				case @{TextWrapping.NoWrap}:
					s.lineBreakMode = NSLineBreakByTruncatingTail;
					break;
				case @{TextWrapping.Wrap}:
					s.lineBreakMode = NSLineBreakByWordWrapping;
				default: break;
			}
			s.lineSpacing = lineSpacing;
		@}

		[Foreign(Language.ObjC)]
		public static ObjC.Object CreateNSTextStorage(string value, ObjC.Object font, ObjC.Object color, ObjC.Object style)
		@{
			return [[NSTextStorage alloc] initWithString:value
				attributes: \@{
					NSFontAttributeName: font,
					NSForegroundColorAttributeName: color,
					NSParagraphStyleAttributeName: style
				}];
		@}

		[Foreign(Language.ObjC)]
		public static void SetNSTextStorage(ObjC.Object layoutManager, ObjC.Object textStorage)
		@{
			[(NSLayoutManager*)layoutManager setTextStorage:textStorage];
		@}

		[Foreign(Language.ObjC)]
		public static void AddNSTextContainer(ObjC.Object layoutManager, ObjC.Object textContainer)
		@{
			[(NSLayoutManager*)layoutManager addTextContainer:(NSTextContainer*)textContainer];
		@}

		static Rect CreateRect(float2 pos, float2 size)
		{
			return new Rect(pos, size);
		}

		[Foreign(Language.ObjC)]
		public static Rect UsedRectForTextContainer(ObjC.Object layoutManager, ObjC.Object textContainer)
		@{
			CGRect rect = [(NSLayoutManager*)layoutManager
				usedRectForTextContainer:(NSTextContainer*)textContainer];
			@{float2} pos = @{float2(float, float):New((float)rect.origin.x, (float)-rect.origin.y)}; // Apple's coordinate systems and/or APIs are crazy.
			@{float2} size = @{float2(float, float):New((float)rect.size.width, (float)rect.size.height)};
			return @{CreateRect(float2, float2):Call(pos, size)};
		@}
	}

	[Set("TypeName", "::CGColorSpaceRef")]
	[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
	extern(iOS) struct CGColorSpaceRef { IntPtr _dummy; }

	[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
	[Set("TypeName", "::CGContextRef")]
	extern(iOS) struct CGContextRef { IntPtr _dummy; }

	internal extern (iOS) class TextRenderer : ITextRenderer
	{
		static readonly CGColorSpaceRef _colorSpace = CGColorSpaceCreateDeviceRGB();

		static CGColorSpaceRef CGColorSpaceCreateDeviceRGB() @{ return ::CGColorSpaceCreateDeviceRGB(); @}

		internal static ITextRenderer Create( Fuse.Controls.TextControl control )
		{
			return new TextRenderer(control);
		}

		TextLayout _textLayout = new TextLayout();
		TextLayout _measureLayout;

		Fuse.Controls.TextControl _control;
		public TextRenderer( Fuse.Controls.TextControl control )
		{
			_control = control;
		}

		public float2 GetContentSize(LayoutParams lp)
		{
			if (_measureLayout == null)
				_measureLayout = new TextLayout();

			var size = float2(
				lp.HasX ? lp.X : float.PositiveInfinity,
				lp.HasY ? lp.Y : float.PositiveInfinity);
			if (lp.HasMaxX)
				size.X = Math.Min(size.X, lp.MaxX);
			if (lp.HasMaxY)
				size.Y = Math.Min(size.Y, lp.MaxY);
			_measureLayout.UpdateLayout(_control, size, true);
			return _measureLayout.PixelBounds.Size / _control.Viewport.PixelsPerPoint;
		}

		public void Draw(DrawContext dc, Visual where)
		{
			if (_textLayout.UpdateLayout(_control, _arrangeSize))
				InvalidateTexture();

			var pixelSize = (int2)Math.Ceil(_textLayout.PixelBounds.Size);
			if (pixelSize.X < 1 || pixelSize.Y < 1 ||
			    pixelSize.X > Texture2D.MaxSize || pixelSize.Y > Texture2D.MaxSize)
				return;

			var pointSize = (float2)pixelSize / _control.Viewport.PixelsPerPoint;

			if (_texture == null)
			{
				IntPtr textureBuffer = extern<IntPtr>(pixelSize) "malloc($0.X * $0.Y * 4)";
				if (textureBuffer == IntPtr.Zero)
					return;

				var imageContext = CGBitmapContextCreate(textureBuffer, pixelSize.X, pixelSize.Y, _colorSpace);
				if (extern<IntPtr>(imageContext) "(@{IntPtr})$0" == IntPtr.Zero)
					throw new Exception("Failed to create CGBitmapContext");

				DrawGlyphs(
					imageContext,
					- _textLayout.PixelBounds.Position.X, - _textLayout.PixelBounds.Position.Y,
					pixelSize.X, pixelSize.Y,
					_textLayout.LayoutManager,
					_textLayout.TextContainer);

				CGContextRelease(imageContext);

				var textureHandle = GL.CreateTexture();
				GL.BindTexture(GLTextureTarget.Texture2D, textureHandle);
				GL.PixelStore(GLPixelStoreParameter.UnpackAlignment, 1);
				GL.TexImage2D(GLTextureTarget.Texture2D, 0, GLPixelFormat.Rgba, pixelSize.X, pixelSize.Y, 0, GLPixelFormat.Bgra, GLPixelType.UnsignedByte, textureBuffer);
				extern(textureBuffer) "free($0)";
				textureBuffer = IntPtr.Zero;
				GL.BindTexture(GLTextureTarget.Texture2D, GLTextureHandle.Zero);

				_texture = new texture2D(textureHandle, pixelSize, 1, Format.RGBA8888);
			}

			var pointPosition = _textLayout.PixelBounds.Position / _control.Viewport.PixelsPerPoint;
			Blitter.Singleton.Blit(_texture, new Rect(pointPosition, pointSize), dc.GetLocalToClipTransform(where), _textLayout.TextOpacity, true);
		}

		static CGContextRef CGBitmapContextCreate(IntPtr textureBuffer, int width, int height, CGColorSpaceRef colorSpace)
		@{
			CGBitmapInfo flags = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;
			return ::CGBitmapContextCreate($0, $1, $2, 8, $1 * 4, $3, flags);
		@}

		static void CGContextRelease(CGContextRef context) @{ ::CGContextRelease($0); @}

		[Foreign(Language.ObjC)]
		static void DrawGlyphs(
			CGContextRef context,
			float x, float y,
			int width, int height,
			ObjC.Object layoutManager,
			ObjC.Object textContainer)
		@{
			NSLayoutManager* lm = (NSLayoutManager*)layoutManager;
			NSTextContainer* tc = (NSTextContainer*)textContainer;
			UIGraphicsPushContext(context);
			CGRect rect = CGRectMake(0, 0, width, height);
			CGContextClearRect(context, rect);
			NSRange glyphRange = [lm glyphRangeForTextContainer:tc];
			CGPoint point = CGPointMake(x, y);
			[lm drawGlyphsForGlyphRange:glyphRange atPoint:point];
			UIGraphicsPopContext();
		@}

		float2 _arrangePosition, _arrangeSize;
		public void Arrange(float2 position, float2 size)
		{
			_arrangePosition = position;
			// Add a half-pixel to the size to avoid truncation due
			// to floating point precision or rounding errors
			_arrangeSize = size + float2(0.5f, 0.5f) / _control.Viewport.PixelsPerPoint;
			Invalidate();
			_textLayout.UpdateLayout(_control, _arrangeSize);
		}

		public void Invalidate()
		{
			_textLayout.Invalidate();
			if (_measureLayout != null)
				_measureLayout.Invalidate();
			InvalidateTexture();
		}

		public void SoftDispose()
		{
			InvalidateTexture();
		}

		void InvalidateTexture()
		{
			if (_texture != null)
			{
				_texture.Dispose();
				_texture = null;
			}
		}

		public Uno.Rect GetRenderBounds()
		{
			_textLayout.UpdateLayout(_control, _arrangeSize);
			return Uno.Rect.Translate( new Uno.Rect(
				(float2)_textLayout.PixelBounds.Position / _control.Viewport.PixelsPerPoint,
				(float2)_textLayout.PixelBounds.Size / _control.Viewport.PixelsPerPoint), _arrangePosition );
		}

		texture2D _texture;
	}
}
