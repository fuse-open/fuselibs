
namespace Fuse.Physics
{
	/**
		@mount Physics
	*/
	public class Spring: Behavior, IRule
	{
		Visual _target;
		Body _targetBody;
		public Visual Target
		{
			get { return _target; }
			set
			{
				_target = value;
				if (_body != null)
				{
					if (_targetBody != null) _targetBody.Unpin();

					if (_target != null) _targetBody = Body.Pin(_target);
					else _targetBody = null;
				}
			}
		}

		float _length = 1.0f;
		public float Length
		{
			get { return _length; }
			set { _length = value; }
		}

		float _stiffness = 1.0f;
		public float Stiffness
		{
			get { return _stiffness; }
			set { _stiffness = value; }
		}

		Body _body;

		protected override void OnRooted()
		{
			base.OnRooted();

			_body = Body.Pin(Parent);
			_body.World.AddRule(this);
			if (_target != null) _targetBody = Body.Pin(_target);
		}

		protected override void OnUnrooted()
		{
			_body.World.RemoveRule(this);

			_body.Unpin();
			_body = null;

			if (_targetBody != null)
			{
				_targetBody.Unpin();
				_targetBody = null;
			}

			base.OnUnrooted();
		}

		void IRule.Update(double deltaTime, World world)
		{
			if (_body == null || _targetBody == null) return;

			var vec = _body.WorldPosition - _targetBody.WorldPosition;

			var dist = Uno.Vector.Length(vec);

			if (Uno.Math.Abs(dist) < 0.001f) return;

			var dir = vec / dist;

			var force = dir * (dist - Length) * (float)deltaTime * _stiffness * 100.0f;

			_targetBody.ApplyForce(force);
			_body.ApplyForce(force * -1.0f);
		}
	}
}
