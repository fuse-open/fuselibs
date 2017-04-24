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
		Used to group a set of @States together and switch between them.

		`StateGroup` has an `Active` property, which is used to assign which @(State) is currently active in that group.

		One can also specify the `Transition`, which can be either `Exclusive` or `Parallel`.
		`Exclusive` means that each state will have to be fully deactivated before the next state becomes active.
		`Parallel` means that as one state deactivates, the next one will become active and whatever properties they animate will be interpolated between them.

		# Example
		Here is an example of how to use a `StateGroup` to switch the color of a @(Rectangle) between three states:

			<StackPanel>
				<Panel Width="100" Height="100">
					<SolidColor ux:Name="someColor"/>
				</Panel>
				<StateGroup ux:Name="stateGroup">
					<State ux:Name="redState">
						<Change someColor.Color="#f00" Duration="0.2"/>
					</State>
					<State ux:Name="blueState">
						<Change someColor.Color="#00f" Duration="0.2"/>
					</State>
					<State ux:Name="greenState">
						<Change someColor.Color="#0f0" Duration="0.2"/>
					</State>
				</StateGroup>
				<Grid ColumnCount="3">
					<Button Text="Red">
						<Clicked>
							<Set stateGroup.Active="redState"/>
						</Clicked>
					</Button>
					<Button Text="Blue">
						<Clicked>
							<Set stateGroup.Active="blueState"/>
						</Clicked>
					</Button>
					<Button Text="Green">
						<Clicked>
							<Set stateGroup.Active="greenState"/>
						</Clicked>
					</Button>
				</Grid>
			</StackPanel>
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
