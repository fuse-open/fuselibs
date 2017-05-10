using Uno;
using Fuse;
using Fuse.Drawing;

public partial class ActionTiming
{
	void Start(object s, object a)
	{
		Trig.Pulse();
		TrigB.Pulse();
	}

	void Reset(object s, object a)
	{
		foreach (var anim in Trig.Actions)
		{
			var track = anim as Track;
			if (track != null)
				track.Clear();
		}
		foreach (var anim in TrigB.Actions)
		{
			var track = anim as Track;
			if (track != null)
				track.Clear();
		}
	}
}

public sealed class Track : Fuse.Triggers.Actions.TriggerAction
{
	static double start;

	public string Text { get; set; }
	public bool Reset { get; set; }

	public int Count { get; set; }
	public float Expect { get; set; }

	public Status Status { get; set; }

	public void Clear()
	{
		Count = 0;
		Status.CountPanel.Background = new SolidColor( float4(0,0,0,0) );
		Status.TimePanel.Background = new SolidColor( float4(0,0,0,0) );
	}

	protected override void Perform(Node target)
	{
		if (Reset)
			start = Time.FrameTime;

		var relative = Time.FrameTime - start;

		Count = Count + 1;
		Status.CountText.Value = String.Format( "{0:D}", Count );
		Status.TimeText.Value = String.Format( "{0:F2}", relative );

		if (Count == 1)
			Status.CountPanel.Background = new SolidColor( float4(0,1,0,1) );
		else
			Status.CountPanel.Background = new SolidColor( float4(1,0,0,1) );

		if ( Math.Abs( relative - Expect ) < 0.1f ) //close enough even at 10FPS
			Status.TimePanel.Background = new SolidColor( float4(0,1,0,1) );
		else
			Status.TimePanel.Background = new SolidColor( float4(1,0,0,1) );
	}
}
