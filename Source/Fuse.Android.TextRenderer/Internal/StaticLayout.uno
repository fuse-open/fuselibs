using Uno;
using Uno.Graphics;
using OpenGL;
using Fuse.Elements;
using Fuse.Controls.Graphics;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Android
{

	extern (Android) internal class StaticLayout
	{
		public enum Alignment
		{
			Center = 0,
			Normal,
			Opposite
		}

		public Java.Object Handle
		{
			get { return _handle; }
		}

		readonly Java.Object _handle;

		public StaticLayout(Java.Object handle)
		{
			_handle = handle;
		}

		public StaticLayout(
			string text,
			TextPaint paint,
			int width,
			Alignment align,
			float spacingMult,
			float spacingAdd,
			bool includePad)
			
			: this( Create(text, paint.Handle, width, (int)align, spacingMult, spacingAdd, includePad) ) { }

		public StaticLayout(
			string text,
			int bufStart,
			int bufEnd,
			TextPaint paint,
			int outerWidth,
			Alignment align,
			float spacingMult,
			float spacingAdd,
			bool includePad,
			TextUtils.TruncateAt truncateAt,
			int ellipsizedWith)

			: this( Create(text, bufStart, bufEnd, paint.Handle, outerWidth, (int)align, spacingMult, spacingAdd, includePad, (int)truncateAt, ellipsizedWith) ) { }

		public static float GetDesiredWidth(string text, TextPaint paint)
		{
			return GetDesiredWidthImpl(text ?? "", paint.Handle);
		}

		public int LineCount
		{
			get { return GetLineCount(Handle); }
		}

		public int EllipsizedWidth
		{
			get { return GetEllipsizedWidth(Handle); }
		}

		public int Height
		{
			get { return GetHeight(Handle); }
		}

		public int Width
		{
			get { return GetWidth(Handle); }
		}

		public int GetLineStart(int line)
		{
			return GetLineStart(Handle, line);
		}

		public int GetLineEnd(int line)
		{
			return GetLineEnd(Handle, line);
		}

		public float GetLineLeft(int line)
		{
			return GetLineLeft(Handle, line);
		}

		public int GetLineBaseline(int line)
		{
			return GetLineBaseline(Handle, line);
		}

		public void Draw(Canvas canvas)
		{
			Draw(Handle, canvas.Handle);
		}

		[Foreign(Language.Java)]
		static void Draw(Java.Object layoutHandle, Java.Object canvasHandle)
		@{
			((android.text.StaticLayout)layoutHandle).draw(((android.graphics.Canvas)canvasHandle));
		@}

		[Foreign(Language.Java)]
		static int GetHeight(Java.Object handle)
		@{
			return ((android.text.StaticLayout)handle).getHeight();
		@}

		[Foreign(Language.Java)]
		static int GetWidth(Java.Object handle)
		@{
			return ((android.text.StaticLayout)handle).getWidth();
		@}

		[Foreign(Language.Java)]
		static int GetEllipsizedWidth(Java.Object handle)
		@{
			return ((android.text.StaticLayout)handle).getEllipsizedWidth();
		@}

		[Foreign(Language.Java)]
		static int GetLineBaseline(Java.Object handle, int line)
		@{
			return ((android.text.StaticLayout)handle).getLineBaseline(line);
		@}

		[Foreign(Language.Java)]
		static float GetLineLeft(Java.Object handle, int line)
		@{
			return ((android.text.StaticLayout)handle).getLineLeft(line);
		@}

		[Foreign(Language.Java)]
		static int GetLineStart(Java.Object handle, int line)
		@{
			return ((android.text.StaticLayout)handle).getLineStart(line);
		@}

		[Foreign(Language.Java)]
		static int GetLineEnd(Java.Object handle, int line)
		@{
			return ((android.text.StaticLayout)handle).getLineEnd(line);
		@}

		[Foreign(Language.Java)]
		static float GetDesiredWidthImpl(string text, Java.Object paintHandle)
		@{
			android.text.TextPaint paint = (android.text.TextPaint)paintHandle;
			return android.text.StaticLayout.getDesiredWidth(text, paint);
		@}

		[Foreign(Language.Java)]
		static int GetLineCount(Java.Object handle)
		@{
			return ((android.text.StaticLayout)handle).getLineCount();
		@}

		[Foreign(Language.Java)]
		static Java.Object Create(
			string text,
			Java.Object paintHandle,
			int width,
			int align,
			float spacingMult,
			float spacingAdd,
			bool includePad)
		@{
			// Be careful, doing stupid enum conversion
			android.text.Layout.Alignment alignment = android.text.Layout.Alignment.ALIGN_CENTER;
			if (align == 1) alignment = android.text.Layout.Alignment.ALIGN_NORMAL;
			else if (align == 2) alignment = android.text.Layout.Alignment.ALIGN_OPPOSITE;

			android.text.TextPaint paint = (android.text.TextPaint)paintHandle;

			return new android.text.StaticLayout(text, paint, width, alignment, spacingMult, spacingAdd, includePad);
		@}

		[Foreign(Language.Java)]
		static Java.Object Create(
			string text,
			int bufStart,
			int bufEnd,
			Java.Object paintHandle,
			int outerWidth,
			int align,
			float spacingMult,
			float spacingAdd,
			bool includePad,
			int truncateAt,
			int ellipsizedWith)
		@{
			// Be careful, doing stupid enum conversion
			android.text.Layout.Alignment alignment = android.text.Layout.Alignment.ALIGN_CENTER;
			if (align == 1) alignment = android.text.Layout.Alignment.ALIGN_NORMAL;
			else if (align == 2) alignment = android.text.Layout.Alignment.ALIGN_OPPOSITE;

			// Be careful, doing stupid enum conversion
			android.text.TextUtils.TruncateAt truncate = android.text.TextUtils.TruncateAt.END;
			if (truncateAt == 1) truncate = android.text.TextUtils.TruncateAt.MARQUEE;
			else if (truncateAt == 2) truncate = android.text.TextUtils.TruncateAt.MIDDLE;
			else if (truncateAt == 3) truncate = android.text.TextUtils.TruncateAt.START;

			android.text.TextPaint paint = (android.text.TextPaint)paintHandle;

			return new android.text.StaticLayout(text, bufStart, bufEnd, paint, outerWidth, alignment, spacingMult, spacingAdd, includePad, truncate, ellipsizedWith);
		@}

	}

}