using Uno;
using Uno.Collections;

using Fuse.Animations;

namespace Fuse.Triggers.Test
{
	internal class TestAnimator : Animator
	{
		public List<TestAnimatorState> Active = new List<TestAnimatorState>();

		public bool HasBack { get; set; }

		public bool IsOpen { get; set; }

		internal override AnimatorState CreateState(CreateStateParams p)
		{
			return new TestAnimatorState(this, p);
		}

		internal override AnimatorVariant AnimatorVariant
		{
			get { return HasBack ? AnimatorVariant.HasBackward : AnimatorVariant.Allow; }
		}
	}

	internal class TestAnimatorState : AnimatorState
	{
		TestAnimator _animator;
		public bool IsActive { get; private set; }

		public bool AllowStable { get; set; }

		internal TestAnimatorState(TestAnimator animator, CreateStateParams p)
			: base(p)
		{
			_animator = animator;
			_animator.Active.Add(this);
			IsActive = true;
		}

		internal override SeekResult SeekProgress(double progress, double interval, SeekDirection dir,
				double strength)
		{
			if (!IsActive)
				throw new Exception( "_isActive is false" );

			//somewhat similar to OpenAnimator
			var mayEnd = dir == SeekDirection.Forward ? progress >= 1 : progress <= 0;
			var stable = !_animator.IsOpen || AllowStable;

			var q = (stable ? SeekResult.Stable : SeekResult.None) |
				(mayEnd && stable ? SeekResult.Complete : SeekResult.None);
			return q;
		}

		internal override SeekResult SeekTime(double nominal, double interval, SeekDirection dir,
			double strength )
		{
			return SeekProgress(nominal/TotalDuration, interval, dir, strength);
		}

		public override void Disable()
		{
			if (!IsActive)
				throw new Exception( "_isActive is false" );
			IsActive = false;
			_animator.Active.Remove(this);
		}
	}
}
