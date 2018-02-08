using Uno;
using Uno.UX;

using Fuse.Platform;
using Fuse.Reactive;

namespace Fuse.Triggers
{
	/**
		Active when on-screen controls are visible, such as the keyboard. This excludes the fixed controls, such as navigation and home button, on some devices.
	*/
	public class WhileKeyboardVisible: WhileTrigger, IPropertyListener
	{
		/** @Deprecated */
		[Obsolete]
		public float Threshold
		{
			get { return 150; }
		}

		WindowCaps _caps;
		protected override void OnRooted()
		{
			base.OnRooted();
			_caps = WindowCaps.AttachFrom(this);
			_caps.AddPropertyListener(this);
			CheckActivation();
		}

		protected override void OnUnrooted()
		{
			_caps.RemovePropertyListener(this);
			_caps.Detach();
			_caps = null;
			base.OnUnrooted();
		}

		static float _deltaY;

		void IPropertyListener.OnPropertyChanged(PropertyObject sender, Selector name)
		{
			if (sender == _caps && (name == WindowCaps.NameSafeMargins || 
				name == WindowCaps.NameStaticMargins) )
				CheckActivation();
		}
		
		void CheckActivation()
		{
			var safe = float4(0);
			var stat = float4(0);
			if (!Marshal.TryToType<float4>(_caps[WindowCaps.NameSafeMargins], out safe) ||
				!Marshal.TryToType<float4>(_caps[WindowCaps.NameStaticMargins], out stat))
			{
				Fuse.Diagnostics.InternalError( "Invalid margin values", this );
				Deactivate();
				return;
			}

			SetActive(safe.W > stat.W);
		}
	}
}
