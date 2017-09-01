using Uno;
using Uno.Time;

public partial class ClockPage
{
	public ClockPage()
	{
		InitializeUX();
		Fuse.UpdateManager.AddAction(OnUpdate);
	}

	void OnUpdate()
	{
		if (!IsVisible)
			return;
			
		var t = ZonedDateTime.Now;
		float h = t.Hour;
		float m = t.Minute;
		float s = t.Second;
		
		//ticking seconds
		RotateSecond.Degrees = (float)(Math.Floor(s)/60 * 360);
		RotateMinute.Degrees = (float)(m/60 * 360);
		RotateHour.Degrees = (float)(h/12 * 360);
	}
}
