using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;

namespace Fuse.Controls.Android
{
	extern(ANDROID) internal static class CameraLoader
	{
		class CameraPromise : Promise<Camera>
		{
			CameraFacing _facing;
			int _cameraId;

			public CameraPromise(CameraFacing facing, int cameraId)
			{
				_facing = facing;
				_cameraId = cameraId;
				Load(cameraId, OnLoaded, OnRejected);
			}

			void OnLoaded(Java.Object camera)
			{
				var c = new Camera(camera, _cameraId, _facing);
				if (!_cancelled)
					Resolve(c);
				else
					c.Dispose();
			}

			void OnRejected(string msg)
			{
				if (!_cancelled)
					Reject(new Exception(msg));
			}

			bool _cancelled = false;
			public override void Cancel(bool shutdownGracefully = false)
			{
				_cancelled = true;
			}
		}

		public static Future<Camera> Load(CameraFacing facing)
		{
			int cameraId;
			if (facing.TryGetCameraId(out cameraId))
				return new CameraPromise(facing, cameraId);
			else
			{
				var p = new Promise<Camera>();
				p.Reject(new Exception("Unsupported camerafacing: " + facing.ToString()));
				return p;
			}
		}

		[Foreign(Language.Java)]
		static void Load(int cameraId, Action<Java.Object> resolve, Action<string> reject)
		@{
			try {
				resolve.run(android.hardware.Camera.open(cameraId));
			} catch (final Exception e) {
				reject.run(e.getMessage());
			}
		@}
	}

	[ForeignInclude(Language.Java, "android.hardware.Camera")]
	extern(ANDROID) static class CameraFacingExtension
	{
		public static bool TryGetCameraId(this CameraFacing cameraFacing, out int cameraId)
		{
			cameraId = GetCameraId((int)cameraFacing);
			return cameraId > -1;
		}

		[Foreign(Language.Java)]
		static int GetCameraId(int facing)
		@{
			Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
			for (int i = 0; i < Camera.getNumberOfCameras(); i++)
			{
				Camera.getCameraInfo(i, cameraInfo);
				if (cameraInfo.facing == facing)
					return i;
			}
			return -1;
		@}
	}
}

