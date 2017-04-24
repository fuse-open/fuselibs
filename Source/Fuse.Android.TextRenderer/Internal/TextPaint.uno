using Uno;
using Uno.Graphics;
using OpenGL;
using Fuse.Elements;
using Fuse.Controls.Graphics;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Android
{

	using Fuse.Controls.Native.Android;

	extern(Android) internal class TextPaint
	{
		public Java.Object Handle
		{
			get { return _handle; }
		}

		readonly Java.Object _handle;

		public TextPaint() : this(Create()) { }

		public TextPaint(Java.Object handle)
		{
			_handle = handle;
		}

		public bool AntiAlias
		{
			set { SetAntiAlias(Handle, value); }
		}

		public Rect GetTextBounds(string text, int start, int end)
		{
			int[] r = new int[4];
			GetTextBounds(Handle, text, start, end, r);
			return new Rect((float)r[0], (float)r[1], (float)r[2], (float)r[3]);
		}

		public Typeface Typeface
		{
			set { SetTypeface(Handle, value.Handle); }
		}

		public float TextSize
		{
			set { SetTextSize(Handle, value); }
		}

		public float4 Color
		{
			set { SetColor(Handle, (int)Uno.Color.ToArgb(value)); }
		}

		[Foreign(Language.Java)]
		static void SetColor(Java.Object handle, int color)
		@{
			((android.text.TextPaint)handle).setColor(color);
		@}

		[Foreign(Language.Java)]
		static void GetTextBounds(Java.Object handle, string text, int start, int end, int[] r)
		@{
			android.graphics.Rect rect = new android.graphics.Rect();
			((android.text.TextPaint)handle).getTextBounds(text, start, end, rect);
			r.set(0, rect.left);
			r.set(1, rect.top);
			r.set(2, rect.right);
			r.set(3, rect.bottom);
		@}

		[Foreign(Language.Java)]
		static void SetAntiAlias(Java.Object handle, bool value)
		@{
			((android.text.TextPaint)handle).setAntiAlias(value);
		@}

		[Foreign(Language.Java)]
		static void SetTypeface(Java.Object paintHandle, Java.Object typefaceHandle)
		@{
			((android.text.TextPaint)paintHandle).setTypeface(((android.graphics.Typeface)typefaceHandle));
		@}

		[Foreign(Language.Java)]
		static void SetTextSize(Java.Object handle, float textSize)
		@{
			((android.text.TextPaint)handle).setTextSize(textSize);
		@}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new android.text.TextPaint();
		@}

	}

}