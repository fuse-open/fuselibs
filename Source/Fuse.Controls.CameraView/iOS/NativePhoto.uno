using Uno;
using OpenGL;
using Uno.Graphics;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;
using Uno.Threading;
using Uno.Collections;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Controls.CameraView;
using Fuse.Resources.Exif;

namespace Fuse.Controls.iOS
{
	extern(iOS) class NativePhoto : Photo, IDisposable
	{
		IntPtr _sampleBuffer;
		int _orientation;

		public NativePhoto(IntPtr sampleBuffer, int orientation)
		{
			_sampleBuffer = sampleBuffer;
			_sampleBuffer.Retain();
			_orientation = orientation;
		}

		public override Future<string> Save()
		{
			return new SavePromise(_sampleBuffer);
		}

		public override Future<string> SaveThumbnail(ThumbnailSizeHint thumbnailSizeHint = null)
		{
			return new SaveThumbnailPromise(_sampleBuffer, thumbnailSizeHint);
		}

		internal override Future<PhotoTexture> GetTexture()
		{
			return new UploadTexturePromise(_sampleBuffer, _orientation);
		}

		internal override Future<PhotoHandle> GetPhotoHandle()
		{
			return new PhotoHandlePromise(_sampleBuffer, _orientation);
		}

		public override void Release()
		{
			Dispose();
		}

		bool _isDisposed = false;
		public void Dispose()
		{
			if (!_isDisposed)
			{
				_isDisposed = true;
				_sampleBuffer.Release();
				_sampleBuffer = IntPtr.Zero;
			}
		}
	}

	extern(iOS) class NativePhotoHandle : PhotoHandle
	{
		public readonly ObjC.Object UIImage;

		public NativePhotoHandle(ObjC.Object uiImage)
		{
			UIImage = uiImage;
		}
	}

