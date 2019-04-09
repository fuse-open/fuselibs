using Uno.Threading;
using Uno;
using Uno.UX;
using Fuse.Scripting;
using Fuse.Scripting.JSObjectUtils;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.VideoTools
{
	/**
		@scriptmodule FuseJS/VideoTools

		Utility methods for video files manipulation. Currently only supports moving a video file to the camera roll.
		
		> To use this module, add `Fuse.CameraView` to your package references in your `.unoproj`.


		## Example

			<JavaScript>
				var VideoTools = require("FuseJS/VideoTools");

				VideoTools.copyVideoToCameraRoll(somePath);
			</JavaScript>
	*/
	[UXGlobalModule]
	public class VideoTools : NativeModule
	{

		static readonly VideoTools _instance;

		public VideoTools()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/VideoTools");
			AddMember(new NativeFunction("copyVideoToCameraRoll", CopyVideoToCameraRoll));
		}

		/**
			Copy a video to the camera roll.

			@scriptmethod copyVideoToCameraRoll(videoPath)
		*/
		object CopyVideoToCameraRoll(Context c, object[] args)
		{
			if(args.Length < 1) return false;

			if defined(iOS)
			{
				return iOSVideoTools.SaveVideo(args[0].ToString());
			}
			else if defined (Android)
			{
				return AndroidVideoTools.SaveVideo(args[0].ToString());
			}
			else
			{
				return false;
			}
		}

		extern (iOS) internal class iOSVideoTools 
		{
			[Require("Xcode.Framework", "AssetsLibrary")]
			[Require("Source.Include", "AssetsLibrary/AssetsLibrary.h")]
			[Foreign(Language.ObjC)]
			extern (iOS) public static bool SaveVideo(string outputFileURL)
			@{
				NSURL *url = [NSURL URLWithString:outputFileURL];
				ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
				if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:url])
				{
					[library writeVideoAtPathToSavedPhotosAlbum:url
											completionBlock:^(NSURL *assetURL, NSError *error)
					{
						[library writeVideoAtPathToSavedPhotosAlbum:url
												completionBlock:^(NSURL *assetURL, NSError *error)
						{
							if (error)
							{
							}
						}];
					}];
				}
				else 
				{
					return false;
				}

				return true;
			@}
		}

		[ForeignInclude(Language.Java, 
			"android.os.Environment", 
			"java.io.File",
			"android.media.MediaScannerConnection"
		)]
		extern (Android) internal class AndroidVideoTools 
		{
			[Foreign(Language.Java)]
			public static bool SaveVideo(string outputFileURL)
			@{
				String filename = "";
				File originalFile;
				File destinationFile;

				try {
					originalFile = new File(outputFileURL);
				} catch (Exception e) {
					return false;
				}

				String outPath = null;
				String state = Environment.getExternalStorageState();

				if(Environment.MEDIA_MOUNTED.equals(state))
					outPath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES) + "/" + originalFile.getName();
				else
					outPath = com.fuse.Activity.getRootActivity().getFilesDir().getAbsolutePath() + "/" + originalFile.getName();
				
				try {
					destinationFile = new File(outPath);
				} catch (Exception e) {
					return false;
				}

				boolean managed = originalFile.renameTo(destinationFile);

				if (managed)
					MediaScannerConnection.scanFile(com.fuse.Activity.getRootActivity(), new String[] { outPath }, null, null);

				return managed;
			@}
		}
	}
}
