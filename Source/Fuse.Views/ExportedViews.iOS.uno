using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Views
{
	[Require("Source.Include", "iOS/ExportedViews.h")]
	[Require("Source.Include", "iOS/ViewHandleImpl.h")]
	[Require("Source.Include", "iOS/ViewHost.h")]
	extern(LIBRARY && iOS)
	internal class ExportedViews
	{
		static ExportedViews _instance;

		public static ExportedViews Instance
		{
			get
			{
				if (_instance == null)
					throw new Exception("ExportedViews not initialized!");
				return _instance;
			}
		}

		public static void Initialize(Func<string,Template> findTemplate)
		{
			_instance = new ExportedViews(findTemplate);
		}

		Func<string,Template> _findTemplate;

		ExportedViews(Func<string,Template> findTemplate)
		{
			_findTemplate = findTemplate;
			InitializeiOS(Instantiate);
		}

		[Foreign(Language.ObjC)]
		void InitializeiOS(Func<string,ObjC.Object> instantiate)
		@{
			[::ExportedViews initialize:^ViewHandle* (NSString* templateName) { return (ViewHandle*)instantiate(templateName); }];
		@}

		ObjC.Object Instantiate(string templateName)
		{
			var t = _findTemplate(templateName);
			if (t == null)
				return null;

			var visual = t.New() as Visual;
			if (visual == null)
				return null;

			var view = new View(visual);
			var nativeView = view.GetNativeView();

			return WrapView(view, nativeView);
		}

		[Foreign(Language.ObjC)]
		ObjC.Object WrapView(Object handle, ObjC.Object nativeView)
		@{
			return [[ViewHandleImpl alloc] initWith:handle withViewHost:(ViewHost*)nativeView];
		@}

	}
}