using Fuse;
using Fuse.Input;
using Uno;

public partial class Multitouch
{
	TouchCircle[] _touchCircles = new TouchCircle[10];
	bool[] _down = new bool[10];

	public Multitouch()
	{
		InitializeUX();
		for (var i = 0; i < _touchCircles.Length; i++)
		{
			var t = new TouchCircle();
			t.Label.Value = i.ToString();
			_touchCircles[i] = t;
			_testPanel.Children.Add(t);
		}
	}

	protected override void OnRooted()
	{
		base.OnRooted();
		Pointer.AddHandlers(_testPanel, OnPointerPressed, OnPointerMoved, OnPointerReleased);
	}

	protected override void OnUnrooted()
	{
		Pointer.RemoveHandlers(_testPanel, OnPointerPressed, OnPointerMoved, OnPointerReleased);
		base.OnUnrooted();
	}

	class LostCaptureCallback
	{
		Multitouch _multitouch;
		int _index;

		public LostCaptureCallback(Multitouch multitouch, int index)
		{
			_multitouch = multitouch;
			_index = index;
		}

		public void LostCapture()
		{
			_multitouch._down[_index] = false;
			_multitouch._touchCircles[_index].IsActive.Value = false;
		}
	}

	void OnPointerPressed(object sender, PointerPressedArgs args)
	{
		var t = _touchCircles[args.PointIndex];
		if (args.TryHardCapture(t, new LostCaptureCallback(this, args.PointIndex).LostCapture))
		{
			_down[args.PointIndex] = true;
			t.IsActive.Value = true;
			UpdatePos(args);
		}
	}

	void OnPointerMoved(object sender, PointerMovedArgs args)
	{
		if (_down[args.PointIndex])
			UpdatePos(args);
	}

	void OnPointerReleased(object sender, PointerReleasedArgs args)
	{
		_down[args.PointIndex] = false;
		_touchCircles[args.PointIndex].IsActive.Value = false;
		args.ReleaseCapture(_touchCircles[args.PointIndex]);
	}

	void UpdatePos(PointerEventArgs args)
	{
		_touchCircles[args.PointIndex].Translation.XY = _testPanel.WindowToLocal(args.WindowPoint);
	}
}