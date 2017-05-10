using Uno.Threading;
using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
namespace Fuse.Audio
{
	[Require("Source.Include", "Apple/AudioHelper.h")]
	[Set("FileExtension", "mm")]
	internal extern(iOS) class SoundPlayer
	{
		public static void PlaySoundFromBundle(BundleFileSource file)
		{
			PlaySoundFromUrl("data/" + file.BundleFile.BundlePath);
		}

		[Foreign(Language.ObjC)]
		static void PlaySoundFromUrl(string url)
		@{
			NSURL* uri = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[StrongUnoObject class]] pathForResource:url ofType:nil]];
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[[AudioHelper getInstance] playSoundFromFile:uri];
			});
		@}

		public static void PlaySoundFromByteArray(byte[] byteArray)
		@{
			uArray* arr = $0;
			NSData* data = [NSData dataWithBytes:arr->Ptr() length:arr->Length()];
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[[AudioHelper getInstance] playSound:data];
			});
		@}
	}
}
