using Uno;
using Uno.UX;

using Fuse;
using Fuse.Elements;
using Fuse.Triggers;

public partial class FpsMeter
{
	protected override void OnRooted()
	{
		base.OnRooted();
		IsVisibleChanged += OnIsVisibleChanged;
		UpdateListen();
	}
	
	protected override void OnUnrooted()
	{
		IsVisibleChanged -= OnIsVisibleChanged;
		UpdateListen(true);
		base.OnUnrooted();
	}
	
	void OnIsVisibleChanged(object s, object a)
	{
		UpdateListen();
	}
	
	bool _listening;
	void UpdateListen(bool forceOff = false)
	{
		var should = IsVisible && !forceOff;
		
		if (should == _listening)
			return;
			
		_initial = true;
		if (should)
			UpdateManager.AddAction(OnUpdate);
		else
			UpdateManager.RemoveAction(OnUpdate);
		_listening = should;
	}
	
	double _fpsShort;
	double _fpsLong;
	bool _initial = true;
	
	double _updateIn;
	
	void OnUpdate()
	{
		//assume a timing glitch / startup timing
		if (Time.FrameInterval < 1/500.0f)
			return;
			
		var fps = 1 / Time.FrameInterval;
		
		var alphaShort = 1 / 20.0f;
		_fpsShort = _initial ? fps : Math.Lerp( _fpsShort, fps, alphaShort );
		
		var alphaLong = 1 / 120.0f;
		_fpsLong = _initial ? fps : Math.Lerp( _fpsLong, fps, alphaLong );
		//fast drop, but slow recovery
		_fpsLong = Math.Min( _fpsLong, fps );
	
		//only update infrequently to avoid display flickering
		_updateIn -= Time.FrameInterval;
		if (_updateIn < 0 || _initial)
		{
			debug_log "FPS: " + _fpsLong + ", "+ _fpsShort;
			_updateIn = 0.5f;
		}
		
		_initial = false;
		
	}
}
