using Uno;
using Uno.UX;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	public partial class Control
	{

		public object Appearance { get; internal set; }

		public Visual GraphicsVisual {	get; internal set; }

		IView _nativeView;
		public IView NativeView
		{
			get { return _nativeView; }
			internal set
			{
				_nativeView = value;
				if (_nativeView != null)
					PushPropertiesToNativeView();
			}
		}

		protected override void OnInvalidateVisual()
		{
			base.OnInvalidateVisual();
			if defined(Android||iOS)
			{
				if (ViewHandle != null)
				{
					ViewHandle.Invalidate();
				}
			}
		}

		protected virtual void PushPropertiesToNativeView()
		{
			// To be overridden in subclasses
		}

		protected virtual IView CreateNativeView()
		{
			return null;
		}

		// Expose CreateNativeView to ITreeRenderer for backwardscompatibility
		internal IView InstantiateNativeView()
		{
			return CreateNativeView();
		}

		protected override float2 GetContentSize(LayoutParams lp)
		{
			var t = TreeRenderer;
			if (t != null)
			{
				float2 size;
				if (t.Measure(this, lp, out size))
					return size;
			}
			return base.GetContentSize(lp);
		}

		internal virtual void CompensateForScrollView(ref float4x4 t) { }
	}
}