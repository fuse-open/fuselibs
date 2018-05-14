using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Views
{
	extern(LIBRARY && Android)
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
			InitializeAndroid();
			_findTemplate = findTemplate;
		}

		[Foreign(Language.Java)]
		void InitializeAndroid()
		@{
			com.fuse.views.ExportedViews.initialize(new com.fuse.views.internal.IExportedViews() {
				public com.fuse.views.ViewHandle instantiate(String uxClassName) {
					return (com.fuse.views.ViewHandle)@{global::Fuse.Views.ExportedViews:Of(_this).Instantiate(string):Call(uxClassName)};
				}
			});
		@}

		Java.Object Instantiate(string uxClassName)
		{
			var t = _findTemplate(uxClassName);
			if (t == null)
				return null;

			var visual = t.New() as Visual;
			if (visual == null)
				return null;

			var view = new View(visual);
			var nativeView = view.GetNativeView();

			return WrapView(view, nativeView);
		}

		[Foreign(Language.Java)]
		Java.Object WrapView(Object handle, Java.Object nativeView)
		@{
			return new com.fuse.views.ViewHandle(handle, (com.fuse.views.internal.FuseView)nativeView);
		@}

	}
}