using Uno;

using Fuse;
using Fuse.Controls;
using Fuse.Triggers;

namespace FuseTest
{
	/**
		A control that allows explicit control of the busy status.
	*/
	public class BusyControl : Panel
	{
		BusyTask _busyTask;

		BusyTaskActivity _activity = BusyTaskActivity.Processing;
		public BusyTaskActivity Activity { get { return _activity; } set { _activity = value; } }
		
		bool _isBusy = false;
		public bool IsBusy
		{
			get { return _isBusy; }
			set
			{
				if (_isBusy == value)
					return;
				_isBusy = value;
				if (IsRootingCompleted)
				{
					if (_isBusy)
						SetBusy();
					else
						ResetBusy();
				}
			}
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			if (IsBusy)
				SetBusy();
		}
		
		protected override void OnUnrooted()
		{
			ResetBusy();
			base.OnUnrooted();
		}
		
		void SetBusy()
		{
			BusyTask.SetBusy(this, ref _busyTask, _activity);
		}
		
		void ResetBusy()
		{
			BusyTask.SetBusy(this, ref _busyTask, BusyTaskActivity.None);
		}
	}
}