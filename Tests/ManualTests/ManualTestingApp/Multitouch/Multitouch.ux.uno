using Fuse;
using Fuse.Input;
using Uno;
using Uno.Collections;

public partial class Multitouch
{
	List<TouchCircle> _touchCircles = new List<TouchCircle>();
	List<bool> _down = new List<bool>();

	public Multitouch()
	{
		InitializeUX();
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

	void AddTouchCircle()
	{
		var t = new TouchCircle();
		t.Label.Value = _touchCircles.Count.ToString();
		_touchCircles.Add(t);
		_down.Add(false);
		_testPanel.Children.Add(t);
	}

	void OnPointerPressed(object sender, PointerPressedArgs args)
	{
		while (args.PointIndex >= _touchCircles.Count)
			AddTouchCircle();

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
		if (args.PointIndex >= _down.Count)
			return;
			
		if (_down[args.PointIndex])
			UpdatePos(args);
	}

	void OnPointerReleased(object sender, PointerReleasedArgs args)
	{
		if (args.PointIndex >= _down.Count)
			return;
			
		_down[args.PointIndex] = false;
		_touchCircles[args.PointIndex].IsActive.Value = false;
		args.ReleaseCapture(_touchCircles[args.PointIndex]);
	}

	void UpdatePos(PointerEventArgs args)
	{
		_touchCircles[args.PointIndex].Translation.XY = _testPanel.WindowToLocal(args.WindowPoint);
	}
}