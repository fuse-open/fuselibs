using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using OpenGL;

namespace Fuse.Controls.Native.Android
{
	extern(Android) internal class NativeViewRenderer : INativeViewRenderer
	{

		readonly Java.Object _viewHandle;

		GLTextureHandle _textureHandle;
		Java.Object _bitmapHandle;
		bool _visualValid = false;

		public NativeViewRenderer(Java.Object viewHandle)
		{
			_viewHandle = viewHandle;
		}

		int2 _oldSize = int2(-1, -1);
		void INativeViewRenderer.Draw(
			float4x4 localToClipTransform,
			float2 position,
			float2 size,
			float density)
		{

			var realSize = (int2)(size * density);
			var reuse = true;

			if (_oldSize != realSize)
			{
				DeleteTexture();
				_textureHandle = GL.CreateTexture();
				_bitmapHandle = CreateBitmap(realSize.X, realSize.Y);
				_oldSize = realSize;
				reuse = false;
				_visualValid = false;
			}

			if (!_visualValid)
			{
				GL.BindTexture(GLTextureTarget.Texture2D, _textureHandle);
				Upload(_viewHandle, _bitmapHandle, reuse, realSize.X, realSize.Y);
				GL.BindTexture(GLTextureTarget.Texture2D, GLTextureHandle.Zero);
				_visualValid = true;
			}

			Blitter.Singleton.Blit(
				new texture2D(_textureHandle, realSize, 1, Format.RGBA8888),
				position,
				size,
				localToClipTransform);
		}

		[Foreign(Language.Java)]
		static void Upload(Java.Object viewHandle, Java.Object bitmapHandle, bool reuse, int w, int h)
		@{
			android.view.View view = (android.view.View)viewHandle;

			view.measure(
				android.view.View.MeasureSpec.makeMeasureSpec(w, android.view.View.MeasureSpec.EXACTLY),
				android.view.View.MeasureSpec.makeMeasureSpec(h, android.view.View.MeasureSpec.EXACTLY));

			view.layout(0, 0, w, h);
			android.graphics.Bitmap bitmap = (android.graphics.Bitmap)bitmapHandle;
			android.graphics.Canvas canvas = new android.graphics.Canvas(bitmap);

			int scrollX = view.getScrollX();
			int scrollY = view.getScrollY();
			canvas.translate(-(float)scrollX, -(float)scrollY);

			bitmap.eraseColor((int)0x00000000);

			view.draw(canvas);

			if (reuse)
			{
				android.opengl.GLUtils.texSubImage2D(android.opengl.GLES20.GL_TEXTURE_2D, 0, 0, 0, bitmap);
			}
			else
			{
				android.opengl.GLUtils.texImage2D(android.opengl.GLES20.GL_TEXTURE_2D, 0, bitmap, 0);
			}
		@}

		[Foreign(Language.Java)]
		static void DisposeBitmap(Java.Object bitmap)
		@{
			((android.graphics.Bitmap)bitmap).recycle();
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateBitmap(int w, int h)
		@{
			return android.graphics.Bitmap.createBitmap(w, h, android.graphics.Bitmap.Config.ARGB_8888);
		@}

		void INativeViewRenderer.Invalidate()
		{
			_visualValid = false;
		}

		void IDisposable.Dispose()
		{
			DeleteTexture();
		}

		void DeleteTexture()
		{
			if (_textureHandle != GLTextureHandle.Zero)
			{
				GL.DeleteTexture(_textureHandle);
				_textureHandle = GLTextureHandle.Zero;
			}
			if (_bitmapHandle != null)
			{
				DisposeBitmap(_bitmapHandle);
				_bitmapHandle = null;
			}
		}
	}

	extern(Android) class Blitter
	{
		internal static Blitter Singleton = new Blitter();

		public void Blit(texture2D vt, float2 pos, float2 size, float4x4 localToClipTransform)
		{
			draw
			{
				apply Fuse.Drawing.PreMultipliedAlphaCompositing;

				CullFace : PolygonFace.None;
				DepthTestEnabled: false;
				float2[] verts: readonly new float2[] {

					float2(0,0),
					float2(1,0),
					float2(1,1),
					float2(0,0),
					float2(1,1),
					float2(0,1)
				};

				float2 v: vertex_attrib(verts);
				float2 LocalVertex: pos + v * size;
				ClipPosition: Vector.Transform(LocalVertex, localToClipTransform);
				float2 TexCoord: v;
				PixelColor: sample(vt, TexCoord, SamplerState.LinearClamp);
			};
		}
	}
}
