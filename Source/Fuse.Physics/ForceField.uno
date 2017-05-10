
namespace Fuse.Physics
{
	public abstract class ForceField: Behavior, IRule
	{
		World _world;

		internal World World { get { return _world; } }

		protected override void OnRooted()
		{
			base.OnRooted();

			_world = World.FindWorld(Parent);

			_world.AddRule(this);
		}

		protected override void OnUnrooted()
		{
			_world.RemoveRule(this);

			base.OnUnrooted();
		}

		void IRule.Update(double deltaTime, World world)
		{
			OnUpdate(deltaTime, world);
		}

		protected abstract void OnUpdate(double deltaTime, World world);
	}
}
