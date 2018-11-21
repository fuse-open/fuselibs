using Uno.UX;
using Uno.Collections;

namespace Fuse.Physics
{
	public interface IRule
	{
		void Update(double deltaTime, World world);
	}



	public class World
	{
		World() {}

		static World _globalWorld = new World();

		static PropertyHandle _worldHandle = Properties.CreateHandle();

		[UXAttachedPropertySetter("Physics.IsPhysicsWorld")]
		public static void SetIsPhysicsWorld(Visual n, bool isPhysicsWorld)
		{
			if (isPhysicsWorld)
			{
				if (n.Properties.Get(_worldHandle) == null)
					n.Properties.Set(_worldHandle, new World());
			}
			else
			{
				n.Properties.Clear(_worldHandle);
			}
		}

		[UXAttachedPropertyStyleSetter("Physics.IsPhysicsWorld")]
		public static void SetIsPhysicsWorldStyle(Visual n, bool isPhysicsWorld)
		{
			SetIsPhysicsWorld(n, isPhysicsWorld);
		}

		[UXAttachedPropertyGetter("Physics.IsPhysicsWorld")]
		public static bool GetIsPhysicsWorld(Visual n)
		{
			return n.Properties.Get(_worldHandle) != null;
		}

		internal static World FindWorld(Visual n)
		{
			var w = n.Properties.Get(_worldHandle) as World;
			if (w != null) return w;

			if (n.Parent != null) return FindWorld(n.Parent);
			
			return _globalWorld;
		}

		List<Body> _bodies = new List<Body>();

		internal List<Body> Bodies { get { return _bodies; } }

		PropertyHandle _bodyHandle = Properties.CreateHandle();

		internal Body TryGetBody(Visual node)
		{
			return node.Properties.Get(_bodyHandle) as Body;
		}

		internal Body PinBody(Visual node)
		{
			var body = TryGetBody(node);

			if (body == null)
			{
				body = new Body(this, node);
				node.Properties.Set(_bodyHandle, body);
				_bodies.Add(body);
			}

			body.PinCount++;

			EnsureSimulation();

			return body;
		}

		internal void UnpinBody(Body body)
		{
			body.PinCount--;

			if (body.PinCount == 0)
			{
				body.Visual.Properties.Clear(_bodyHandle);
				_bodies.Remove(body);
				body.Dispose();
			}

			if (_bodies.Count == 0)
			{
				EndSimulation();
			}
		}

		bool _isSimulating;

		void EnsureSimulation()
		{
			if (_isSimulating) return;
			UpdateManager.AddAction(OnUpdate, UpdateStage.Primary);
			_isSimulating = true;
		}

		void EndSimulation()
		{
			UpdateManager.RemoveAction(OnUpdate, UpdateStage.Primary);
			_isSimulating = false;
		}

		List<IRule> _rules = new List<IRule>();

		public IEnumerable<IRule> Rules { get { return _rules; } }

		internal void AddRule(IRule rule)
		{
			_rules.Add(rule);
		}

		internal void RemoveRule(IRule rule)
		{
			_rules.Remove(rule);
		}

		bool _firstFrame = true;

		void OnUpdate()
		{
			// Skip simulation first frame to allow UI to
			// properly initialize
			if (_firstFrame)
			{
				_firstFrame = false;
				return;
			}

			var deltaTime = Fuse.Time.FrameInterval;

			foreach (var r in _rules)
				r.Update(deltaTime, this);

			foreach (var b in _bodies)
				b.Update(deltaTime);
		}
	}
}