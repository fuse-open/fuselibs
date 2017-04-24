using Uno;
using Uno.Collections;

namespace Fuse.Resources
{
	public enum DisposalRequest
	{
		Regular,
		Background,
		LowMemory,
	}
	
	interface IDeferredDisposable : IDisposable
	{
		void MarkUsed();
		bool CanDispose(DisposalRequest dr);
	}

	//this class enables the use of derived disposables that use a common policy system, like anticipated for UX
	abstract class PolicyDeferredDisposable : IDeferredDisposable
	{
		public DisposalPolicy Policy;
		
		public void MarkUsed()
		{
			if( Policy != null )
				Policy.MarkUsed();
		}
		
		public bool CanDispose(DisposalRequest dr) 
		{ 
			if( Policy != null )
				return Policy.CanDispose(dr, IsPinned);
				
			//actually misconfigured, so allow disposable for easiest debugging path
			return true;
		}
		
		protected virtual bool IsPinned { get { return false; } }
		
		public abstract void Dispose();
	}
}
