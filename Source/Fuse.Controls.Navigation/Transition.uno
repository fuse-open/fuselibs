using Uno;
using Uno.Collections;

using Fuse.Animations;
using Fuse.Controls;
using Fuse.Internal;
using Fuse.Navigation;

namespace Fuse.Triggers
{
	class TransitionGroup
	{
		static Dictionary<Node, TransitionGroup> _groupMap = new Dictionary<Node, TransitionGroup>();
		
		static public TransitionGroup Root( Transition t )
		{
			var q = t.ContextParent;
			Navigator nav = null;
			while (q != null && nav == null)
			{
				nav = q as Navigator;
				q = q.ContextParent;
			}
			if (nav == null)
			{
				Fuse.Diagnostics.UserError( "Transition must have a Navigator ancestor", t );
				return null;
			}
			
			var vis = t.Parent as Visual;
			if (vis == null)
			{
				Fuse.Diagnostics.UserError( "Transition must have a Visual parent", t );
				return null;
			}
			
			TransitionGroup tg;
			if (!_groupMap.TryGetValue( t.Parent, out tg ) )
			{
				tg = new TransitionGroup(nav, vis);
				_groupMap[t.Parent] = tg;
			}
			
			tg.Add(t);
			return tg;
		}
		
		Navigator _navigator;
		Visual _parent;
		public TransitionGroup(Navigator navigator, Visual parent)
		{
			_parent = parent;
			_navigator = navigator;
			_navigator.Switched += OnSwitched;
		}

		public Navigator Navigator { get { return _navigator; } }
		
		public Visual Page { get { return _parent; } }
		
		public void ReleasePage()
		{
			_navigator.ReleasePage(_parent);
		}
		
		void Cleanup()
		{
			_navigator.Switched -= OnSwitched;
		}
		
		List<Transition> _states = new List<Transition>();
		public void Add(Transition t)
		{
			_states.Add(t);
		}
		
		public void Unroot(Transition t)
		{
			_states.Remove(t);
			if (_states.Count == 0)
			{
				Cleanup();
				_groupMap.Remove(_parent);
			}
		}
		
		static internal int TestMemoryCount { get { return _groupMap.Count; } }
		
		void OnSwitched(object sender, NavigatorSwitchedArgs args)
		{
			int activeDirection = args.OldVisual == _parent ? -1 :
				args.NewVisual == _parent ? 1 : 0;
			if (activeDirection == 0 && _selected != null)
			{
				SelectTransition(_selected);
				return;
			}
			
			var thisActive = activeDirection == 1;
			var isBackward = args.Operation == RoutingOperation.Pop;
			
			Transition selectTrans = null;
			int prio = -1;
			for (int i=0; i < _states.Count; ++i)
			{
				int p = _states[i].Priority(thisActive, isBackward, args.NewPath, args.OldPath, args.Mode,
					args.OperationStyle);
				if (p > prio)
				{
					selectTrans = _states[i];
					prio = p;
				}
			}

			//if none then add in a default handler
			if (selectTrans == null && _navigator.Transition != NavigationControlTransition.None)
			{
				var forward = thisActive != isBackward;
				var trans = new Transition();
				trans.UseTransition = NavigationControlTransition.Default;
				//back/front will cover all cases, here we only add the one needed in case another
				//transition covers the other case
				trans.Direction = forward ? TransitionDirection.InFront : TransitionDirection.Behind;
				
				//this will be left in the children so it matches in the future, preventing the default match again
				_parent.Children.Add(trans);
				selectTrans = trans;
			}
			
			SelectTransition(selectTrans);
		}
		
		Transition _selected;
		void SelectTransition(Transition which)
		{
			for (int i=0; i < _states.Count; ++i)
				_states[i].IsSelected = _states[i] == which;
			
			_selected = which;
		}
	}
	
	/**
		Limits the `Transition` to match in a particular direction, relative to the page, of navigation.
	*/
	public enum TransitionDirection
	{
		/**
			Matches any transition.
		*/
		Any,
		
		/**
			Matches if the page is in front of, or will be in front of, the active page.
			
			This matches in both a forward and backward direction.
		*/
		InFront,
		/**
			Matches if the page is behind, or will be behind, the active page.
			
			This matches in both a forward and backward direction.
		*/
		Behind,
		
		/** Matches only when the page is becoming the active one. */
		ToActive,
		/** Matches only when the page is becoming an inactive one. */
		ToInactive,
		
		/** Matches when the page is becoming inactive and moving behind the active one. */
		ToBack,
		/** Matches when the page is becoming active and moving from behind the active one. */
		FromBack,
		/** Matches when the page is becoming inactive and moving in front of the active one. */
		ToFront,
		/** Matches when the page is becoming active and moving from in front of the active one. */
		FromFront,
	}

