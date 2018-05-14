using Uno;
using Uno.UX;
using Uno.Time;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Scripting;
using Fuse.ImageTools;

namespace Fuse.Deprecated
{
	using iOS;
	using Android;

	interface ICameraView
	{
		void SavePicture(ImagePromiseCallback p, PictureResolution res);
		void SwapCamera();
		void StartRecording();
		void StopRecording(VideoPromiseCallback p);
		void UpdateCamera();
		CameraDirection Direction { get; set; }
		bool UseFlash { get; set; }
	}

	/** 
		Cameras only can support front-facing or back-facing.
	*/
	public enum CameraDirection 
	{
		Front = 0,
		Back = 1,
		None = -1
	}

	/**
		A picture resolution can either be taken at the max possible resolution supported by the device, 
		or at the closest resolution to the camera preview. 

		Note that since cameras do not support taking an image at custom resolutions, it may be best to take a full resolution
		picture, and resize it after.
	*/
	public enum PictureResolution 
	{
		Full,
		Preview
	}

	interface ICameraViewHost
	{
	}

	/**
		This callback is used when an image has been captured on the device. 
		If an image is successfully captured, we return an `Image` object containing the path of the image.
		Note that the path is a temporary path, and the image should be moved if desired to be kept.
	*/
	public class ImagePromiseCallback
	{
		Function _p;
		Context _context;
		public ImagePromiseCallback(Function p, Context context)
		{
			_p = p;
			_context = context;
		}

		public void Resolve(string path)
		{
			var image = new Fuse.ImageTools.Image(path);
			var obj = Fuse.ImageTools.Image.Converter(_context, image);

			_p.Call(_context, null, obj);
		}

		public void Reject(string reason)
		{
			_p.Call(_context, reason, null);
		}
	}

	public class VideoPromiseCallback
	{
		Function _p;
		Context _context;
		public VideoPromiseCallback(Function p, Context context)
		{
			_p = p;
			_context = context;
		}

		public void Resolve(string path)
		{
			_p.Call(_context, null, path);
		}

		public void Reject(string reason)
		{
			_p.Call(_context, reason, null);
		}
	}

	/**
		@include Docs/README.md
	*/
	public abstract partial class CameraViewBase : Panel, ICameraViewHost
	{
		static Selector _currentCameraViewName = "CameraView";

		static Selector _cameraDirectionName = "CameraDirection";
		static Selector _cameraDirectionAsStringName = "CameraDirectionAsString";
		static Selector _cameraIsRecordingName = "CameraIsRecording";

		bool _isCurrentlyRecording = false;

		ICameraView CameraView
		{
			get { return NativeView as ICameraView; }
		}

		/**
			Capture a picture from the current camera with the given resolution options
			The callback returns an error if no camera device is existed.
		*/
		public void SavePicture(ImagePromiseCallback p, PictureResolution res)
		{
			if defined(iOS || Android) 
			{
				CameraView.SavePicture(p, res);
				return;
			}

			p.Reject("Cameras are not supported on OSX/Windows");
		}

		/**
			Swap the camera direction to face the opposite direction if supported. 
		*/
		public void SwapCamera()
		{
			if defined(iOS || Android)
			{
				var newDirection = CameraDirection == CameraDirection.Back ? CameraDirection.Front : CameraDirection.Back;

				// Make sure we actually support the correct camera direction
				if (!IsDirectionSupported(newDirection))
					return;

				CameraDirection = newDirection;
				CameraView.SwapCamera();
				OnCameraDirectionChanged();
			}
		}

		public void StartRecording()
		{
			if defined(iOS || Android)
			{
				CameraView.StartRecording();
				_isCurrentlyRecording = true;
				OnPropertyChanged(_cameraIsRecordingName, null);
			}

		}

		public void StopRecording(VideoPromiseCallback p)
		{
			if defined(iOS || Android)
			{
				CameraView.StopRecording(p);
				_isCurrentlyRecording = false;
				OnPropertyChanged(_cameraIsRecordingName, null);
			}

		}

		public static bool IsDirectionSupported(CameraDirection direction)
		{
			var directions = CameraDevice.SupportedDirections;

			for (var i = 0; i < directions.Length; i++)
			{
				if (directions[i] == direction) return true;
			}
			return false;
		}

		// Locking logic taken from nativedatepicker. Unsure if needed, talk to vegard
		CameraDirection _in = CameraDirection.Back;
		CameraDirection _out = CameraDirection.Back;
		public CameraDirection CameraDirection 
		{
			get { return CameraView.Direction; }
			set { 
				lock(this)
					CameraView.Direction = value; 
				OnCameraDirectionChanged();
			}
		}

		public string CameraDirectionAsString
		{
			get { 
				if (CameraView == null) return CameraDirectionToString(CameraDirection.None);

				return CameraDirectionToString(CameraView.Direction); 
			}
		}

		public bool UseFlash
		{
			get { return CameraView.UseFlash; }
			set { 
				lock (this)
					CameraView.UseFlash = value;
			}
		}

		string _facing = "Back";
		public string Facing 
		{
			get { return _facing; }
			set { _facing = value; }
		}

		internal void OnCameraDirectionChanged()
		{
			lock(this)
				_out = CameraDirection;
			OnPropertyChanged(_cameraDirectionName, null);
			OnPropertyChanged(_cameraDirectionAsStringName, null);
		}

		void UpdateCameraDirection()
		{
			lock(this)
				CameraDirection = _in;
				CameraView.UpdateCamera();
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if defined(iOS || Android) 
			{
				CameraDirection direction = CameraDirectionFromString(_facing);
				_in = direction;
				UpdateCameraDirection();

				_out = CameraDirection;
				OnCameraDirectionChanged();
				InvalidateLayout();
			}
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
		}

		static string CameraDirectionToString(CameraDirection direction)
		{
			if (direction == CameraDirection.Front) 
				return "Front"; 
			else if (direction == CameraDirection.Back)
				return "Back";

			return "None";
		}

		static CameraDirection CameraDirectionFromString(string direction)
		{
			if (direction == "Front")
				return CameraDirection.Front;
			else if (direction == "Back")
				return CameraDirection.Back;
			else if (direction == "None")
				return CameraDirection.None;

			return CameraDirection.None;
		}
	}
}
