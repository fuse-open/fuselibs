using Uno;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Fuse;
using Fuse.Elements;
using Fuse.Navigation;
using Uno.Compiler.ExportTargetInterop;
namespace Fuse.iOS.Controls
{
	[Require("Source.Include", "iOS/WVNavDelegate.h")]
	static public extern(iOS) class NavDelegate
	{
		[Foreign(Language.ObjC)]
		public static ObjC.Object Create(Action beginLoading, Action pageLoaded, Action urlChanged, Action<string> OnCustomURI, string[] schemes, Func<bool> hasURISchemeHandler)
		@{
			return [[WVNavDelegate alloc] initWithEventHandlers:beginLoading loaded:pageLoaded change:urlChanged uriHandler:OnCustomURI schemes:[schemes copyArray] hasURISchemeHandler:hasURISchemeHandler];
		@}
	}
}
