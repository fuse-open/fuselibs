using Uno;
using Fuse;
using Fuse.Input;
using Fuse.Controls;

namespace AnimationTests.Test
{
	public class AnimationTestPanel : Panel
	{
		public void Pressed()
		{
			Pointer.Pressed.RaiseWithBubble(
				new PointerPressedArgs(
					new PointerEventData{
						PointIndex = 0,
						WindowPoint = float2(100f),
						WheelDelta = float2(0,0), 
						WheelDeltaMode = Uno.Platform.WheelDeltaMode.DeltaPixel,
						IsPrimary = true,
						PointerType = Uno.Platform.PointerType.Mouse}, this));
		}

		public void Unpressed()
		{
			Pointer.Released.RaiseWithBubble(
				new PointerReleasedArgs(
					new PointerEventData{
						PointIndex = 0,
						WindowPoint = float2(100f),
						WheelDelta = float2(0,0), 
						WheelDeltaMode = Uno.Platform.WheelDeltaMode.DeltaPixel,
						IsPrimary = true,
						PointerType = Uno.Platform.PointerType.Mouse}, this));
		}

	    public Panel Panel1
		{
			get
			{
				return this;
			}
		}
	}
}
