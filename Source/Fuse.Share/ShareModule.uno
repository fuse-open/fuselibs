using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;
using Fuse.Elements;

namespace Fuse.Share
{
	/**
	@scriptmodule FuseJS/Share

	Cross-app content sharing API for mobile targets.
	Supports sharing of raw text, and files with associated [mimetype](http://www.iana.org/assignments/media-types/media-types.xhtml).

	Uses Action Sheet on iOS and ACTION_SEND Intents on Android.

	NB: on iPad, iOS design guidelines requires a point on screen as the origin for the share popover. You can do this by passing a reference to a UX element.

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

	## iPad example

		<Panel>
			<Button Text="Share" Clicked="{shareText}"/>
			<Panel ux:Name="ShareOrigin" Alignment="Center" Width="1" Height="1" />
			<JavaScript>
				var Share = require("FuseJS/Share")
				module.exports = {
					shareText : function()
					{
						// The iOS popover will use the position of ShareOrigin as its spawn origin
						Share.shareText("https://www.fusetools.com/", "The link to Fuse website", ShareOrigin);
					}
				}
			</JavaScript>
		</Panel>
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

			if defined(android || iOS)
			{
				var textToShare = "" + args[0];
				var description = args.Length>1 ? "" + args[1] : "";

				if defined(android)
				{
					AndroidShareImpl.ShareText(textToShare, description);
					return true;
				}
				else if defined(iOS)
				{
					float2 position = float2(0);
					if (args.Length > 2 && TryGetPosition(args[2], out position))
						iOSShareImpl.ShareText(textToShare, description, position);
					else
						iOSShareImpl.ShareText(textToShare, description);
					return true;
				}
				else
					build_error;
			}

			return false;
		}

		bool TryGetPosition(object arg, out float2 position)
		{
			position = float2(0.0f);
			var obj = arg as Fuse.Scripting.Object;
			if (obj != null && obj.ContainsKey("external_object"))
			{
				var element = ((Fuse.Scripting.External)obj["external_object"]).Object as Element;
				if (element != null)
				{
					var pos = element.ActualPosition;
					var size = element.ActualSize;
					position = pos + size * 0.5f;
					return true;
				}
			}
			return false;
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

			if (path==null)
				return false;

			if defined(android || iOS)
			{
				var description = args.Length>2 ? "" + args[2] : "";
				if defined(android)
				{
					AndroidShareImpl.ShareFile(path, type, description);
					return true;
				}
				else if defined(iOS)
				{
					float2 position = float2(0);
					if (args.Length > 3 && TryGetPosition(args[3], out position))
						iOSShareImpl.ShareFile("file://" + path, type, description, position);
					else
						iOSShareImpl.ShareFile("file://" + path, type, description);
					return true;
				}
				else
					build_error;
			}
			return false;
		}
	}
}
