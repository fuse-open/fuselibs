using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.Android
{
	extern(!Android) public class Button {}
	extern(Android) public class Button : LeafView, ILabelView
	{
		public Button() : base(Create()) {}

		public string Text
		{
			set { SetText(Handle, value); }
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new android.widget.Button(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		static void SetText(Java.Object handle, string text)
		@{
			((android.widget.Button)handle).setText(text);
		@}

	}
}