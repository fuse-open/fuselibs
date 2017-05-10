using Uno;

using Fuse.Triggers;

namespace Fuse.Controls
{
	public enum PageFreeze
	{
		/** Do not apply any standard freezing to the page. It can still be explicitly frozen.*/
		Never,
		/** Freezes the page when it's parent navigation is currently navigating. */
		WhileNavigating,
	}
	
	public enum PagePrepareBusy
	{
		/** Nothing special happens when the page is prepared */
		None,
		/** The page is marked busy for a couple of frames when prepared, thus deferring navigation */
		FrameDelay,
	}
	
	/** Represents a page that participates in navigation.
	
		You generally want to use this as the base class when implementing your page views, although any @Visual can be used.
		
		See the [navigation guide](/docs/navigation/navigation) for an introductory guide to implementing navigation in your app.
		
		## Example
		
		The following example illustrates subclassing @Page and using it in a @PageControl.
		
			<Page ux:Class="MyPage">
			    <Text Alignment="Center">This is a page!</Text>
			</Page>
			
			<PageControl>
			    <MyPage />
			    <MyPage />
			</PageControl>
		
		## Remarks
		
		@Page exposes a local @Uno.UX.Resource "Title", which can be set using the @Title property.
	*/
	public class Page: Panel
	{
		public Page()
		{
			//this is a better default for combining with `Freeze`
			DeferFreeze = BusyTaskActivity.Short;
		}
		
		public object SaveState()
		{
			return OnSaveState();
		}

		protected virtual object OnSaveState()
		{
			return null;
		}

		public void RestoreState(object state)
		{
			OnRestoreState(state);
		}

		protected virtual void OnRestoreState(object state) { }

		const string _titleKey = "Title";
		/** The title of the page. Setting this will also set a local @Uno.UX.Resource with the key "Title". */
		public string Title
		{
			get 
			{ 
				object v;
				if (TryGetResource(_titleKey, null, out v))
					return v as string;
				return null;
			}
			set
			{
				if (Title != value)
				{
					SetResource(_titleKey, value);
					OnPropertyChanged(_titleKey);
				}
			}
		}

		Trigger _freezeTrigger;
		protected override void OnRooted()
		{
			base.OnRooted();
			SetupFreezeTrigger();
		}
		
		void SetupFreezeTrigger()
		{
			CleanupFreezeTrigger();
			switch (Freeze)
			{
				case PageFreeze.Never:
					break;
				case PageFreeze.WhileNavigating:
					_freezeTrigger = new NavigationInternal.PageWhileNavigatingFreeze(this);
					break;
			}
			
			if (_freezeTrigger != null)
				Children.Add(_freezeTrigger);
		}
		
		void CleanupFreezeTrigger()
		{
			if (_freezeTrigger != null)
			{
				Children.Remove(_freezeTrigger);
				_freezeTrigger = null;
			}
		}
		
		protected override void OnUnrooted()
		{
			CleanupFreezeTrigger();
			CleanupBusy();
			base.OnUnrooted();
		}

		PageFreeze _freeze = PageFreeze.Never;
		/**
			Specifies when this page will be frozen.
			
			For full size transitions, like in a top-level navigator, this value is typically set to `WhileNavigating`:
			
				<Page Freeze="WhileNavigating">
				
			This may improve navigation performance by essentially blocking animation on the page itself while in transition.
			
			Refer to the @Fuse.Controls.Panel.IsFrozen property.
			@advanced
		*/
		public PageFreeze Freeze
		{
			get { return _freeze; }
			set { _freeze = value; }
		}

		PagePrepareBusy _prepare = PagePrepareBusy.FrameDelay;
		/**
			Allows marking a page as busy when it is first prepared. This can improve navigation animations as the first preparation frames will happen prior to the transition.

			The default is `FrameDelay`
			@advanced
		*/
		public PagePrepareBusy PrepareBusy
		{
			get { return _prepare; }
			set { _prepare = value; }
		}
		
		BusyTask _prepareBusy;
		int _busyFrames;
		bool _isBusy;
		internal override void Prepare(string parameter)
		{
			base.Prepare(parameter);
			
			if (PrepareBusy == PagePrepareBusy.FrameDelay)
			{
				//this usually ends up as 1 since prepare tends to be called prior to the first update stages
				_busyFrames = 2;
				ListenBusy();
			}
		}

		void CleanupBusy()
		{
			_busyFrames = 0;
			ListenBusy();
		}
		
		void ListenBusy()
		{
			var should = _busyFrames > 0;
			if (should == _isBusy)
				return;
				
			_isBusy = should;
			if (_isBusy)
			{
				BusyTask.SetBusy(this, ref _prepareBusy, BusyTaskActivity.Preparing );
				UpdateManager.AddAction( OnBusyUpdate );
			}
			else
			{
				BusyTask.SetBusy(this, ref _prepareBusy, BusyTaskActivity.None );
				UpdateManager.RemoveAction( OnBusyUpdate );
			}
		}
		
		void OnBusyUpdate()
		{
			_busyFrames--;
			ListenBusy();
		}
		
	}
}