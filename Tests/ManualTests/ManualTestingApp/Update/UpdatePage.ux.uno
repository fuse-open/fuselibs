using Uno;

using Fuse;

public partial class UpdatePage
{
	int _idleCount;
	int _lastFrame;
	public void Start(object s, object a)
	{
		_idleCount = 0;
		UpdateManager.AddAction(WaitNoDraw);
		_lastFrame = UpdateManager.FrameIndex;
	}
	
	int _waitCount;
	void WaitNoDraw()
	{
		CheckFrame();
		var app = AppBase.Current;
		var need = app.NeedsRedraw;
		
		if (!need)
		{	
			//the counting ensures that we have render stability, not just one lucky frame
			_idleCount++;
			
			if (_idleCount > 30)
			{
				UpdateManager.RemoveAction(WaitNoDraw);
				_waitCount = 10;
				UpdateManager.PerformNextFrame(WaitDone);
				stepB.Value = true;
			}
		}
		else
		{
			_idleCount = 0;
		}
	}

	void CheckFrame()
	{
		//frame index should always update, even without drawing.
		// UpdateCircle also checks this error in a more realistic fashion, but this test is explicit thus less
		// prone to working artificially
		if (_lastFrame >= UpdateManager.FrameIndex)
		{
			Fuse.Diagnostics.InternalError( "Timing error ");
			//it will never complete now
			UpdateManager.RemoveAction(WaitNoDraw);
			return;
		}
		_lastFrame = UpdateManager.FrameIndex;
	}
	
	void WaitDone()
	{
		CheckFrame();
		_waitCount--;
		// the counting here is to ensure onces (PErformNextFrame) also work as intended
		if (_waitCount > 0)
		{
			if (AppBase.Current.NeedsRedraw)
			{
				_idleCount = 0;
				UpdateManager.AddAction(WaitNoDraw);
			}
			
			UpdateManager.PerformNextFrame(WaitDone);
			return;
		}
		
		stepB.Value = true;
		UpdateManager.PerformNextFrame(PingCircle);
	}
	
	void PingCircle()
	{
		circC.Ping();
	}
}

// This catches the error found in https://github.com/fusetools/fuselibs-public/issues/452
// It's due to how InvalidateVisual prevents duplicate calls by checking the FrameIndex
public class UpdateCircle : Fuse.Controls.Circle
{
	public void Ping()
	{
		//this triggers the first invalidation...
		InvalidateVisual();
		UpdateManager.PerformNextFrame(UpdateColor);
	}
	
	public void UpdateColor()
	{
		//...the next frame will call invalidate again, but since the FrameIndex wasn't updated it will not be done
		Color = float4(0,0.5f,0,1);
	}
}
