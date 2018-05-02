using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
namespace Fuse.Share
{
	internal extern(iOS) class iOSShareImpl
	{
		public static void ShareText(string text, string description)
		{
			if (IsIPad())
				Fuse.Diagnostics.UserWarning("iPad requires a position as the spawn origion of the Share popover", text + " - " + description);

			Present(NewShareTextActivity(text, description), false, 0, 0);
		}

		public static void ShareText(string text, string description, float2 position)
		{
			Present(NewShareTextActivity(text, description), true, position.X, position.Y);
		}

		public static void ShareFile(string path, string mimeType, string description)
		{
			if (IsIPad())
				Fuse.Diagnostics.UserWarning("iPad requires a position as the spawn origion of the Share popover", path + " - " + mimeType + " - " + description);

			Present(NewShareFileActivity(path, mimeType, description), false, 0, 0);
		}

		public static void ShareFile(string path, string mimeType, string description, float2 position)
		{
			Present(NewShareFileActivity(path, mimeType, description), true, position.X, position.Y);
		}

		[Foreign(Language.ObjC)]
		static bool IsIPad()
		@{
			return UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object NewShareTextActivity(string text, string description)
		@{
			NSArray* sharedObjects=@[text, description];
			return [[UIActivityViewController alloc] initWithActivityItems:sharedObjects applicationActivities:nil];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object NewShareFileActivity(string path, string mimeType, string description)
		@{
			NSArray* sharedObjects=@[[NSURL URLWithString:path], description];
			return [[UIActivityViewController alloc] initWithActivityItems:sharedObjects applicationActivities:nil];
		@}

		[Foreign(Language.ObjC)]
		static void Present(ObjC.Object activityController, bool hasPosition, float x, float y)
		@{
			UIActivityViewController* activityVC = (UIActivityViewController*)activityController;
			dispatch_async(dispatch_get_main_queue(), ^{
				if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
				{
					activityVC.popoverPresentationController.sourceView = [[[UIApplication sharedApplication] keyWindow] rootViewController].view;
					if (hasPosition)
						activityVC.popoverPresentationController.sourceRect = CGRectMake(x, y, 1, 1);
				}
				[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:activityVC animated:YES completion:nil];
			});
		@}
	}
}
