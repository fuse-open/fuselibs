using Uno;
using OpenGL;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
using Uno.Graphics;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Resources.Exif;

namespace Fuse.Controls.Android
{
	[ForeignInclude(Language.Java,
		"com.fuse.camera.ImageStorageTools",
		"java.io.File",
		"java.io.FileOutputStream")]
	extern(ANDROID) class NativePhoto : Photo
	{
		Java.Object _byteArray;

		public NativePhoto(Java.Object byteArray)
		{
			_byteArray = byteArray;
		}

		public override Future<string> Save()
		{
			return new SavePromise(_byteArray);
		}

		public override Future<string> SaveThumbnail(ThumbnailSizeHint thumbnailSizeHint = null)
		{
			return new SaveThumbnailPromise(_byteArray, thumbnailSizeHint);
		}

		class UploadTexturePromise : CameraPromise<PhotoTexture>
		{
			class AndroidPhotoTexture : PhotoTexture
			{
				public override ImageOrientation Orientation { get { return _orientation; } }
				public override texture2D Texture { get { return _texture; } }
				public override void Dispose()
				{
					if (_texture != null)
					{
						_texture.Dispose();
						_texture = null;
					}
				}

				texture2D _texture;
				ImageOrientation _orientation;

				public AndroidPhotoTexture(texture2D texture, ImageOrientation orientation)
				{
					_texture = texture;
					_orientation = orientation;
				}
			}

			Java.Object _byteArray;

			public UploadTexturePromise(Java.Object byteArray)
			{
				_byteArray = byteArray;
				GraphicsWorker.Dispatch(Upload);
			}

			void Upload()
			{
				var orientation = ExifData.FromAndroidInputStream(GetInputStream(_byteArray)).Orientation;

				var bitmap = DecodeJpegBytes(OnReject, _byteArray);
				if (State != FutureState.Pending)
					return;

				var textureName = GL.CreateTexture();
				GL.BindTexture(GLTextureTarget.Texture2D, textureName);

				Upload(OnReject, bitmap);
				if (State != FutureState.Pending)
				{
					GL.DeleteTexture(textureName);
					return;
				}
				Resolve(new AndroidPhotoTexture(new texture2D((GLTextureHandle)textureName, int2(GetWidth(bitmap), GetHeight(bitmap)), 1, Format.RGBA8888), orientation));
			}

			void OnReject(string msg)
			{
				Reject(new Exception(msg));
			}

			[Foreign(Language.Java)]
			static int GetWidth(Java.Object bitmap)
			@{
				return ((android.graphics.Bitmap)bitmap).getWidth();
			@}

			[Foreign(Language.Java)]
			static int GetHeight(Java.Object bitmap)
			@{
				return ((android.graphics.Bitmap)bitmap).getHeight();
			@}

			[Foreign(Language.Java)]
			static void Upload(Action<string> onReject, Java.Object bitmap)
			@{
				try {
					android.opengl.GLUtils.texImage2D(android.opengl.GLES20.GL_TEXTURE_2D, 0, (android.graphics.Bitmap)bitmap, 0);
				} catch (Exception e) {
					onReject.run("Failed to upload texture: " + e.getMessage());
				}
			@}

			[Foreign(Language.Java)]
			static Java.Object DecodeJpegBytes(Action<string> onReject, Java.Object byteArray)
			@{
				try {
					byte[] jpegBytes = (byte[])byteArray;
					return android.graphics.BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.length);
				} catch(Exception e) {
					onReject.run("Failed to decode jpeg byte array: " + e.getMessage());
					return null;
				}
			@}
		}

		internal override Future<PhotoTexture> GetTexture()
		{
			return new UploadTexturePromise(_byteArray);
		}

		internal override Future<PhotoHandle> GetPhotoHandle()
		{
			return new PhotoHandlePromise(_byteArray);
		}

		[ForeignInclude(Language.Java,
			"java.lang.Thread",
			"java.lang.Runnable",
			"java.io.InputStream",
			"java.io.ByteArrayInputStream",
			"android.media.ExifInterface",
			"android.graphics.Bitmap",
			"android.graphics.BitmapFactory",
			"android.graphics.Matrix")]
		class PhotoHandlePromise : CameraPromise<PhotoHandle>
		{
			public PhotoHandlePromise(Java.Object byteArray)
			{
				var orientation = ExifData.FromAndroidInputStream(GetInputStream(byteArray)).Orientation;
				var matrix = GetOrientationMatrix(orientation);
				Load(byteArray, matrix, OnResolve, OnReject);
			}

