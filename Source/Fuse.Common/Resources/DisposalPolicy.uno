using Uno;
using Uno.Collections;
using Uno.Diagnostics;

namespace Fuse.Resources
{
	abstract class DisposalPolicy
	{
		public abstract void MarkUsed();
		public abstract bool CanDispose(DisposalRequest dr, bool pinned);
		public abstract DisposalPolicy Clone();
	}
	
	sealed class ExpirationDisposalPolicy : DisposalPolicy
	{
		double lastUsedFrameTime;
		//if > 0 used as timeout, if <= 0 ignored
		public double Timeout { get; set; }
		
		public override void MarkUsed()
		{
			lastUsedFrameTime = Time.FrameTime;
		}
		
		public override bool CanDispose(DisposalRequest dr, bool pinned)
		{
			if( !pinned && Timeout > 0 ) 
			{
				var elapsed = Time.FrameTime - lastUsedFrameTime;
				if( elapsed > Timeout )
					return true;
			}

			//okay to go away on any non-regular disposal as well
			return dr != DisposalRequest.Regular;
		}
		
		public override DisposalPolicy Clone()
		{
			var p = new ExpirationDisposalPolicy();
			p.Timeout = Timeout;
			//internal fields not cloned, only public settings
			return p;
		}
	}
	
	sealed class RetainDisposalPolicy : DisposalPolicy
	{
		public override void MarkUsed() { }
		public override bool CanDispose(DisposalRequest dr, bool pinned) { return false; }
		public override DisposalPolicy Clone() { return new RetainDisposalPolicy(); }
	}
}
