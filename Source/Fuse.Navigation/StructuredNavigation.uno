using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Animations;
using Fuse.Elements;
using Fuse.Motion;
using Fuse.Motion.Simulation;
using Fuse.Triggers;

namespace Fuse.Navigation
{
	public abstract partial class StructuredNavigation : VisualNavigation, ISeekableNavigation
	{
		internal enum NavigationStructure
		{
			Linear,
			Hierarchical,
		}

		protected bool _reuseExistingVisual = true;

		internal NavigationStructure Mode { get; set; }

		internal StructuredNavigation( NavigationStructure mode )
		{
			Mode = mode;
		}

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
			
		protected override void OnRooted()
		{
			base.OnRooted();
			//there's no real way to fix this "correctly" due to how HierarchicalNavigation works
			//https://github.com/fusetools/fuselibs-private/issues/1701
			if (_active != null && _active.Parent != null && Parent != _active.Parent)
				SetActive(null);

			// https://github.com/fusetools/fuselibs-private/issues/3427
			if (_active != null && !Parent.Children.Contains(_active))
				SetActive(null);
				
			if (PageCount > 0 && _active == null)
				SetActive(GetPage(0));

			if (_active != null)
				GotoImpl(_active, NavigationGotoMode.Bypass);
			
			_region = Motion.AcquireSimulation();
			_region.Position = float2(_progress,0);
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

		public override void Goto(Visual element, NavigationGotoMode mode)
		{
			if (mode != NavigationGotoMode.Transition &&
				mode != NavigationGotoMode.Bypass)
				return;
		
			if (Parent == null)
			{
				//queue until rooted
				SetActive(element);
				return;
			}

			if (element == _active)
				return;

			if (element == null)
				SetActive(null);
			else
				GotoImpl(element, mode);
		}

		public void GotoImpl(Visual element, NavigationGotoMode mode)
		{
			//https://github.com/fusetools/fuselibs-private/issues/1701
			if (element.Parent != null && element.Parent != Parent)
			{
				Fuse.Diagnostics.UserError( "Attempting to navigate to element with different parent", element );
				SetActive(null);
				return;
			}
			
			if (!Parent.Children.Contains(element))
			{
				if (Mode == NavigationStructure.Hierarchical)
				{
					ClearForwardHistory();
					Parent.Children.Insert(0, element);
				}
				else
				{
					return;
				}
			}
			else if (!_reuseExistingVisual)
			{
				if (Mode == NavigationStructure.Hierarchical)
				{
					var diff = Progress - GetPageIndex(_active);
					Parent.BeginRemoveChild(element);
					SetProgress((float)(GetPageIndex(_active) + diff));
					ClearForwardHistory();
					Parent.Children.Insert(0,element);
				}
			}

			TransitionToChild(element, mode.HasFlag(NavigationGotoMode.Bypass) );
			OnHistoryChanged();
		}
		
		public void QueueClearForwardHistory()
		{
			_queueClearForwardHistory = true;
		}

		/**
			@return true if the _region was updated
		*/
		bool TransitionToChild(Visual element, bool bypass = false, bool clamp = false)
		{
			var targetProgress = (float)GetPageIndex(element);
			SetActive(element);

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
				TransitionToChild(Next);
		}

		public override void GoBack()
		{
			if (CanGoBack)
				TransitionToChild(Previous);
		}

		//DEPRECATED: 2016-03-30
		[UXContent]
		public Easing Easing 
		{ 
			get { return Motion.GotoEasing; }
			set
			{
				Motion.GotoEasing = value;
				Fuse.Diagnostics.Deprecated( "Use a `NavigationMotion` and the `GotoEasing` property instead of `Navigation.Easing`", this );
			}
		}
		public double Duration  
		{ 
			get { return Motion.GotoDuration; }
			set
			{
				Motion.GotoDuration = (float)value;
				Fuse.Diagnostics.Deprecated( "Use a `NavigationMotion` and the `GotoDuration` property instead of `Navigation.Duration`", this );
			}
		}

		public override void OnChildAddedWhileRooted(Node child)
		{
			base.OnChildAddedWhileRooted(child);

			var v = child as Visual;
			if (v == null) return;

			if (_active != null)
				SetProgress(GetPageIndex(_active));

			if (_active == null)
				SetActive(v);

			OnHistoryChanged();
		}

		public override void OnChildRemovedWhileRooted(Node child)
		{
			base.OnChildRemovedWhileRooted(child);

			var v = child as Visual;
			if (v == null) return;

			if (_active == child)
				SetActive(null);

			OnHistoryChanged();
			ChangeProgress((float)Progress,(float)Progress, NavigationMode.Bypass);
		}

		//TODO: change to float
		public double Progress
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
			set
			{
				Goto(value, NavigationGotoMode.Transition);
			}
		}
		
		void SetActive(Visual page)
		{
			if (page == _active)
				return;

			_active = page;
			OnActiveChanged(_active);
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

	/**
		## Navigation Order
		
		The navigation order of a `LinearNavigation` is the same as the child order. Earlier children are in front of later children. The navigation progress is continuous, and pages can be more than 1 away from the active one.
		
		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public class LinearNavigation : StructuredNavigation
	{
		public LinearNavigation()
			: base( NavigationStructure.Linear )
		{ }
	}

	public class HierarchicalNavigation : StructuredNavigation
	{
		public HierarchicalNavigation()
			: base( NavigationStructure.Hierarchical )
		{ }

		public bool ReuseExistingVisual
		{
			get { return _reuseExistingVisual; }
			set { _reuseExistingVisual = value; }
		}
	}

}
