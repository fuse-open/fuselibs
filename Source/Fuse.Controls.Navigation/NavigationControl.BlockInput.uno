using Fuse.Triggers;

namespace Fuse.Controls
{
	public enum NavigationControlBlockInput
	{
		/** Input is not blocked */
		Never,
		/** Input is blocked during navigation -- when `WhileNavigating` would be active */
		WhileNavigating,
	}
	
	public abstract partial class NavigationControl
	{
		NavigationControlBlockInput _blockInput = NavigationControlBlockInput.WhileNavigating;
		/**
			Whether or not input to block input to the pages during navigation.
			
			The default is `WhileNavigating`: the pages will not get any pointer input during navigation.
		*/
		public NavigationControlBlockInput BlockInput
		{
			get { return _blockInput; }
			set
			{
				if (_blockInput == value)
					return;
					
				_blockInput = value;
				if (IsRootingCompleted)
					UpdateBlockInput();
			}
		}

		Trigger _blockInputTrigger;
		void BlockInputRooted()
		{
			UpdateBlockInput();
		}
		
		void BlockInputUnrooted()
		{
			DisableBlockInput();
		}
		
		void UpdateBlockInput()
		{
			if (_blockInput == NavigationControlBlockInput.Never)
				DisableBlockInput();
			else
				EnableBlockInput();
		}
			
		void DisableBlockInput()
		{
			if (_blockInputTrigger != null)
			{
				Children.Remove(_blockInputTrigger);
				_blockInputTrigger = null;
			}
		}
		
		void EnableBlockInput()
		{
			if (_blockInputTrigger == null)
			{
				_blockInputTrigger = new NavigationInternal.BlockInputWhileNavigating(this);
				Children.Add(_blockInputTrigger);
			}
		}
	}
}
