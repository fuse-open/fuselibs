using Fuse;

namespace Fuse.Controls.Native
{
	extern(iOS || Android)
	internal class NativeRootViewport : RootViewport
	{
		public ViewHandle RootView
		{
			get { return _rootView; }
		}

		ViewHandle _rootView;

		public NativeRootViewport(ViewHandle rootView, IFrame frame) : base(frame)
		{
			_rootView = rootView;
		}

		public NativeRootViewport(ViewHandle rootView) : base()
		{
			_rootView = rootView;
		}
	}
}