	public enum TransitionMode
	{
		/** Matches an interactive or non-interactive transition */
		Any,
		/** Matches only if the transition was not a Prepare type */
		NonPrepare,
		/** Matches only if the transition was a Prepare type, such as used in swiping */
		Prepare,
	}
	
	/**
		Controls the animations for page-to-page transitions in a `Navigator`.
		
		@include Docs/Transition.md
	
		## Extended Example
		
		The [Transition Example](https://github.com/fusetools/fuse-samples/tree/master/Samples/UIStructure/Transition) shows a variety of page transitions using `Transition`.
	*/
	public class Transition : Trigger
	{
		static string Join( ref MiniList<string> list )
		{
			var o = "";
			for (int i=0; i < list.Count; ++i)
			{
				if (i != 0)
					o += ",";
				o += list[i];
			}
			return o;
		}
		
		static void Parse( ref MiniList<string> list, string src )
		{
			list.Clear();
			var s = src.Split(',');
			for (int i=0; i < s.Length; ++i)
				list.Add(s[i].Trim());
		}
		
		MiniList<string> _to;
		/**
			"To" pages matching thing `Transition`. If specified only transitions to one of these pages will match the trigger. See the remarks on @Transition about backward navigation.
			
			This is a comma-separated list of page names.
		*/
		public string To
		{
			get { return Join(ref _to); }
			set { Parse( ref _to, value); }
		}
		
		MiniList<string> _from;
		/**
			"From" pages matching thing `Transition`. If specified only transitions from one of these pages will match the trigger. See the remarks on @Transition about backward navigation.
			
			This is a comma-separated list of page names.
		*/
		public string From
		{
			get { return Join(ref _from); }
			set { Parse( ref _from,value); }
		}
		
		TransitionDirection _direction = TransitionDirection.Any;
		/**
			Which navigation directions, of the page, match this transition.

			This can be used on its own or in addition to a `To` or `From` filter.
		*/
		public TransitionDirection Direction
		{
			get { return _direction; }
			set { _direction = value; }
		}

		bool _autoRelease = true;
		/**
			By default a page will be released once the transition to the inactive state is complete (at the end of this trigger). Set to `false` to disable this behaviour.
			
			Refer to @Navigator to understand the significant of released pages.
		*/
		public bool AutoRelease
		{
			get { return _autoRelease; }
			set { _autoRelease = value; }
		}

		TransitionMode _mode = TransitionMode.Any;
		public TransitionMode Mode
		{
			get { return _mode; }
			set { _mode = value; }
		}
		
		string _style = null;
		/** If non-null then only a navigation operation style will match this transition. */
		public String Style
		{
			get { return _style; }
			set { _style = value; }
		}
		
		NavigationControlTransition _useTransition = NavigationControlTransition.None;
		/**
			Selects a standard transition to use instead of a custom one.
			
			Note that [Navigator.Transition](api:fuse/controls/navigationcontrol/transition) will be automatically used if no matching `Transition` is found, thus it may not be necessary to use the `UseTransition` property.
		*/
		public NavigationControlTransition UseTransition
		{
			get { return _useTransition; }
			set { _useTransition = value; }
		}
		
		TransitionGroup _group;
		protected override void OnRooted()
		{
			base.OnRooted();
			_group = TransitionGroup.Root(this);
			//_group may be null
		
			if (_group != null)
			{
				AddUseTransition();
				_group.Navigator.SetTransitionState(this, false);
				_group.Navigator.PageProgressChanged += OnPageProgressChanged;
			}
		}
		
		Animator _useAnimator;
		void AddUseTransition()
		{
			var use = UseTransition;
			if (use == NavigationControlTransition.Default)
				use = _group.Navigator.Transition;
				
			switch (use)
			{
				case NavigationControlTransition.Default: //unexpected
				case NavigationControlTransition.None:
					break;
					
				case NavigationControlTransition.Standard:
				{
					//This is meant to match the NavigationInternal.NavEnterHorizontal or NavExitHorizontal
					var  move = new Move();
					move.X = this.Direction == TransitionDirection.InFront ? 1 : -1;
					move.RelativeTo = TranslationModes.ParentSize;
					move.Duration = 0.3;
					move.Easing = Easing.QuadraticInOut;
					_useAnimator = move;
					break;
				}
			}
			
			if (_useAnimator != null)
				Animators.Add(_useAnimator);
		}
		
