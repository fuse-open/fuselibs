using Uno;
using Uno.Collections;
using Fuse.Elements;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	public partial class ScrollViewBase
	{
		IScrollView NativeScrollView
		{
			get { return NativeView as IScrollView; }
		}

		float IScrollViewHost.PixelsPerPoint
		{
			get { return Viewport.PixelsPerPoint; }
		}

		void IScrollViewHost.OnScrollPositionChanged(float2 newScrollPosition)
		{
			SetScrollPosition(newScrollPosition, null);
		}

		float2 IScrollViewHost.ContentSize
		{
			get
			{
				var content = Children.FirstOrDefault() as Element;
				return content != null ? content.ActualSize : float2(0.0f);
			}
		}

		internal sealed override void CompensateForScrollView(ref float4x4 t)
		{
			t.M41 = t.M41 + ScrollPosition.X;
			t.M42 = t.M42 + ScrollPosition.Y;
		}

		protected override void PushPropertiesToNativeView()
		{
			base.PushPropertiesToNativeView();
			var nsv = NativeScrollView;
			if (nsv != null)
			{
				nsv.AllowedScrollDirections = AllowedScrollDirections;
			}
		}
	}
}
