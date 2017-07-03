using Uno;
using Uno.UX;

using Fuse;
using Fuse.Scripting;

namespace Fuse.Triggers
{
	/**
		A @Trigger that is managed by a @StateGroup.

		See @StateGroup for more information.
	*/
	public partial class State : Trigger
	{
		bool _on;
		internal bool On
		{
			get { return _on; }
			set
			{
				if (_on == value)
					return;
				_on = value;
				if (Parent != null)
				{
					if (_on)
						Activate();
					else
						Deactivate();
				}
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (_on)
				Activate();
		}
	
		StateGroup _stateGroup;
		internal void RootStateGroup(StateGroup stateGroup)
		{
			OverrideContextParent = OverrideContextParent ?? stateGroup;
			_stateGroup = stateGroup;
		}
		
		protected override void OnUnrooted()
		{
			if (OverrideContextParent == _stateGroup) OverrideContextParent = null;
			_stateGroup = null;
			base.OnUnrooted();
		}

		public new double Progress { get { return base.Progress; } }
		
		public void Goto()
		{
			if (_stateGroup == null)
			{
				Fuse.Diagnostics.InternalError( "Cannot call `Goto` on an unrooted `State`");
				return;
			}
			
			_stateGroup.Goto(this);
		}
		
		protected override void OnPlayStateChanged(TriggerPlayState state)
		{
			if (_stateGroup != null && state == TriggerPlayState.Stopped)
				_stateGroup.StateStopped();
		}
	}
}