	extern(iOS) class PhotoHandlePromise : CameraPromise<PhotoHandle>
	{
		IntPtr _sampleBuffer;

		public PhotoHandlePromise(IntPtr sampleBuffer, int orientation)
		{
			_sampleBuffer = sampleBuffer;
			_sampleBuffer.Retain();
			Load(_sampleBuffer, CGImageOrientationToUIImageOrientation(orientation), OnResolve);
		}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "CoreMedia/CoreMedia.h")]
		void Load(IntPtr sampleBuffer, int orientation, Action<ObjC.Object> onResolve)
		@{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				CMSampleBufferRef bufferRef = (CMSampleBufferRef)sampleBuffer;
				CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(bufferRef);
				CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)imageBuffer;

				CIImage* ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
				CIContext* ctx = [CIContext contextWithOptions:NULL];
				CGImageRef cgImage = [ctx createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
				UIImage* uiImage = [UIImage imageWithCGImage:cgImage scale:1 orientation: (UIImageOrientation)orientation];
				CGImageRelease(cgImage);
				onResolve(uiImage);
			});
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "ImageIO/CGImageProperties.h")]
		static int CGImageOrientationToUIImageOrientation(int orientation)
		@{
			switch ((CGImagePropertyOrientation)orientation) {
				case kCGImagePropertyOrientationUp: return UIImageOrientationUp;
				case kCGImagePropertyOrientationDown: return UIImageOrientationDown;
				case kCGImagePropertyOrientationLeft: return UIImageOrientationLeft;
				case kCGImagePropertyOrientationRight: return UIImageOrientationRight;
				case kCGImagePropertyOrientationUpMirrored: return UIImageOrientationUpMirrored;
				case kCGImagePropertyOrientationDownMirrored: return UIImageOrientationDownMirrored;
				case kCGImagePropertyOrientationLeftMirrored: return UIImageOrientationLeftMirrored;
				case kCGImagePropertyOrientationRightMirrored: return UIImageOrientationRightMirrored;
			}
		@}

		void OnResolve(ObjC.Object uiImage)
		{
			Resolve(new NativePhotoHandle(uiImage));
			_sampleBuffer.Release();
		}
	}

	extern(iOS) class UploadTexturePromise : CameraPromise<PhotoTexture>
	{
		class NativePhotoTexture : PhotoTexture
		{
			texture2D _texture;
			IntPtr _textureRef;
			IntPtr _textureCacheRef;
			int _orientation;

			public NativePhotoTexture(texture2D texture, IntPtr textureRef, IntPtr textureCacheRef, int orientation)
			{
				_texture = texture;
				_textureRef = textureRef;
				_textureCacheRef = textureCacheRef;
				_orientation = orientation;
			}

			public override ImageOrientation Orientation
			{
				get
				{
					switch (_orientation)
					{
						case 0:
						case 1:
							return ImageOrientation.Identity;
						case 2:
							return ImageOrientation.FlipVertical | ImageOrientation.Rotate180;
						case 3:
							return ImageOrientation.Rotate180;
						case 4:
							return ImageOrientation.FlipVertical;
						case 5:
							return ImageOrientation.FlipVertical | ImageOrientation.Rotate270;
						case 6:
							return ImageOrientation.Rotate90;
						case 7:
							return ImageOrientation.FlipVertical | ImageOrientation.Rotate90;
						case 8:
							return ImageOrientation.Rotate270;
						default:
							throw new Exception("Unexpected orientation: " + _orientation);
					}
				}
			}

			public override texture2D Texture
			{
				get { return _texture; }
			}

			public override void Dispose()
			{
				_texture = null;
				_textureRef.Release();
				_textureRef = IntPtr.Zero;
				_textureCacheRef.Release();
				_textureCacheRef = IntPtr.Zero;
			}
		}

		IntPtr _sampleBuffer;
		int _orientation;
		public UploadTexturePromise(IntPtr sampleBuffer, int orientation)
		{
			_sampleBuffer = sampleBuffer;
			_orientation = orientation;
			_sampleBuffer.Retain();
			GraphicsWorker.Dispatch(Upload);
		}

		void Upload()
		{
			try
			{
				UploadTexture(_sampleBuffer, OnResolve, OnReject);
			}
			finally
			{
				_sampleBuffer.Release();
			}
		}

		void OnResolve(
			int textureName,
			int width,
			int height,
			IntPtr textureRef,
			IntPtr textureCacheRef)
		{
			var texture = new texture2D((GLTextureHandle)textureName, int2(width, height), 1, Format.RGBA8888);
			Resolve(new NativePhotoTexture(texture, textureRef, textureCacheRef, _orientation));
		}

		void OnReject(string msg)
		{
			Reject(new Exception(msg));
		}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "CoreVideo/CVOpenGLESTextureCache.h")]
		[Require("Source.Include", "OpenGLES/ES2/glext.h")]
		[Require("Source.Include", "CoreMedia/CoreMedia.h")]
		static void UploadTexture(IntPtr sampleBuffer, Action<int,int,int,IntPtr,IntPtr> onResolve, Action<string> onReject)
		@{
			CMSampleBufferRef bufferRef = (CMSampleBufferRef)sampleBuffer;
			CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(bufferRef);
			CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)imageBuffer;

			CVOpenGLESTextureRef textureHandle;
			CVOpenGLESTextureCacheRef textureCacheHandle;

			#if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
			CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [EAGLContext currentContext], NULL, &textureCacheHandle);
			#else
			CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[EAGLContext currentContext], NULL, &textureCacheHandle);
			#endif

			if (err != kCVReturnSuccess) {
				onReject([NSString stringWithFormat:@"Failed to create CVOpenGLESTextureCache, error code: %d", err]);
				return;
			}

			GLsizei width = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
			GLsizei height = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);

			glActiveTexture(GL_TEXTURE0);
			err = CVOpenGLESTextureCacheCreateTextureFromImage(
				kCFAllocatorDefault,
				textureCacheHandle,
				pixelBuffer,
				NULL,
				GL_TEXTURE_2D,
				GL_RGBA,
				width,
				height,
				GL_BGRA,
				GL_UNSIGNED_BYTE,
				0,
				&textureHandle);

			if (err != kCVReturnSuccess) {
				onReject([NSString stringWithFormat:@"Failed to create texture from image, error code: %d", err]);
				return;
			}

			glBindTexture(CVOpenGLESTextureGetTarget(textureHandle), CVOpenGLESTextureGetName(textureHandle));
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

			onResolve(CVOpenGLESTextureGetName(textureHandle), (uint32_t)width, (uint32_t)height, textureHandle, textureCacheHandle);
		@}
	}

	extern(iOS) class SavePromise : CameraPromise<string>
	{
		public SavePromise(IntPtr sampleBuffer)
		{
			Save(sampleBuffer, OnResolve, OnReject);
		}

		[Foreign(Language.ObjC)]
		[Require("Xcode.Framework", "MobileCoreServices")]
		[Require("Source.Include", "MobileCoreServices/MobileCoreServices.h")]
		[Require("Source.Include", "ImageIO/CGImageDestination.h")]
		[Require("Source.Include", "CoreMedia/CoreMedia.h")]
		static void Save(IntPtr sampleBuffer, Action<string> resolve, Action<string> reject)
		@{
			CFRetain(sampleBuffer);
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				CMSampleBufferRef bufferRef = (CMSampleBufferRef)sampleBuffer;
				CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(bufferRef);
				CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)imageBuffer;

				CIImage* ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
				CIContext* ctx = [CIContext contextWithOptions:NULL];
				CGImageRef cgImage = [ctx createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];

				NSData* data = NULL;

				// The CMAttachments associated with the samplebuffer does not follow along
				// when creating a CGImage from the buffer. These attachments contains the EXIF
				// data. If they exists we copy them manually to the output image
				CFDictionaryRef attachments = (CFDictionaryRef)CMCopyDictionaryOfAttachments(kCFAllocatorDefault, bufferRef, kCMAttachmentMode_ShouldPropagate);
				if (attachments) {
					NSMutableData* destinationData = [NSMutableData data];
					CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)destinationData, kUTTypeJPEG, 1, NULL);
					if (destination) {
						CGImageDestinationAddImage(destination, cgImage, attachments);
						BOOL success = CGImageDestinationFinalize(destination);
						if (success) {
							data = destinationData;
						}
						CFRelease(destination);
					}
					CFRelease(attachments);
				}

				if (!data) {
					UIImage* uiImage = [UIImage imageWithCGImage:cgImage];
					data = UIImageJPEGRepresentation(uiImage, 1.0f);
				}

				CGImageRelease(cgImage);
				CFRelease(sampleBuffer);

				NSString* ext = @"jpg";
				NSString* uuid = [[NSUUID UUID] UUIDString];
				NSString* dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
				NSString* path = [NSString stringWithFormat:@"%@/IMG_%@.%@", dir, uuid, ext];

				NSError* error = nil;
				if (![data writeToFile:path options:NSDataWritingWithoutOverwriting error:&error]) {
					reject([NSString stringWithFormat:@"Failed to save image: %@", error]);
				} else {
					resolve(path);
				}
			});
		@}

		void OnResolve(string filePath) { Resolve(filePath); }
		void OnReject(string msg) { Reject(new Exception(msg)); }
	}

	extern(iOS) class SaveThumbnailPromise : CameraPromise<string>
	{
		public SaveThumbnailPromise(IntPtr sampleBuffer, ThumbnailSizeHint thumbnailSizeHint)
		{
			var widthHint = 0.0f;
			var heightHint = 0.0f;
			var useSizeHint = false;
			if (thumbnailSizeHint != null)
			{
				var pixelsPerPoint = Fuse.App.Current.RootViewport.PixelsPerPoint;
				widthHint = Math.Max(thumbnailSizeHint.Width, 8) * pixelsPerPoint;
				heightHint = Math.Max(thumbnailSizeHint.Height, 8) * pixelsPerPoint;
				useSizeHint = true;
			}
			SaveThumbnail(
				sampleBuffer,
				Resolve,
				OnReject,
				useSizeHint,
				widthHint,
				heightHint);
		}

		void OnReject(string msg) { Reject(new Exception(msg)); }

		[Foreign(Language.ObjC)]
		[Require("Xcode.Framework", "Accelerate")]
		[Require("Xcode.Framework", "MobileCoreServices")]
		[Require("Source.Include", "CoreMedia/CoreMedia.h")]
		[Require("Source.Include", "Accelerate/Accelerate.h")]
		[Require("Source.Include", "MobileCoreServices/MobileCoreServices.h")]
		[Require("Source.Include", "ImageIO/CGImageDestination.h")]
		static void SaveThumbnail(
			IntPtr sampleBuffer,
			Action<string> resolve,
			Action<string> reject,
			bool useSizeHint,
			float widthHint,
			float heightHint)
		@{
			CFRetain(sampleBuffer);
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				CMSampleBufferRef bufferRef = (CMSampleBufferRef)sampleBuffer;
				CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(bufferRef);
				CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)imageBuffer;

				auto width = CVPixelBufferGetWidth(pixelBuffer);
				auto height = CVPixelBufferGetHeight(pixelBuffer);

				CVPixelBufferLockBaseAddress(pixelBuffer, 0);

				vImage_Buffer input = { 0 };
				input.data = CVPixelBufferGetBaseAddress(pixelBuffer);
				input.rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer);
				input.width = width;
				input.height = height;

				CGFloat screenScale = [[UIScreen mainScreen] scale];

				CGFloat targetWidth;
				CGFloat targetHeight;

				if (useSizeHint)
				{
					targetWidth = MIN(widthHint, width);
					targetHeight = MIN(heightHint, height);
				}
				else
				{
					CGRect screenBounds = [[UIScreen mainScreen] bounds];
					targetWidth = (screenBounds.size.width * screenScale) / 2;
					targetHeight = (screenBounds.size.height * screenScale) / 2;
				}

				auto scale = MIN(targetWidth / width, targetHeight / height);

				auto scaledWidth = (vImagePixelCount)ceil(width * scale);
				auto scaledHeight = (vImagePixelCount)ceil(height * scale);

				CVPixelBufferRef scaledPixelBuffer = NULL;
				CVReturn cverr = CVPixelBufferCreate(
					NULL,
					scaledWidth,
					scaledHeight,
					CVPixelBufferGetPixelFormatType(pixelBuffer),
					NULL,
					&scaledPixelBuffer);

				if (cverr != kCVReturnSuccess) {
					CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
					CFRelease(sampleBuffer);

					reject([NSString stringWithFormat:@"Failed to create thumbnail pixelbuffer: %d", cverr]);
					return;
				}

				CVPixelBufferLockBaseAddress(scaledPixelBuffer, 0);

				vImage_Buffer output = { 0 };
				output.data = CVPixelBufferGetBaseAddress(scaledPixelBuffer);
				output.rowBytes = CVPixelBufferGetBytesPerRow(scaledPixelBuffer);
				output.width = scaledWidth;
				output.height = scaledHeight;

				vImage_Error err = vImageScale_ARGB8888(&input, &output, NULL, 0);
				if (err != kvImageNoError) {
					CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
					CVPixelBufferUnlockBaseAddress(scaledPixelBuffer, 0);
					CVPixelBufferRelease(scaledPixelBuffer);
					CFRelease(sampleBuffer);

					reject([NSString stringWithFormat:@"Failed to scale thumbnail: %zd", err]);
					return;
				}

				CIImage* ciImage = [CIImage imageWithCVPixelBuffer:scaledPixelBuffer];
				CIContext* ctx = [CIContext contextWithOptions:NULL];
				CGImageRef cgImage = [ctx createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(scaledPixelBuffer), CVPixelBufferGetHeight(scaledPixelBuffer))];

				NSData* data = NULL;

				CFDictionaryRef attachments = (CFDictionaryRef)CMCopyDictionaryOfAttachments(kCFAllocatorDefault, bufferRef, kCMAttachmentMode_ShouldPropagate);
				if (attachments) {
					NSMutableData* destinationData = [NSMutableData data];
					CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)destinationData, kUTTypeJPEG, 1, NULL);
					if (destination) {
						CGImageDestinationAddImage(destination, cgImage, attachments);
						BOOL success = CGImageDestinationFinalize(destination);
						if (success) {
							data = destinationData;
						}
						CFRelease(destination);
					}
					CFRelease(attachments);
				}

				if (!data) {
					UIImage* uiImage = [UIImage imageWithCGImage:cgImage];
					data = UIImageJPEGRepresentation(uiImage, 1.0f);
				}

				CGImageRelease(cgImage);

				CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
				CVPixelBufferUnlockBaseAddress(scaledPixelBuffer, 0);
				CVPixelBufferRelease(scaledPixelBuffer);

				CFRelease(sampleBuffer);

				NSString* ext = @"jpg";
				NSString* uuid = [[NSUUID UUID] UUIDString];
				NSString* dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
				NSString* path = [NSString stringWithFormat:@"%@/IMG_%@.%@", dir, uuid, ext];

				NSError* error = nil;
				if (![data writeToFile:path options:NSDataWritingWithoutOverwriting error:&error]) {
					reject([NSString stringWithFormat:@"Failed to save thumbnail: %@", error]);
				} else {
					resolve(path);
				}
			});
		@}
	}

	[Require("Source.Include", "Foundation/Foundation.h")]
	extern(iOS) static class CoreFoundationExtensions
	{
		[Foreign(Language.ObjC)]
		public static void Retain(this IntPtr ptr)
		@{
			CFRetain(ptr);
		@}

		[Foreign(Language.ObjC)]
		public static void Release(this IntPtr ptr)
		@{
			CFRelease(ptr);
		@}
	}
}
