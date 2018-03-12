using System;
using System.Runtime.InteropServices;
using Fuse.Video.CILInterface;

namespace Fuse.Video.Mono
{
	public enum CVPixelBufferLockFlags
	{
		kCVPixelBufferLock_ReadOnly = 0x00000001,
	};

	public class PixelBuffer : IDisposable
	{
		public int Width
		{
			get { return (int)PixelBufferImpl.CVPixelBufferGetWidth(_handle); }
		}

		public int BytesPerRow
		{
			get { return (int)PixelBufferImpl.CVPixelBufferGetBytesPerRow(_handle); }
		}

		public int Height
		{
			get { return (int)PixelBufferImpl.CVPixelBufferGetHeight(_handle); }
		}

		private readonly IGL _gl;
		readonly IntPtr _handle;

		public PixelBuffer(IGL gl, IntPtr handle)
		{
			_gl = gl;
			_handle = handle;
			if (_handle == IntPtr.Zero)
				throw new ArgumentNullException();
		}

		public void CopyPixels(byte[] pixels)
		{
			var size = PixelBufferImpl.CVPixelBufferGetBytesPerRow(_handle).ToInt32() * Height;

			if (size == 0)
				return;

			if (pixels.Length != size)
				throw new ArgumentOutOfRangeException("pixel buffer invalide size");

			PixelBufferImpl.CVPixelBufferLockBaseAddress(_handle, CVPixelBufferLockFlags.kCVPixelBufferLock_ReadOnly);

			Marshal.Copy(
				PixelBufferImpl.CVPixelBufferGetBaseAddress(_handle),
				pixels,
				0,
				size);

			PixelBufferImpl.CVPixelBufferUnlockBaseAddress(_handle, CVPixelBufferLockFlags.kCVPixelBufferLock_ReadOnly);
		}


		/*public void UpdateTexture(int textureName)
		{
			GL.BindTexture(TextureTarget.Texture2D, textureName);
			PixelBufferImpl.CVPixelBufferLockBaseAddress(_handle, CVPixelBufferLockFlags.kCVPixelBufferLock_ReadOnly);
			GL.TexImage2D(
				TextureTarget.Texture2D,
				0,
				PixelInternalFormat.Rgba,
				Width,
				Height,
				0,
				PixelFormat.Bgra,
				PixelType.UnsignedByte,
				PixelBufferImpl.CVPixelBufferGetBaseAddress(_handle));
			PixelBufferImpl.CVPixelBufferUnlockBaseAddress(_handle, CVPixelBufferLockFlags.kCVPixelBufferLock_ReadOnly);
		}*/

		public void UpdateTexture(int textureName, VideoHandle handle)
		{
			var width = Width;
			var height = Height;
			var bytesPerRow = BytesPerRow;
			var actualBytesPerRow = width * 4;

			PixelBufferImpl.CVPixelBufferLockBaseAddress(_handle, CVPixelBufferLockFlags.kCVPixelBufferLock_ReadOnly);

			var baseAddress = PixelBufferImpl.CVPixelBufferGetBaseAddress (_handle);
			var sourceAddress = baseAddress;
			var sourceOffset = 0;
			var destOffset = 0;

			for (int y = 0; y < height; y++)
			{
				sourceOffset = y * bytesPerRow;
				destOffset = y * actualBytesPerRow;
				sourceAddress = new IntPtr (baseAddress.ToInt64() + (Int64)sourceOffset);
				Marshal.Copy (sourceAddress, handle.Pixels, destOffset, actualBytesPerRow);
			}

			PixelBufferImpl.CVPixelBufferUnlockBaseAddress(_handle, CVPixelBufferLockFlags.kCVPixelBufferLock_ReadOnly);

			var pinnedArray = GCHandle.Alloc (handle.Pixels, GCHandleType.Pinned);

			_gl.BindTexture((int)TextureTarget.Texture2D, (int)textureName);
			if (width != handle.WidthCache || height != handle.HeightCache)
			{
				handle.WidthCache = width;
				handle.HeightCache = height;
				_gl.TexImage2D(
					(int)TextureTarget.Texture2D,
					0,
					(int)PixelInternalFormat.Rgba,
					width,
					height,
					0,
					(int)PixelFormat.Bgra,
					(int)PixelType.UnsignedByte,
					pinnedArray.AddrOfPinnedObject());
			}
			else
			{
				_gl.TexSubImage2D(
					(int)TextureTarget.Texture2D,
					0,
					0,
					0,
					width,
					height,
					(int)PixelFormat.Bgra,
					(int)PixelType.UnsignedByte,
					pinnedArray.AddrOfPinnedObject());
			}

			pinnedArray.Free();
		}

		public void Dispose()
		{
			PixelBufferImpl.CVBufferRelease(_handle);
		}
	}

	static class PixelBufferImpl
	{
		[DllImport("/System/Library/Frameworks/CoreVideo.framework/CoreVideo")]
		public static extern void CVPixelBufferLockBaseAddress(IntPtr HandleRef, CVPixelBufferLockFlags flags);

		[DllImport("/System/Library/Frameworks/CoreVideo.framework/CoreVideo")]
		public static extern void CVPixelBufferUnlockBaseAddress(IntPtr HandleRef, CVPixelBufferLockFlags flags);

		[DllImport("/System/Library/Frameworks/CoreVideo.framework/CoreVideo")]
		public static extern IntPtr CVPixelBufferGetHeight(IntPtr handle);

		[DllImport("/System/Library/Frameworks/CoreVideo.framework/CoreVideo")]
		public static extern IntPtr CVPixelBufferGetWidth(IntPtr handle);

		[DllImport("/System/Library/Frameworks/CoreVideo.framework/CoreVideo")]
		public static extern IntPtr CVPixelBufferGetBaseAddress(IntPtr handle);

		[DllImport("/System/Library/Frameworks/CoreVideo.framework/CoreVideo")]
		public static extern IntPtr CVPixelBufferGetBytesPerRow(IntPtr handle);

		[DllImport("/System/Library/Frameworks/CoreVideo.framework/CoreVideo")]
		public static extern void CVBufferRelease(IntPtr handle);
	}
}

