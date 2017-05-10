using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Triggers;

namespace Fuse.Controls.Native.Android
{
	extern (!Android) public class Switch : IToggleView
	{
		public bool Value { set { } }
		public IToggleViewHost Host { set { } }

		[UXConstructor]
		public Switch([UXParameter("Host")]IToggleViewHost host) { }
	}

	extern(Android) public class Switch : LeafView, IToggleView
	{
		public bool Value
		{
			set { SetValue(Handle, value); }
		}

		IToggleViewHost _host;

		[UXConstructor]
		public Switch([UXParameter("Host")]IToggleViewHost host) : base(Create(), true)
		{
			_host = host;
			AddCallback(Handle);
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new android.widget.Switch(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		void AddCallback(Java.Object handle)
		@{
			((android.widget.Switch)handle).setOnCheckedChangeListener(new android.widget.CompoundButton.OnCheckedChangeListener() {
				public void onCheckedChanged(android.widget.CompoundButton buttonView, boolean isChecked) {
					@{global::Fuse.Controls.Native.Android.Switch:Of(_this).OnToggleChanged(bool):Call(isChecked)};
				}
			});
		@}

		[Foreign(Language.Java)]
		static void SetValue(Java.Object handle, bool value)
		@{
			((android.widget.Switch)handle).setChecked(value);
		@}

		void OnToggleChanged(bool value)
		{
			_host.OnValueChanged(value);
		}

		public override void Dispose()
		{
			_host = null;
			base.Dispose();
		}
	}
}