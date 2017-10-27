using Uno;
using Uno.UX;

using Fuse.Motion;
using Fuse.Motion.Simulation;
using Fuse.Triggers;

namespace Fuse.Navigation
{
	/**
		A linear navigation that retains the active state during changes of the pages
	*/
	public class DynamicLinearNavigation : VisualNavigation, ISeekableNavigation
	{
		protected bool _reuseExistingVisual = true;

		MotionConfig _motion;
		[UXContent]
		public MotionConfig Motion 
		{ 	
			get
			{
				if (_motion == null)
					_motion = new NavigationMotion();
				return _motion;
			}
			set
			{
				_motion = value;
				if (IsRootingCompleted)
					Fuse.Diagnostics.UserError( "Motion should not be changed post-rooting", this );
			}
		}
		
		BoundedRegion2D _region;
			
		enum Desired
		{
			None,
			Active,
			Index,
		}
		Desired _desired = Desired.None;
		Visual _desiredActive;
		int _desiredIndex;
		
		protected override void OnRooted()
		{
			base.OnRooted();

			if (_desired == Desired.None && PageCount > 0)
				_desiredActive = GetPage(0);
				
			_region = Motion.AcquireSimulation();
			_region.Position = float2(_progress,0);
			if (!GotoDesiredActive())
				SetProgress(GetPageIndex(_active));
				
			//force events as the above may not actually change the values, yet the logical state can change
			OnHistoryChanged();
		}
		
		Visual _listenComplete;
		void CleanupListenComplete()
		{
			if (_listenComplete != null)
			{
				_listenComplete.RootingCompleted -= GotoDesiredActiveAction;
				_listenComplete = null;
			}
		}
		
		void GotoDesiredActiveAction()
		{
			GotoDesiredActive();
		}
		
		bool GotoDesiredActive()
		{
			Visual desiredPage = null;
			switch (_desired)
			{
				case Desired.None:
					desiredPage = _active ?? GetPage(0);
					break;
					
				case Desired.Active:
					desiredPage = _desiredActive;
					break;
					
				case Desired.Index:
					desiredPage = GetPage(_desiredIndex);
					break;
			}
			
			if (desiredPage == null)
				return false;
				
			if (!desiredPage.IsRootingStarted)
			{
				CleanupListenComplete();
				_listenComplete = desiredPage;
				_listenComplete.RootingCompleted += GotoDesiredActiveAction;
				return false;
			}
		
			UpdateDesired(desiredPage, -1);
			if (desiredPage == _active)	
				return false;
				
			GotoImpl(desiredPage, NavigationGotoMode.Bypass);
			return true;
		}

		protected override void OnUnrooted()
		{
			if (_region != null)
			{
				_progress = _region.Position.X;
				_region = null;
				Motion.ReleaseSimulation();
			}
				
			CheckNeedUpdate(true);
			base.OnUnrooted();
		}

		public override double PageProgress
		{
			get { return Progress; }
		}

		/*
			External goto is a "desired" requres, and thus updates the desired mode.
		*/
		public override void Goto(Visual element, NavigationGotoMode mode)
		{
			if (mode != NavigationGotoMode.Transition &&
				mode != NavigationGotoMode.Bypass)
				return;
		
			UpdateDesired(element, -1);
			GotoInternal(element, mode);
		}
		
		/*
			Internal goto does not update the desired mode. It should be used by anything internally that needs a Goto but does not reflect a user desired change.
		*/
		void GotoInternal(Visual element, NavigationGotoMode mode)
		{
			if (!IsRootingCompleted)
			{
				//queue until rooted
				DirectSetActive(element);
				return;
			}

			if (element == _active)
				return;

			if (element == null)
				DirectSetActive(null);
			else
				GotoImpl(element, mode);
		}

		public void GotoImpl(Visual element, NavigationGotoMode mode)
		{
			if (element.Parent != Parent)
			{
				Fuse.Diagnostics.UserError( "Attempting to navigate to element with different parent", element );
				return;
			}
			
			TransitionToChild(element, mode.HasFlag(NavigationGotoMode.Bypass) );
		}
		
