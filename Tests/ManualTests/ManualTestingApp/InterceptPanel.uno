using Fuse;
using Fuse.Controls;
using Fuse.Triggers;

public class InterceptPanel : LayoutControl
{
	public WhileTrue Invalid { get; set; }
	
	protected override float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
	{
		if( lp.Size.X == 0 || lp.Size.Y == 0) {
			UpdateManager.AddDeferredAction(MarkInvalid); //defer to not invalidate during layout
		}
		return base.OnArrangeMarginBox(position, lp);
	}
	
	void MarkInvalid()
	{
		Invalid.Value = true;
	}
	
}