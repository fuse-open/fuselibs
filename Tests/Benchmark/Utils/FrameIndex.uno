using Uno;
using Uno.UX;

using Fuse;
using Fuse.Reactive;
using Fuse.Triggers;

[UXFunction("frameIndex")]
public class FrameIndex: Fuse.Reactive.Expression, IDisposable
{
	IListener _listener;
	public override IDisposable Subscribe(IContext context, IListener listener)
	{
		_listener = listener;
		UpdateManager.AddAction(OnUpdate);
		return this;
	}

	public void Dispose()
	{
		UpdateManager.RemoveAction(OnUpdate);
	}

	void OnUpdate()
	{
		_listener.OnNewData(this, UpdateManager.FrameIndex);
	}
}