		/**
			@return true if the _region was updated
		*/
		bool TransitionToChild(Visual element, bool bypass = false, bool clamp = false)
		{
			var targetProgress = (float)GetPageIndex(element);
			DirectSetActive(element);

			if (bypass || !IsRootingCompleted)
			{
				SetProgress(targetProgress);
				OnNavigated(element);
				return false;
			}

			//shortcut if nothing changes
			if (Progress == targetProgress)
			{
				OnStateChanged( NavigationState.Stable);
				return false;
			}

			OnStateChanged( NavigationState.Transition );

			_region.MoveTo( float2((float)targetProgress,0) );
			CheckNeedUpdate();
			return true;
		}
		
		bool _hasUpdated;
		void CheckNeedUpdate(bool off = false)
		{
			bool needUpdated = _region != null && !_region.IsStatic;
			if (needUpdated == _hasUpdated)
				return;

			if (needUpdated)
			{
				UpdateManager.AddAction(OnUpdated);
				_hasUpdated = true;
			}
			else if (off)
			{
				AnimationDone();
				UpdateManager.RemoveAction(OnUpdated);
				_hasUpdated = false;
			}
		}
		
		void OnUpdated()
		{
			if (_region == null)
			{
				Fuse.Diagnostics.InternalError( "Updated called without a region", this );
				return;
			}
				
			var prev = _region.Position.X;
			_region.Update( Time.FrameInterval );
			ChangeProgress(prev, _region.Position.X, NavigationMode.Seek);

			//allow turning off update now, this ensures we always get one update when _region changed
			CheckNeedUpdate(true);
		}
		
		//only used when not rooted (_region == null)
		float _progress;
		
		void ResetRegionLimits()
		{
			_region.MaxPosition = float2(MaxIndex,0);
			_region.MinPosition = float2(0);
		}
		
		void SetProgress(float value)
		{	
			float prev;
			if (_region != null)
			{
				ResetRegionLimits();
				prev = _region.Position.X;
				_region.Position = float2((float)value,0);
				value = _region.Position.X; //in case modified somehow
			}
			else
			{
				prev = _progress;
				_progress = value;
			}
			
			ChangeProgress(prev, value, NavigationMode.Bypass);
		}
		
		float _prevProgress;
		void ChangeProgress(float prev, float next, NavigationMode mode)
		{
			_prevProgress = prev;
			OnPageProgressChanged(next, prev, mode);
		}

		public override NavigationPageState GetPageState(Visual page)
		{
			var pd = GetPageData(page);
			if (pd == null)
				return new NavigationPageState{ Progress = 0, PreviousProgress = 0 };
				
			return new NavigationPageState{ Progress = (float)Progress - pd.Index,
				PreviousProgress = (float)_prevProgress  - pd.Index };
		}
		
		public override bool CanGoForward
		{
			get
			{
				return HasPages && _active != Front;
			}
		}

		public override bool CanGoBack
		{
			get
			{
				return HasPages && _active != Back;
			}
		}

		public override void GoForward()
		{
			if (CanGoForward)
				DesiredTransition(Next);
		}

		public override void GoBack()
		{
			if (CanGoBack)
				DesiredTransition(Previous);
		}
		
		//transition to an update the desired values
		void DesiredTransition(Visual target)
		{
			UpdateDesired(target, -1);
			TransitionToChild(target);
		}
		
		internal static Selector DesiredActiveName = "DesiredActive";
		internal static Selector DesiredActiveIndexName = "DesiredActiveIndex";
		
		void UpdateDesired(Visual target, int index)
		{
			if (target != null)
			{
				var pd = GetPageData(target);
				index = pd == null ? -1 : pd.Index;
			}
			else
			{
				target = GetPage(index);
			}
			
			if (_desiredActive != target)
			{
				_desiredActive = target;
				OnPropertyChanged(DesiredActiveName);
			}
			if (_desiredIndex != index)
			{
				_desiredIndex = index;
				OnPropertyChanged(DesiredActiveIndexName);
			}
		}

		public override void OnChildAddedWhileRooted(Node child)
		{
			base.OnChildAddedWhileRooted(child);

			var v = child as Visual;
			if (v == null) return;

			if (_active != null)
				SetProgress(GetPageIndex(_active));

			GotoDesiredActive();
			OnHistoryChanged();
		}

		public override void OnChildRemovedWhileRooted(Node child)
		{
			base.OnChildRemovedWhileRooted(child);

			var v = child as Visual;
			if (v == null) return;

			if (_active == child)
				DirectSetActive(null);

			GotoDesiredActive();
			OnHistoryChanged();
			ChangeProgress((float)Progress,(float)Progress, NavigationMode.Bypass);
		}

