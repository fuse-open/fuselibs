using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
namespace Fuse.Share
{
	public extern(iOS) class iOSShareImpl
	{
		[Foreign(Language.ObjC)]
		public static void ShareText(string text, string description)
		@{
			UIActivityViewController* activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[text] applicationActivities:nil];
			dispatch_async(dispatch_get_main_queue(), ^{
				if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
					activityVC.popoverPresentationController.sourceView = [[[UIApplication sharedApplication] keyWindow] rootViewController].view;
				[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:activityVC animated:YES completion:nil];
			});
		@}

		[Foreign(Language.ObjC)]
		public static void ShareFile(string path, string mimeType,  string description)
		@{
			NSURL* url = [NSURL URLWithString:path];
			UIActivityViewController* activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];

			dispatch_async(dispatch_get_main_queue(), ^{
				if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
					activityVC.popoverPresentationController.sourceView = [[[UIApplication sharedApplication] keyWindow] rootViewController].view;
				[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:activityVC animated:YES completion:nil];
			});
		@}
	}
}
