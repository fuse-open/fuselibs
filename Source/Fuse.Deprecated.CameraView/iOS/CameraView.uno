using Uno;
using Uno.UX;
using Uno.Time;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.ImageTools;
using Fuse.Deprecated.CameraView;

namespace Fuse.Deprecated.iOS
{
	extern(!iOS) class CameraView
	{
		[UXConstructor]
		public CameraView([UXParameter("Host")]ICameraViewHost host) { }
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "AVFoundation/AVFoundation.h")]
	[Require("Source.Include", "iOS/UCameraView.h")]
	[Require("Xcode.Framework", "AssetsLibrary")]
	extern(iOS) class CameraView : Fuse.Controls.Native.iOS.View, ICameraView
	{
		ICameraViewHost _host;

		[UXConstructor]
		public CameraView([UXParameter("Host")]ICameraViewHost host) : base(Create())
		{
			_host = host;
			AttachCamera(Handle);
			UpdateCamera();
		}

		public override void Dispose()
		{
			base.Dispose();
			_host = null;
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			UCameraView* view = [[UCameraView alloc] init];
			view.isBackCamera = true;
			view.isRecording = false;
			return view;
		@}

		[Foreign(Language.ObjC)]
		static void AttachCamera(ObjC.Object viewObject)
		@{
			UCameraView* view = (UCameraView*) viewObject;
			[view startSession];
			[view attachCamera];
		@}

		public void SavePicture(ImagePromiseCallback p, PictureResolution res)
		{
			SavePicture(Handle, p.Resolve, p.Reject, res == PictureResolution.Full, texture2D.MaxSize);
		}

		public void SwapCamera()
		{
			SwapCamera(Handle);
			SetFlash(Handle, _useFlash);
		}

		public void StartRecording()
		{
			StartRecording(Handle);
		}

		public void StopRecording(VideoPromiseCallback p)
		{
			StopRecording(Handle, p.Resolve, p.Reject);
		}

		CameraDirection _direction = CameraDirection.Back;
		public CameraDirection Direction
		{
			get 
			{ 
				return _direction;
			}

			set 
			{
				_direction = value;
			}
		}

		bool _useFlash = false;
		public bool UseFlash
		{
			get { return _useFlash; }

			set 
			{ 
				_useFlash = SetFlash(Handle, value);
			}
		}

		public CameraDirection[] SupportedDirections
		{
			get 
			{
				return CameraDevice.SupportedDirections;
			}
		}

		public void UpdateCamera()
		{
			SetIsBackCamera(Handle, Direction == CameraDirection.Back);
			SetFlash(Handle, _useFlash);
		}

		[Foreign(Language.ObjC)]
		static void SetIsBackCamera(ObjC.Object viewObject, bool isBackCamera)
		@{
			UCameraView* view = (UCameraView*) viewObject;
			[view setCamera:isBackCamera];
		@}

		[Foreign(Language.ObjC)]
		static bool IsBackCamera(ObjC.Object viewObject)
		@{
			UCameraView* view = (UCameraView*) viewObject;
			return view.isBackCamera;
		@}

		[Foreign(Language.ObjC)]
		static void SwapCamera(ObjC.Object viewObject)
		@{
			UCameraView* view = (UCameraView*) viewObject;
			[view swapCamera];
		@}

		[Foreign(Language.ObjC)]
		static void SavePicture(ObjC.Object viewObject, Action<string> onComplete, Action<string> onFail, bool isFullRes, int maxTextureSize)
		@{
			UCameraView* view = (UCameraView*) viewObject;
			[view captureNow: onComplete onFail:onFail isFullRes:isFullRes maxTextureSize:maxTextureSize];
		@}

		[Foreign(Language.ObjC)]
		static void StartRecording(ObjC.Object viewObject)
		@{
			UCameraView* view = (UCameraView*) viewObject;
			[view startRecording];
		@}

		[Foreign(Language.ObjC)]
		static void StopRecording(ObjC.Object viewObject, Action<string> onComplete, Action<string> onFail)
		@{
			UCameraView* view = (UCameraView*) viewObject;
			[view stopRecording: onComplete onFail:onFail];
		@}

		[Foreign(Language.ObjC)]
		static bool SetFlash(ObjC.Object viewObject, bool enableFlash)
		@{
			UCameraView* view = (UCameraView*) viewObject;
			return [view setFlash:enableFlash];
		@}
	}
}
