using Uno; 
using Uno.UX;

namespace Fuse
{
	public abstract partial class Node
	{
		Selector _name;
		[UXName]
		/** Run-time name of the node.
			This property is automatically set using the ux:Name attribute. */
		public Selector Name
		{
			get { return _name; }
			set 
			{ 
				if (_name != value)
				{
					_name = value;


					if (IsRootingStarted)
					{
						// Name could be changed during rooting, so we have to set it to be sure
						NameRegistry.SetName(this, _name);
					}
				}
			}
		}

		/** Finds the first node with a given name that satisfies the given acceptor.
			The serach algorithm works as follows: Nodes in the subtree are matched first, then 
			it matches the nodes in the subtrees ofthe ancestor nodes by turn all the way to the
			root. If no matching node is found, the function returns null.
		*/
		public Node FindNodeByName(Selector name, Predicate<Node> acceptor = null)
		{
			var objs = NameRegistry.GetObjectsWithName(name);
			if (objs == null) return null;

			int bestDistance = int.MaxValue;
			Node best = null;
			for (int i = 0; i < objs.Count; i++)
			{
				var n = objs[i];
				if (acceptor != null && !acceptor(n)) continue;

				var dist = DistanceTo(n, bestDistance);
				if (dist < bestDistance)
				{
					bestDistance = dist;
					best = n;
				}

				if (bestDistance == 0) return best;
			}

			return best;
		}

		int DistanceTo(Node obj, int reference)
		{
			var p = this;
			int c = 0;
			while (p != null)
			{
				if (p.HasInSubtree(obj)) return c;
				c++;
				// Optimization - avoid recursing all the way to root
				// if we already know it is not going to win
				if (c > reference) return c;
				p = p.Parent;
			}
			return int.MaxValue;
		}

		bool HasInSubtree(Node c)
		{
			if (c == this) return true;

			if (c != null)
			{
				var p = c.Parent;
				if (p != null) return HasInSubtree(p);
			}
			return false;
		}
		
	}
}