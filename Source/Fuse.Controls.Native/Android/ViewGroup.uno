
using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.Android
{
	extern(Android) public class ViewGroup
	{
		[Foreign(Language.Java)]
		internal static Java.Object Create()
		@{
			android.widget.FrameLayout frameLayout = new com.fuse.android.views.ViewGroup(com.fuse.Activity.getRootActivity());
			frameLayout.setFocusable(true);
			frameLayout.setFocusableInTouchMode(true);
			frameLayout.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return frameLayout;
		@}

		[Foreign(Language.Java)]
		internal static void AddView(Java.Object parentHandle, Java.Object childHandle)
		@{
			android.view.ViewGroup viewGroup = (android.view.ViewGroup)parentHandle;
			android.view.View childView = (android.view.View)childHandle;
			viewGroup.addView(childView);
		@}

		[Foreign(Language.Java)]
		internal static void AddView(Java.Object parentHandle, Java.Object childHandle, int index)
		@{
			android.view.ViewGroup viewGroup = (android.view.ViewGroup)parentHandle;
			android.view.View childView = (android.view.View)childHandle;
			viewGroup.addView(childView, index);
		@}

		[Foreign(Language.Java)]
		internal static void RemoveView(Java.Object parentHandle, Java.Object childHandle)
		@{
			android.view.ViewGroup viewGroup = (android.view.ViewGroup)parentHandle;
			android.view.View childView = (android.view.View)childHandle;
			viewGroup.removeView(childView);
		@}

	}

}
