using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;

namespace Fuse.Share
{
	/**
	@scriptmodule FuseJS/Share

	Cross-app content sharing API for mobile targets.
	Supports sharing of raw text, and files with associated [mimetype](http://www.iana.org/assignments/media-types/media-types.xhtml).

	Uses Action Sheet on iOS and ACTION_SEND Intents on Android.

	You need to add a reference to "Fuse.Share" in your project file to use this feature.

	## Example

		<JavaScript>
			var Share = require("FuseJS/Share")
			var Camera = require("FuseJS/Camera")
			module.exports = {
				shareFile : function()
				{
					Camera.takePicture(320,240)
					.then(function(image) {
						Share.shareFile(image.path, "image/*", "Photo from Fuse");
					});
				},
				shareText : function()
				{
					Share.shareText("https://www.fusetools.com/", "The link to Fuse website");
				}
			}
		</JavaScript>
	*/
	[UXGlobalModule]
	public class ShareModule : NativeModule
	{
		static readonly ShareModule _instance;
		public ShareModule() : base()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Share");

			AddMember(new NativeFunction("shareText", ShareText));
			AddMember(new NativeFunction("shareFile", ShareFile));
		}

		/**
			Share raw text to another application.
			@scriptmethod shareText(text, description)
			@param text (string) The text to share
			@param description (string) A short user-facing description for the share dialog
		*/
		object ShareText(Context c, object[] args)
		{
			if(args.Length < 1) return false;
			var textToShare = "" + args[0];
			var description = args.Length>1 ? "" + args[1] : "";

			if defined(android)
			{
				AndroidShareImpl.ShareText(textToShare, description);
				return true;
			}
			else if defined(iOS)
			{
				iOSShareImpl.ShareText(textToShare, description);
				return true;
			}
			else
			{
				return false;
			}
		}

		/**
			Share a file to another application by path.
			@scriptmethod shareFile(path, mimetype, description)
			@param path (string) The path to the file to share
			@param mimetype (string) The data format mimetype (eg. 'image/jpeg', 'text/plain' etc)
			@param description (string) A short user-facing description for the share dialog
		*/
		object ShareFile(Context c, object[] args)
		{
			if(args.Length < 1) return false;
			var path = args[0] as string;
			var type = args[1] as string;
			if(type==null)
				throw new Uno.Exception("Second argument of ShareFile must be a mimetype string");
			var description = args.Length>1 ? "" + args[1] : "";

			if (path==null)
				return false;

			if defined(android)
			{
				AndroidShareImpl.ShareFile("file://" + path, type, description);
				return true;
			}
			else if defined(iOS)
			{
				iOSShareImpl.ShareFile("file://" + path, type, description);
				return true;
			}
			else
			{
				return false;
			}
		}
	}
}
