using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;

namespace Fuse.Controls
{
	/**
		TODO write docs please
	*/
	public class SystemScreenConfigBase : Behavior
	{
		public enum Visibility
	    {
	        None,
	        Minimal,
	        Full,
	    }

	    private static List<SystemScreenConfigBase> rootedConfigs = new List<SystemScreenConfigBase>();

	    protected Timer _timer;
		private bool _rooted;

	    protected override void OnRooted()
		{
			base.OnRooted();

			_rooted = true;

			rootedConfigs.Add(this);

		}
		protected override void OnUnrooted()
		{
			base.OnUnrooted();

			resetTimer();

			rootedConfigs.Remove(this);
			_rooted = false;
		}

		protected double calculateResetTime() 
		{
			double lowestReset = _resetDelay;

			foreach(SystemScreenConfigBase theBase in rootedConfigs) 
			{
				lowestReset = Math.Min(lowestReset, theBase.ResetDelay);
			}
			return lowestReset;
		}

		protected void resetTimer() 
		{
			if(_timer!=null) 
			{
				_timer.Stop();
				_timer = null;
			}
		}

	    private Visibility _visibility;
	    public virtual Visibility Show 
	    { 
	    	get
	    	{
	    		return _visibility;
	    	} 
	    	set
	    	{
	    		_visibility = value;
	    	} 
	    }

	    private bool _showNavigation = true;
	    public virtual bool ShowNavigation 
	    { 
	    	get
	    	{
	    		return _showNavigation;
	    	}
	    	set
	    	{
	    		_showNavigation = value;
	    	} 
	    }

		private bool _showStatus = true;
	    public virtual bool ShowStatus 
	    { 
	    	get
	    	{
	    		return _showStatus;
	    	}
	    	set
	    	{
	    		_showStatus = value;
	    	} 
	    }

	    private bool _isDim = false;
	    public virtual bool IsDim 
	    { 
	    	get
	    	{
	    		return _isDim;
	    	} 
	    	set
	    	{
	    		_isDim = value;
	    	} 
	    }

	    //private Theme _theme = Theme.Dark;
	    //public Theme Theme { get; set; }

	    private double _resetDelay = 5.0;
	    public virtual double ResetDelay 
	    { 
	    	get
	    	{
	    		return _resetDelay;
    		} 
    		set
    		{
    			_resetDelay = value;
    		} 
    	}
	}
}