			[Foreign(Language.Java)]
			void Load(Java.Object byteArray, float[] matrix, Action<Java.Object> onResolve, Action<string> onReject)
			@{
				new Thread(
					new Runnable() {
						public void run() {
							try {
								byte[] array = (byte[])byteArray;
								Bitmap bitmap = BitmapFactory.decodeByteArray(array, 0, array.length);
								Matrix m = new Matrix();
								m.setValues(matrix.copyArray());
								bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), m, true);
								onResolve.run(bitmap);
							} catch (Exception e) {
								onReject.run(e.getMessage());
							}
						}
					}
				).start();
			@}

			float[] GetOrientationMatrix(ImageOrientation orientation)
			{
				var t = float3x3.Identity;
				if (orientation.HasFlag(ImageOrientation.FlipVertical))
				{
					t.M22 = -1;
					t.M32 =  1;
				}

				if (orientation.HasFlag(ImageOrientation.Rotate180))
				{
					var r = float3x3.Identity;
					r.M11 = r.M22 = Math.Cos(Math.PIf);
					r.M12 = Math.Sin(Math.PIf);
					r.M21 = -r.M12;
					t = Matrix.Mul(t, r);
				}

				if (orientation.HasFlag(ImageOrientation.Rotate90))
				{
					var r = float3x3.Identity;
					r.M11 = r.M22 = Math.Cos(Math.PIf * 0.5f);
					r.M21 = Math.Sin(Math.PIf * 0.5f);
					r.M12 = -r.M21;
					t = Matrix.Mul(t, r);
				}
				return new float[]
				{
					t.M11, t.M12, t.M13,
					t.M21, t.M22, t.M23,
					t.M31, t.M32, t.M33,
				};
			}

			void OnResolve(Java.Object bitmap)
			{
				Resolve(new NativePhotoHandle(bitmap));
			}

			void OnReject(string msg)
			{
				Reject(new Exception(msg));
			}

			[Foreign(Language.Java)]
			static Java.Object GetInputStream(Java.Object byteArray)
			@{
				return new java.io.ByteArrayInputStream((byte[])byteArray);
			@}
		}

		public override void Release()
		{
			_byteArray = null;
		}

		class SavePromise : CameraPromise<string>
		{
			public SavePromise(Java.Object byteArray)
			{
				Save(byteArray, Resolve, OnException);
			}

			void OnException(string message)
			{
				Reject(new Exception(message));
			}

			[Foreign(Language.Java)]
			static void Save(Java.Object byteArray, Action<string> resolve, Action<string> reject)
			@{
				new java.lang.Thread(
					new java.lang.Runnable() {
						public void run() {
							try {
								String filePath = ImageStorageTools.createFilePath("jpeg", true);
								File picture = new File(filePath);
								FileOutputStream fos = new FileOutputStream(picture);
								fos.write((byte[])byteArray);
								fos.close();
								resolve.run(filePath);
							} catch (Exception e) {
								reject.run(e.getMessage());
							}
						}
					}
				).start();
			@}
		}

		[ForeignInclude(Language.Java,
			"com.fuse.camera.ImageStorageTools",
			"java.lang.Thread",
			"java.lang.Runnable",
			"android.graphics.Bitmap",
			"android.graphics.BitmapFactory",
			"android.util.DisplayMetrics",
			"android.media.ExifInterface")]
		class SaveThumbnailPromise : CameraPromise<string>
		{
			Java.Object _byteArray;
			ThumbnailSizeHint _thumbnailSizeHint;

			public SaveThumbnailPromise(Java.Object byteArray, ThumbnailSizeHint thumbnailSizeHint)
			{
				_byteArray = byteArray;
				_thumbnailSizeHint = thumbnailSizeHint;
				RunAsync(SaveThumbnail);
			}

			void SaveThumbnail()
			{
				var androidOrientation = GetAndroidOrientation(_byteArray);
				var useHint = false;
				var widthHint = 0.0f;
				var heightHint = 0.0f;
				if (_thumbnailSizeHint != null)
				{
					var pixelsPerPoint = Fuse.App.Current.RootViewport.PixelsPerPoint;
					widthHint = Math.Max(_thumbnailSizeHint.Width, 8) * pixelsPerPoint;
					heightHint = Math.Max(_thumbnailSizeHint.Height, 8) * pixelsPerPoint;
					useHint = true;
				}
				SaveThumbnail(
					_byteArray,
					androidOrientation,
					Resolve,
					OnReject,
					useHint,
					widthHint,
					heightHint);
				_byteArray = null;
			}

			[Foreign(Language.Java)]
			static void SaveThumbnail(
				Java.Object byteArray,
				int exifOrientation,
				Action<string> resolve,
				Action<string> reject,
				bool useHint,
				float widthHint,
				float heightHint)
			@{
				Bitmap input = null;
				Bitmap output = null;
				try {
					byte[] bytes = (byte[])byteArray;
					input = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);

					DisplayMetrics displayMetrics = new DisplayMetrics();
					com.fuse.Activity.getRootActivity()
						.getWindowManager()
						.getDefaultDisplay()
						.getMetrics(displayMetrics);

					float width = (float)input.getWidth();
					float height = (float)input.getHeight();

					float targetWidth;
					float targetheight;

					if (useHint) {
						targetWidth = Math.min(widthHint, width);
						targetheight = Math.min(heightHint, height);
					} else {
						targetWidth = (float)displayMetrics.widthPixels / 2;
						targetheight = (float)displayMetrics.heightPixels / 2;
					}

					float scale = Math.min(targetWidth / width, targetheight / height);

					int scaledWidth = (int)Math.ceil(width * scale);
					int scaledHeight = (int)Math.ceil(height * scale);

					output = Bitmap.createScaledBitmap(input, scaledWidth, scaledHeight, true);

					String filePath = ImageStorageTools.createFilePath("jpeg", true);
					File picture = new File(filePath);
					FileOutputStream fos = new FileOutputStream(picture);
					output.compress(Bitmap.CompressFormat.JPEG, 100, fos);
					fos.close();

					// Meh..
					ExifInterface exif = new ExifInterface(filePath);
					exif.setAttribute(ExifInterface.TAG_ORIENTATION, Integer.toString(exifOrientation));
					exif.saveAttributes();

					resolve.run(filePath);
				} catch (Exception e) {
					reject.run(e.getMessage());
				}

				if (input != null) {
					input.recycle();
				}

				if (output != null && !output.isRecycled()) {
					output.recycle();
				}
			@}

			void OnReject(string msg) { Reject(new Exception(msg)); }

			static int GetAndroidOrientation(Java.Object bytes)
			{
				var o = ExifData.FromAndroidInputStream(GetInputStream(bytes)).Orientation;
				if (o.HasFlag(ImageOrientation.FlipVertical) && o.HasFlag(ImageOrientation.Rotate180))
					return 2;
				if (o.HasFlag(ImageOrientation.FlipVertical) && o.HasFlag(ImageOrientation.Rotate270))
					return 5;
				if (o.HasFlag(ImageOrientation.FlipVertical) && o.HasFlag(ImageOrientation.Rotate90))
					return 7;
				if (o.HasFlag(ImageOrientation.Rotate180))
					return 3;
				if (o.HasFlag(ImageOrientation.FlipVertical))
					return 4;
				if (o.HasFlag(ImageOrientation.Rotate90))
					return 6;
				if (o.HasFlag(ImageOrientation.Rotate270))
					return 8;
				if (o.HasFlag(ImageOrientation.Identity))
					return 1;
				return 0;
			}

			[Foreign(Language.Java)]
			static void RunAsync(Action callback)
			@{
				new java.lang.Thread(callback).start();
			@}
		}

		[Foreign(Language.Java)]
		static Java.Object GetInputStream(Java.Object byteArray)
		@{
			return new java.io.ByteArrayInputStream((byte[])byteArray);
		@}
	}

	extern(ANDROID) class NativePhotoHandle : PhotoHandle, IDisposable
	{
		Java.Object _bitmap;
		public Java.Object Bitmap
		{
			get
			{
				if (_bitmap == null)
					throw new Exception(this + " has been disposed!");
				return _bitmap;
			}
		}

		public NativePhotoHandle(Java.Object bitmap)
		{
			_bitmap = bitmap;
		}

		public void Dispose()
		{
			if (_bitmap == null)
				return;

			Recycle(_bitmap);
			_bitmap = null;
		}

		[Foreign(Language.Java)]
		static void Recycle(Java.Object bitmap)
		@{
			((android.graphics.Bitmap)bitmap).recycle();
		@}
	}
}
