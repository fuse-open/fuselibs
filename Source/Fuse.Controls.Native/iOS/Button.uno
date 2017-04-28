using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern(!iOS) public class Button
	{
		public Button() {}
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	extern(iOS) public class Button : LeafView, ILabelView
	{
		public Button() : base(Create()) {}

		string ILabelView.Text
		{
			set { SetText(Handle, value); }
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			return [[::UIButton alloc] init];
		@}

		[Foreign(Language.ObjC)]
		static void SetText(ObjC.Object handle, string text)
		@{
			::UIButton* button = (::UIButton*)handle;
			[button setTitle:text forState:UIControlStateNormal];
			[button setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
		@}

	}
}