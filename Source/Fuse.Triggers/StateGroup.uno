using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse;

namespace Fuse.Triggers
{
	public enum StateTransition
	{
		Parallel,
		Exclusive,
	}

	/**
		@include Docs/StateGroup.md
	*/
	public partial class StateGroup : Behavior
	{
		IList<State> _states = new List<State>();
		[UXContent]
		public IList<State> States { get { return _states; } }

		State _active;
		public State Active
		{
			get { return _active; }
			set
			{
				if (value != _active)
					Goto(value);
			}
		}

		State _rest;
		public State Rest
		{
			get
			{
				if (_rest != null)
					return _rest;
				if (_states.Count > 0)
					return _states[0];
				return null;
			}
			set { _rest = value; }
		}

		int ActiveIndex
		{
			get
			{
				for (int i=0; i < States.Count; ++i)
					if( _active == States[i])
						return i;
				return -1;
			}
			set
			{
				Active = _states[value];
			}
		}

		public void GotoNextState()
		{
			ActiveIndex = (ActiveIndex +1) % _states.Count;
		}

		public object FindObjectByName(Selector name, Predicate<object> acceptor)
		{
			foreach (var s in States)
			{
				if (s.Name == name && acceptor(s)) return s;
			}
			return null;
		}

		StateTransition _transition;
		public StateTransition Transition
		{
			get { return _transition; }
			set { _transition = value; }
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();

			foreach (var state in _states)
			{
				Parent.Remove(state);
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			if (_active == null && _states.Count > 0)
				_active = _states[0];

			foreach (var state in _states)
			{
				state.On = state == _active;
				state.RootStateGroup(this);
				Parent.Add(state);
			}
		}

		internal void Goto(State next)
		{
			_active = next;

			//this is needed in case a state swtich results in a state switch, see `ChainedSwitch` test case
			UpdateManager.AddDeferredAction( (new GotoImpl{ Next = next, Group = this }).Go );
		}

		class GotoImpl
		{
			public State Next;
			public StateGroup Group;

			public void Go()
			{
				switch (Group.Transition)
				{
					case StateTransition.Parallel:
						foreach (var state in Group._states)
							state.On = state == Next;
						break;

					case StateTransition.Exclusive:
						foreach (var state in Group._states)
							state.On = false;
						Group.CheckAllDone();
						break;
				}
			}
		}

		//called by State to indicate the playback has stopped
		internal void StateStopped()
		{
			if (Transition == StateTransition.Exclusive)
				UpdateManager.AddDeferredAction( CheckAllDone );
		}

		void CheckAllDone()
		{
			bool all = true;
			foreach (var state in _states)
			{
				if (state.Progress > 0)
				{
					all = false;
				}
			}

			if (all && _active != null)
				_active.On = true;
		}
	}
}
