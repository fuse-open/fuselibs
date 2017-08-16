using Uno;

using Fuse;
using Fuse.Triggers;

namespace FuseTest 
{
	/* Defers changing of active status to ensure bypass is working correctly */
	public class WhileDefer : WhileTrigger
	{
		public bool Later { get; set; }
		
		bool _on;
		public bool On
		{
			get { return _on; }
			set
			{
				_on = value;
				if (IsRootingStarted)
					Defer();
			}
		}
		
		void Defer()
		{
			UpdateManager.AddDeferredAction(SwitchOn, Later ? LayoutPriority.Later : LayoutPriority.Now);
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			Defer();
		}
		
		void SwitchOn()
		{
			SetActive(On);
		}
	}
}
