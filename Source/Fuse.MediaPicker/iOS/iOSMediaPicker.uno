using Uno.Threading;
using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.MediaPicker
{
	[Require("source.include", "iOS/FOMediaPicker.h")]
	public extern(iOS) class iOSMediaPicker
	{
		internal static void PickImage(Promise<string> p, ObjC.Object args)
		{
			var cb = new StringPromiseCallback(p);
			PickImageInternal(args, cb.Resolve, cb.Reject);
		}

		internal static void PickVideo(Promise<string> p, ObjC.Object args)
		{
			var cb = new StringPromiseCallback(p);
			PickVideoInternal(args, cb.Resolve, cb.Reject);
		}

		[Foreign(Language.ObjC)]
		static void PickImageInternal(ObjC.Object args, Action<string> onComplete, Action<string> onFail)
		@{
			dispatch_async(dispatch_get_main_queue(), ^{
				NSDictionary* arguments = (NSDictionary *)args;
				int maxImages = [[arguments objectForKey:@"maxImages"] intValue];
				if (maxImages == 1)
					[[FOMediaPicker instance] pickSingleImageWithArgs:arguments withResult:onComplete error:onFail];
				else
					[[FOMediaPicker instance] pickMultiImageWithArgs:arguments withResult:onComplete error:onFail];
			});
		@}

		[Foreign(Language.ObjC)]
		static void PickVideoInternal(ObjC.Object args, Action<string> onComplete, Action<string> onFail)
		@{
			dispatch_async(dispatch_get_main_queue(), ^{
				[[FOMediaPicker instance] pickVideoWithArgs:args withResult:onComplete error:onFail];
			});
		@}

	}
}
