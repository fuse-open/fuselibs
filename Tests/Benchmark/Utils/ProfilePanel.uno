using Fuse;
using Fuse.Controls;
using Fuse.Elements;

using Uno;
using Uno.Diagnostics;

class ProfilePanel : LayoutControl
{
	public ProfilePanel()
	{
		CachingMode = CachingMode.Never;
	}

	public int FrameCount
	{
		get { return _frameCount; }
		set
		{
			_frameCount = Math.Max(value, 1);
		}
	}

	int _frames;
	int _frameCount = 100;
	double _drawMinTime, _drawMaxTime, _drawTotalTime;

	protected override void OnRooted()
	{
		base.OnRooted();

		_drawMinTime = float.MaxValue;
		_drawMaxTime = 0;
		_drawTotalTime = 0;

		UpdateManager.AddAction(Update);
	}

	protected override void OnUnrooted()
	{
		base.OnUnrooted();
		UpdateManager.RemoveAction(Update);
	}

	void Report()
	{
		var name = Name != null ? Name.ToString() : "<Unnamed>";
		Debug.Log(string.Format("Results for \"{0}\", {1} frames:", name, _frames));
		Debug.Log(string.Format("\tDraw MinTime: {1} ms", name, _drawMinTime * 1000.0));
		Debug.Log(string.Format("\tDraw MaxTime: {1} ms", name, _drawMaxTime * 1000.0));
		Debug.Log(string.Format("\tDraw AvgTime: {1} ms", name, (_drawTotalTime / _frames) * 1000.0));
	}

	void Update()
	{
		if (_frames == _frameCount)
		{
			Report();

			var testRunner = GetNearestAncestorOfType<TestRunner>();
			if (testRunner != null)
				testRunner.OnTestFinished();
		}

		_frames++;
	}

	protected override void DrawWithChildren(DrawContext dc)
	{
		var startTime = Uno.Diagnostics.Clock.GetSeconds();
		base.DrawWithChildren(dc);
		var endTime = Uno.Diagnostics.Clock.GetSeconds();

		var time = endTime - startTime;
		_drawMinTime = Math.Min(_drawMinTime, time);
		_drawMaxTime = Math.Max(_drawMaxTime, time);
		_drawTotalTime += time;
	}
}
