using Uno;
using Uno.IO;
using Uno.Graphics;
using Uno.Compiler.ExportTargetInterop;
using Uno.Runtime.InteropServices;
using Uno.Threading;
using Fuse.Scripting;
using Fuse.Drawing;
using OpenGL;
using Fuse.Drawing.DotNetNative;

namespace Fuse.Controls
{

	[ForeignInclude(Language.ObjC, "OpenGLES/ES2/glext.h")]
	[Require("Source.Include", "uImage/Bitmap.h")]
	[Require("Source.Include", "uImage/Png.h")]
	[Require("Source.Include", "uBase/Memory.h")]
	public partial class Panel
	{
		string _imagePath;
		Action<string> _callback;

		static Panel()
		{
			ScriptClass.Register(typeof(Panel), new ScriptPromise<Panel, string, string>("capture", ExecutionThread.Any, Save));
		}

		static Future<string> Save(Context context, Panel panel, object[] args)
		{
			var p = new Promise<string>();
			panel.Capture(p.Resolve);
			return p;
		}

		public void Capture(Action<string> resolve) {
			_callback = resolve;
			SetupImagePath();
			_captureNextFrame = true;
			InvalidateVisual();
		}

		private void SetupImagePath()
		{
			if defined(Android)
				_imagePath = Path.Combine(Directory.GetUserDirectory(UserDirectory.Data), Guid.NewGuid().ToString() + ".png");
			if defined(iOS)
				_imagePath = Path.Combine(Directory.GetUserDirectory(UserDirectory.Cache), Guid.NewGuid().ToString() + ".png");
			if defined(CIL)
				_imagePath = Path.Combine(Directory.GetUserDirectory(UserDirectory.Cache), Guid.NewGuid().ToString() + ".png");
		}

		protected override void DrawWithChildren(DrawContext dc)
		{
			if (_captureNextFrame)
			{
				ScreenshotContent(dc);
				if (_callback != null)
					_callback(_imagePath);

				_captureNextFrame = false;
			}
			base.DrawWithChildren(dc);
		}

		bool _captureNextFrame;
		bool TryGetCaptureRect(out Recti rect)
		{
			var bounds = RenderBoundsWithEffects;
			if (bounds.IsInfinite || bounds.IsEmpty)
			{
				rect = new Recti(0,0,0,0);
				return false;
			}

			var scaled = Rect.Scale(bounds.FlatRect, AbsoluteZoom);
			int2 origin = (int2)Math.Floor(scaled.LeftTop);
			int2 size = (int2)Math.Ceil(scaled.Size);
			rect = new Recti(origin.X, origin.Y, origin.X + size.X, origin.Y + size.Y);
			return true;
		}

		void ScreenshotContent(DrawContext dc)
		{
			if defined(OPENGL)
			{
				Recti rect;
				if (!TryGetCaptureRect(out rect))
				{
					rect = dc.Scissor;
				}

				var size = rect.Size;

				var fb = new framebuffer(size, Format.RGBA8888, FramebufferFlags.None);
				var cc = new OrthographicFrustum
				{
					Origin = float2(rect.Minimum.X, rect.Minimum.Y) / AbsoluteZoom,
					Size = float2(size.X, size.Y) / AbsoluteZoom,
					LocalFromWorld = WorldTransformInverse
				};

				dc.PushRenderTargetFrustum(fb, cc);

				dc.Clear(float4(1, 1, 1, 1));
				base.DrawWithChildren(dc);

				var buffer = new byte[size.X * size.Y * 4];
				GL.PixelStore(GLPixelStoreParameter.PackAlignment, 1);
				GL.ReadPixels(0, 0, size.X, size.Y, GLPixelFormat.Rgba, GLPixelType.UnsignedByte, buffer);

				dc.PopRenderTargetFrustum();
				SavePng(buffer, size.X, size.Y, _imagePath);
				fb.Dispose();
			}
		}

		extern(DOTNET) void SavePng(byte[] data, int w, int h, string path)
		{
			// flip r and b
			int size = w * h * 4;
			for (var i = 0; i < size; i += 4)
			{
				var a = data[i];
				var b = data[i + 2];
				data[i] = b;
				data[i + 2] = a;
			}

			IntPtr buffer =  Fuse.Drawing.DotNetNative.Marshal.UnsafeAddrOfPinnedArrayElement(data, 0);
			var image = new Bitmap(w, h, w * 4, PixelFormat.Format32bppPArgb, buffer);
			image.RotateFlip(RotateFlipType.Rotate180FlipX);
			image.Save(path, ImageFormat.Png);
			image.Dispose();
		}

		extern(CPlusPlus) void SavePng(byte[] data, int w, int h, string path)
		@{
			uImage::Bitmap *bmp = new uImage::Bitmap(w, h, uImage::FormatRGBA_8_8_8_8_UInt_Normalize);
			int pitch = w * 4;
			// OpenGL stores the bottom scan-line first, PNG stores it last. Flip image while copying to compensate.
			for (int y = 0; y < h; ++y) {
				uint8_t *src = ((uint8_t*)data->Ptr()) + y * pitch;
				uint8_t *dst = bmp->GetScanlinePtr(h - y - 1);
				memcpy(dst, src, pitch);
			}
			uCString temp(path);
			uImage::Png::Save(temp.Ptr, bmp);
			delete bmp;
		@}
	}
}