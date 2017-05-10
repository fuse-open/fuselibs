using Uno.Collections;
using Uno;

namespace Fuse.Internal
{
	struct SkylineNode
	{
		public int2 Position;
		public int Width;

		/*
		                         +---------
		         X     Width     |
		        Y+---------------+
		         |
		---------+

		*/
		public SkylineNode(int2 position, int width)
		{
			Position = position;
			Width = width;
		}
	}

	class RectPacker
	{
		public int2 Size { get; private set; }
		LinkedList<SkylineNode> _skyline;

		public RectPacker(int2 size)
		{
			Size = size;
			_skyline = new LinkedList<SkylineNode>();
			_skyline.AddFirst(new SkylineNode(int2(0), Size.X));
		}

		public bool TryAdd(int2 size, out Recti rect)
		{
			// The lowest node _in the current skyline_ where size fits
			LinkedListNode<SkylineNode> lowestNode = null;
			int lowest = int.MaxValue;

			var node = _skyline.First;

			while (node != null)
			{
				int height;
				if (TryFit(node, size, out height))
				{
					if (height < lowest)
					{
						lowestNode = node;
						lowest = height;
					}
				}
				node = node.Next;
			}

			if (lowestNode == null)
			{
				rect = new Recti(0, 0, 0, 0);
				return false;
			}
			else
			{
				var x = lowestNode.Value.Position.X;
				rect = new Recti(int2(x, lowest), size);
				ReplaceNodes(lowestNode, new SkylineNode(int2(x, lowest + size.Y), size.X));
				return true;
			}
		}

		bool TryFit(LinkedListNode<SkylineNode> node, int2 size, out int height)
		{
			int remainingWidth = size.X;
			height = 0;

			while (node != null)
			{
				height = Math.Max(height, node.Value.Position.Y);
				if (height + size.Y > Size.Y) return false;
				remainingWidth -= node.Value.Width;
				if (remainingWidth <= 0) return true;
				node = node.Next;
			}

			return false;
		}

		void ReplaceNodes(LinkedListNode<SkylineNode> node, SkylineNode newSkyline)
		{
			var newNode = _skyline.AddBefore(node, newSkyline);
			int remainingWidth = newSkyline.Width;
			while (node != null && node.Value.Width <= remainingWidth)
			{
				remainingWidth -= node.Value.Width;
				var next = node.Next;
				_skyline.Remove(node);
				node = next;
			}
			if (remainingWidth > 0)
			{
				var value = node.Value;
				_skyline.Remove(node);
				_skyline.AddAfter(
					newNode,
					new SkylineNode(
						int2(
							value.Position.X + remainingWidth,
							value.Position.Y),
						value.Width - remainingWidth));
			}
			MergeNeighbours(newNode);
		}

		void MergeNeighbours(LinkedListNode<SkylineNode> node)
		{
			if (node.Next != null)
			{
				var l = node.Value;
				var r = node.Next.Value;
				if (l.Position.Y == r.Position.Y)
				{
					var newNode = _skyline.AddBefore(node, new SkylineNode(l.Position, l.Width + r.Width));
					_skyline.Remove(node.Next);
					_skyline.Remove(node);
					node = newNode;
				}
			}

			if (node.Previous != null)
			{
				var l = node.Previous.Value;
				var r = node.Value;
				if (l.Position.Y == r.Position.Y)
				{
					_skyline.AddBefore(node.Previous, new SkylineNode(l.Position, l.Width + r.Width));
					_skyline.Remove(node.Previous);
					_skyline.Remove(node);
				}
			}
		}
	}
}
