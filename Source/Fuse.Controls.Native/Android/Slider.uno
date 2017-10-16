using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.Android
{
	extern (!Android) public class Slider : IRangeView
	{
		public double Progress { set { } }

		[UXConstructor]
		public Slider([UXParameter("Host")]IRangeViewHost host) { }
	}

	extern(Android) public class Slider : LeafView, IRangeView
	{

		public double Progress
		{
			set { SetProgress(Handle, value); }
		}

		IRangeViewHost _host;

		[UXConstructor]
		public Slider([UXParameter("Host")]IRangeViewHost host) : base(Create(), true)
		{
			_host = host;
			AddChangedCallback(Handle);
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			android.widget.SeekBar seekBar = new android.widget.SeekBar(com.fuse.Activity.getRootActivity());
			seekBar.setMax(1000);
			return seekBar;
		@}

		[Foreign(Language.Java)]
		static void SetProgress(Java.Object handle, double progress)
		@{
			((android.widget.SeekBar)handle).setProgress( (int)(progress * 1000.0) );
		@}

		[Foreign(Language.Java)]
		void AddChangedCallback(Java.Object handle)
		@{
			((android.widget.SeekBar)handle).setOnSeekBarChangeListener(new android.widget.SeekBar.OnSeekBarChangeListener() {
				public void onProgressChanged(android.widget.SeekBar seekBar, int progress, boolean fromUser) {
					@{global::Fuse.Controls.Native.Android.Slider:Of(_this).OnSeekBarChanged(double,bool):Call(progress / 1000.0, fromUser)};
				}
				public void onStartTrackingTouch(android.widget.SeekBar seekBar) { }
				public void onStopTrackingTouch(android.widget.SeekBar seekBar) { }
			});
		@}

		void OnSeekBarChanged(double rel, bool fromUser)
		{
			if (fromUser)
			{
				var us = _host.RelativeUserStep;
				if (us > 0)
				{
					rel = Math.Round(rel/us) * us;
					SetProgress(Handle, rel * 1000);
				}
			}
			_host.OnProgressChanged(rel);
		}

		public override void Dispose()
		{
			_host = null;
			base.Dispose();
		}

	}
}