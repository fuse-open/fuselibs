using Uno;
using Fuse;
using Fuse.Triggers;
using Fuse.Controls;

/**
	Trigger that will become active while the @ScrollView is in motion
**/
public class WhileScrolling : WhileTrigger
{

	ScrollViewBase _scrollable;

	protected override void OnRooted()
	{
		base.OnRooted();
		_scrollable = Parent.FindByType<ScrollViewBase>();
		if (_scrollable == null)
		{
			Fuse.Diagnostics.UserError( "WhileScrolling could not find a Scrollable control.", this );
			return;
		}
		_scrollable.ScrollPositionChanged += OnScrollPositionChanged;
	}

	protected override void OnUnrooted()
	{
		if (_scrollable != null)
		{
			_scrollable.ScrollPositionChanged -= OnScrollPositionChanged;
			_scrollable = null;
		}
		base.OnUnrooted();
	}

	bool _isActive = false;
	int _prevFrameIndex = 0;

	void OnScrollPositionChanged(object sender, EventArgs args)
	{
		if (!_isActive)
		{
			_isActive = true;
			SetActive(true);
			UpdateManager.AddAction(OnUpdate);
		}
		_prevFrameIndex = UpdateManager.FrameIndex;
	}

	void OnUpdate()
	{
		if (_prevFrameIndex < UpdateManager.FrameIndex)
		{
			SetActive(false);
			_isActive = false;
			UpdateManager.RemoveAction(OnUpdate);
		}
	}

}