		protected override void OnUnrooted()
		{
			if (_useAnimator != null)
				Animators.Remove(_useAnimator);
				
			if (_group != null)
			{
				_group.Navigator.PageProgressChanged -= OnPageProgressChanged;
				_group.Navigator.SetTransitionState(this, false);
				_group.Unroot(this);
			}
			base.OnUnrooted();
		}
		
		internal int Priority(bool isActive, bool isBackward, string newPath, string oldPath,
			NavigationGotoMode mode, string operationStyle)
		{
			var normActive = isActive != isBackward;
			var toPath = isBackward ? oldPath : newPath;
			var fromPath = isBackward ? newPath : oldPath;
			
			int priority = 0;
			if (Direction != TransitionDirection.Any)
			{
				var exclude = false;
				
				switch (Direction)
				{
					case TransitionDirection.InFront:
						priority = 1;
						exclude = isActive == isBackward;
						break;
						
					case TransitionDirection.Behind:
						priority = 1;
						exclude = isActive != isBackward;
						break;
						
					case TransitionDirection.ToActive:
						priority = 2;
						exclude = !isActive;
						break;
						
					case TransitionDirection.ToInactive:
						priority = 2;
						exclude = isActive;
						break;
						
						
					case TransitionDirection.ToBack:
						priority = 3;
						exclude = isBackward || isActive;
						break;
						
					case TransitionDirection.ToFront:
						priority = 3;
						exclude = !isBackward || isActive;
						break;
						
					case TransitionDirection.FromBack:
						priority = 3;
						exclude = !isBackward || !isActive;
						break;

					case TransitionDirection.FromFront:
						priority = 3;
						exclude = isBackward || !isActive;
						break;
				}
				
				if (exclude)
					return -1;
			}
			
			if (Style != null)
			{
				priority += 1000;
				if (Style != operationStyle)
					return -1;
			}
			
			if (Mode != TransitionMode.Any)
			{
				priority += 100;
				if (Mode == TransitionMode.Prepare && mode != NavigationGotoMode.Prepare)
					return -1;
				if (Mode == TransitionMode.NonPrepare && mode == NavigationGotoMode.Prepare)
					return -1;
			}
			
			if (_to.Count > 0)
			{
				if (!normActive && _to.Contains(toPath))
					return priority + 20;
				return -1;
			}
			
			if (_from.Count > 0)
			{
				if (normActive && _from.Contains(fromPath))
					return priority + 10;
				return -1;
			}
			
			return priority;
		}
		
		protected override void OnProgressChanged()
		{
			base.OnProgressChanged();
			//TODO: SeekForward needs to be handled as well, but it can't release immediately, must wait
			//for user to release and animation to end
			if (_group != null && Progress >= 1 && PlayState == TriggerPlayState.Forward
				&& AutoRelease)
				UpdateManager.AddDeferredAction(_group.ReleasePage);
		}
		
		protected override void OnPlayStateChanged(TriggerPlayState state)
		{
			if (_group == null)
				return;
				
			_group.Navigator.SetTransitionState(this, state != TriggerPlayState.Stopped);
		}
		
		internal void QuickDeactivate()
		{ 
			if (Progress < 1)
				Deactivate();
			else
				BypassDeactivate(); 
		}
		
		internal void DoBypassDeactivate() { BypassDeactivate(); }
		internal void DoBypassActivate() { BypassActivate(); } 
		internal void DoPulseBackward() { PulseBackward(); }
		internal void DoActivate() { Activate(); }
		
		internal bool IsSelected = false;
		
		void OnPageProgressChanged(object sender, NavigationArgs args)
		{
			if (!IsSelected || _group == null)
			{
				if (args.Mode == NavigationMode.Bypass)
					BypassDeactivate();
				else
					QuickDeactivate();
				return;
			}

			//NOTE: This is very similar to NavigationAnimation.OnNavigationStateChanged/GoProgress
			var ps = (_group.Navigator as INavigation).GetPageState(_group.Page);
			var d = (Math.Abs(ps.PreviousProgress) < Math.Abs(ps.Progress)) ?
				AnimationVariant.Forward : AnimationVariant.Backward;
			var p = Math.Abs(ps.Progress);
			if (args.Mode == NavigationMode.Switch)
			{
				//TODO: like GoProgress should this also delay? mortoray: my branch is meant to address
				//such lag, so possibly not
				//ref: https://github.com/fusetools/fuselibs-private/issues/2652
				PlayTo(p, d);
			}
			else if (args.Mode == NavigationMode.Seek)
			{
				DirectSeek(p, d);
			}
			else
			{
				BypassSeek(p, d);
			}
		}
	}	
	
}