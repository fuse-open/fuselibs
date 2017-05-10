using Uno;

using Fuse;
using Fuse.Triggers;
using Fuse.Elements;

namespace Fuse.Triggers
{
	/**
		@mount Animation
	*/
	public partial class PullToReload
	{
		StateGroup StateGroup = new StateGroup();

		void EnsureStates()
		{
			for (int i = 0; i < StateGroup.States.Count; i++)
			{
				if (!IsState(StateGroup.States[i]))
					StateGroup.States.RemoveAt(i--);
			}
			Ensure(Rest);
			Ensure(Pulling);
			Ensure(PulledPastThreshold);
			Ensure(Loading);
		}

		void Ensure(State s)
		{
			if (!StateGroup.States.Contains(s)) StateGroup.States.Add(s);
		}

		bool IsState(State s)
		{
			return s == Rest || s == Pulling || s == PulledPastThreshold || s == Loading;
		}

		State _rest, _pulling, _pulledPastThreshold, _loading;
		public State Rest
		{
			get { return _rest; }
			set { _rest = value; EnsureStates(); }
		}
		public State Pulling
		{
			get { return _pulling; }
			set { _pulling = value; EnsureStates(); }
		}
		public State PulledPastThreshold
		{
			get { return _pulledPastThreshold; }
			set { _pulledPastThreshold = value; EnsureStates(); }
		}
		public State Loading
		{
			get { return _loading; }
			set { _loading = value; EnsureStates(); }
		}

		public event VisualEventHandler ReloadHandler;

		protected override void OnRooted()
		{
			base.OnRooted();

			//default to fallback states to make them optional (do now to avoid unnecessary instantiation)
			if (_rest == null)
				Rest = new State();
			if (_pulling == null)
				Pulling = Rest ?? new State();
			if (_pulledPastThreshold == null)
				PulledPastThreshold = Pulling ?? new State();
			if (_loading == null)
				Loading = Rest ?? new State();

			StateGroup.Active = Rest;
			Relate(Parent, StateGroup);
		}

		protected override void OnUnrooted()
		{
			Unrelate(Parent, StateGroup);
			base.OnUnrooted();
		}

		bool _isLoading, _internLoading;
		public bool IsLoading
		{
			get { return _isLoading; }
			set
			{
				_isLoading = value;
				_internLoading = value;
				if (_isLoading)
					StateGroup.Active = Loading;
				else
					StateGroup.Active = Rest;
			}
		}

		bool threshold;
		void StartPull()
		{
			if (IsLoading || _internLoading)
				return;

			threshold = false;
			StateGroup.Active = Pulling;
		}

		void ReleasePull()
		{
			if (IsLoading || _internLoading)
				return;

			if (threshold)
			{
				//this prevents further loading changes until loading operation is done
				_internLoading = true;
				StateGroup.Active = Loading;
				if (ReloadHandler != null)
					ReloadHandler(this, new VisualEventArgs(Parent));
			}
			else
				StateGroup.Active = Rest;
		}

		void ReachThreshold()
		{
			if (IsLoading || _internLoading)
				return;

			threshold = true;
			StateGroup.Active = PulledPastThreshold;
		}
	}

}
