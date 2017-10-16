using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{

	extern (!iOS) public class Slider : IRangeView
	{
		public double Progress { set { } }

		[UXConstructor]
		public Slider([UXParameter("Host")]IRangeViewHost host, [UXParameter("Visual")]Visual visual) { }
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	extern(iOS) public class Slider : LeafView, IRangeView
	{

		public double Progress
		{
			set { Value = (float)value * 100.0f; }
		}

		IRangeViewHost _host;
		Visual _visual;
		IDisposable _valueChangedEvent;

		PointerCaptureAdapter _captureAdapter;

		[UXConstructor]
		public Slider([UXParameter("Host")]IRangeViewHost host, [UXParameter("Visual")]Visual visual) : base(Create())
		{
			_host = host;
			_visual = visual;
			_valueChangedEvent = UIControlEvent.AddValueChangedCallback(Handle, OnValueChanged);
			_captureAdapter = new PointerCaptureAdapter(_visual, Handle);
		}

		public override void Dispose()
		{
			_host = null;
			_valueChangedEvent.Dispose();
			_captureAdapter.Dispose();
			_valueChangedEvent = null;
			_captureAdapter = null;
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
			var rel = (double)(Value / 100.0f);
			var us = _host.RelativeUserStep;
			if (us > 0)
			{
				rel = Math.Round(rel/us) * us;
				SetValue(Handle, (float)rel * 100);
			}
			
			_host.OnProgressChanged( rel );
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