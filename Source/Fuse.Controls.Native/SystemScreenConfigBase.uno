using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Internal;

namespace Fuse.Controls
{
	public class SystemScreenConfigBase : Behavior
	{
		public enum Visibility
		{
			None,
			Minimal,
			Full,
		}

		private static SystemScreenConfigBase rootedConfig = null;

		protected IDisposable _timer;

		protected override void OnRooted()
		{
			base.OnRooted();

			if(rootedConfig==null)
			{
				rootedConfig = this;
			}
			else
			{
				Fuse.Diagnostics.UserError("Only one SystemScreenConfig element should be rooted at once", this);
			}

		}
		protected override void OnUnrooted()
		{
			base.OnUnrooted();

			resetTimer();

			rootedConfig = null;
		}

		protected void resetTimer() 
		{
			if(_timer!=null) 
			{
				_timer.Dispose();
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

		//Android doesn't support Theme
		//public Theme Theme { get; set; }

		//5 seconds chosen as sane default
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
