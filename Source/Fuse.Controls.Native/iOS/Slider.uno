using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{

	extern (!iOS) public class Slider : IRangeView
	{
		public double Progress { set { } }

		[UXConstructor]
		public Slider([UXParameter("Host")]IRangeViewHost host) { }
	}
	
	[Require("Source.Include", "UIKit/UIKit.h")]
	extern(iOS) public class Slider : LeafView, IRangeView
	{

		public double Progress
		{
			set { Value = (float)value * 100.0f; }
		}

		IRangeViewHost _host;
		IDisposable _valueChangedEvent;

		[UXConstructor]
		public Slider([UXParameter("Host")]IRangeViewHost host) : base(Create())
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

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			::UISlider* slider = [[::UISlider alloc] init];
			[slider setMinimumValue:   0.0f];
			[slider setMaximumValue: 100.0f];
			return slider;
		@}

		void OnValueChanged(ObjC.Object sender, ObjC.Object uiEvent)
		{
			_host.OnProgressChanged( (double)(Value / 100.0f) );
		}

		float Value
		{
			get { return GetValue(Handle); }
			set { SetValue(Handle, value); }
		}

		[Foreign(Language.ObjC)]
		static float GetValue(ObjC.Object handle)
		@{
			::UISlider* slider = (::UISlider*)handle;
			return [slider value];
		@}

		[Foreign(Language.ObjC)]
		static void SetValue(ObjC.Object handle, float value)
		@{
			::UISlider* slider = (::UISlider*)handle;
			[slider setValue:value animated:false];
		@}

	}
}