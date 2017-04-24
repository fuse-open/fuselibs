using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern (!iOS) public class Switch : IToggleView
	{
		public bool Value { set { } }
		public IToggleViewHost Host { set { } }

		[UXConstructor]
		public Switch([UXParameter("Host")]IToggleViewHost host) { }
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	extern(iOS) public class Switch : LeafView, IToggleView
	{

		public bool Value
		{
			set { SetValue(Handle, value); }
		}

		IToggleViewHost _host;
		IDisposable _valueChangedEvent;

		[UXConstructor]
		public Switch([UXParameter("Host")]IToggleViewHost host) : base(Create())
		{
			_host = host;
			_valueChangedEvent = UIControlEvent.AddValueChangedCallback(Handle, OnValueChanged);
		}

		public override void Dispose()
		{
			_host = null;
			_valueChangedEvent.Dispose();
			_valueChangedEvent = null;
			base.Dispose();
		}

		void OnValueChanged(ObjC.Object sender, ObjC.Object uiEvent)
		{
			_host.OnValueChanged(GetValue(Handle));
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			return [[::UISwitch alloc] init];
		@}

		[Foreign(Language.ObjC)]
		static bool GetValue(ObjC.Object handle)
		@{
			::UISwitch* sw = (::UISwitch*)handle;
			return [sw isOn];
		@}

		[Foreign(Language.ObjC)]
		static void SetValue(ObjC.Object handle, bool value)
		@{
			::UISwitch* sw = (::UISwitch*)handle;
			[sw setOn:value];
		@}

	}
}