		public float Progress
		{
			get { return _region == null ? _progress : (float)_region.Position.X; }
		}

		bool _queueClearForwardHistory;
		void AnimationDone()
		{
			if (_queueClearForwardHistory)
			{
				ClearForwardHistory();
				_queueClearForwardHistory = false;
			}

			OnNavigated(_active);
			OnHistoryChanged();
			OnStateChanged( NavigationState.Stable );
		}

		Visual _active;
		public override Visual Active
		{
			get { return _active; }
			set { SetDesiredActive(value); }
		}
		
		public Visual DesiredActive
		{
			get { return _desiredActive; }
			set { SetDesiredActive(value); }
		}
		
		public int DesiredActiveIndex
		{
			get { return _desiredIndex; }
			set { SetDesiredActiveIndex(value); }
		}
		
		void SetDesiredActive( Visual page )
		{
			UpdateDesired(page, -1);
			_desired = Desired.Active;
			GotoInternal(page, NavigationGotoMode.Transition);
		}
		
		void SetDesiredActiveIndex( int index )
		{
			UpdateDesired( null, index );
			_desired = Desired.Index;
			GotoInternal( _desiredActive, NavigationGotoMode.Transition );
		}
		
		void DirectSetActive(Visual page)
		{
			if (page == _active)
				return;

			_active = page;
			OnActiveChanged(_active);
			OnHistoryChanged();
		}

		float _seekBase;
		void ISeekableNavigation.BeginSeek()
		{
			_seekBase = (float)Progress;
			if (_region != null)
			{
				ResetRegionLimits();
				_region.StartUser();
			}
				
			OnStateChanged( NavigationState.Seek );
		}

		/**
			Number of pages in the (forward/entering, backward/exiting) direction
		*/
		public float2 SeekRange
		{
			get { return float2( (float)(-_seekBase), (float)(MaxIndex - _seekBase) ); }
		}

		void ISeekableNavigation.Seek(UpdateSeekArgs args)
		{
			if (_region == null)
			{
				Fuse.Diagnostics.InternalError( "Seek being called on an unrooted navigation", this );
				return;
			}
			
			var prev = (float)Progress;
			_region.StepUser(float2(args.RelativeDelta,0));
			ChangeProgress(prev, _region.Position.X, NavigationMode.Seek);
			CheckNeedUpdate();
		}

		void ISeekableNavigation.EndSeek(EndSeekArgs args)
		{
			//don't allow an end to interrupt something else
			if (!_region.IsUser)
				return;
				
			var targetIndex = 0;
			switch (args.SnapTo)
			{
				case SnapTo.Forward:
					targetIndex = ClampProgress((int)Math.Floor(Progress));
					break;

				case SnapTo.Backward:
					targetIndex = ClampProgress((int)Math.Ceil(Progress));
					break;

				case SnapTo.Current:
					var diff = Progress - Math.Floor(Progress);
					targetIndex = ClampProgress((diff > 0.5)
						? (int)Math.Ceil(Progress)
						: (int)Math.Floor(Progress));
					break;
			}

			if (_region != null)
				_region.EndUser(float2(args.Velocity,0));
			
			//force stop if we don't otherwise update the region (in cases where the progress doesn't change)
			UpdateDesired( null, targetIndex );
			if (!TransitionToChild(GetPage(targetIndex), false, true))
				_region.Reset(_region.Position);
		}

		void ClearForwardHistory()
		{
			if (HasPages && _active != Front)
			{
				var target = GetPageIndex(_active);
				for (int i = target-1; i >= 0; i--)
				{
					Parent.Children.Remove(GetPage(i));
				}
			}
			OnHistoryChanged();
		}

		double ClampProgress(double progress)
		{
			return Math.Clamp(progress, 0.0, (double)MaxIndex);
		}

		int ClampProgress(int progress)
		{
			return Math.Clamp(progress, 0, MaxIndex);
		}

		int MaxIndex
		{
			get { return PageCount - 1; }
		}

		Visual Back
		{
			get { return PageCount > 0 ? GetPage(MaxIndex) : null; }
		}

		Visual Front
		{
			get { return PageCount > 0 ? GetPage(0) : null; }
		}

		Visual Previous
		{
			get { return GetPage(GetPageIndex(_active)+1); }
		}

		Visual Next
		{
			get { return GetPage(GetPageIndex(_active)-1); }
		}
	}
}
