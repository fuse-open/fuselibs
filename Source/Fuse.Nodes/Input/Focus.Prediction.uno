using Uno;
using Uno.Collections;
using Fuse.Input;

namespace Fuse.Input
{
	internal static class FocusPredictStrategy
	{
		public static Visual Predict(Visual n, FocusNavigationDirection direction)
		{
			if(n != null)
			{
				if (direction == FocusNavigationDirection.Down)
					return FocusPrediction.PredictNextVisual(n, Focus.CanSetFocus);

				else if (direction == FocusNavigationDirection.Up)
					return FocusPrediction.PredictPreviousVisual(n, Focus.CanSetFocus);
			}
			
			return null;
		}
	}

	internal static class FocusPrediction
	{
		class PredictFilter
		{
			Visual _origin;
			Predicate<Node> _filter;

			public PredictFilter(Visual origin, Predicate<Node> filter)
			{
				_origin = origin;
				_filter = filter;
			}

			public bool Filter(Node node)
			{
				return node != _origin && _filter(node);
			}
		}

		public static Visual PredictPreviousVisual(Visual visual, Uno.Predicate<Node> filter)
		{
			return Predict(visual, new PredictFilter(visual, filter).Filter, LastVisualChild, PreviousSibling);
		}

		public static Visual PredictNextVisual(Visual visual, Uno.Predicate<Node> filter)
		{
			return Predict(visual, new PredictFilter(visual, filter).Filter, FirstVisualChild, NextSibling);
		}

		static Visual Predict(
			Visual visual,
			Uno.Predicate<Node> filter,
			Func<Visual,Visual> getChild,
			Func<Visual,Visual> getSibling)
		{
			if (visual.Children.Count > 0)
			{
				var child = getChild(visual);
				return filter(child)
					? child
					: Predict(child, filter, getChild, getSibling);
			}
			var sibling = getSibling(visual);
			if (sibling != null)
			{
				return filter(sibling)
					? sibling
					: Predict(sibling, filter, getChild, getSibling);
			}
			return null;
		}

		static Visual NextSibling(Visual visual)
		{
			return (visual.Parent != null) 
				? NextSibling(visual.Parent, visual)
				: null;
		}

		static Visual NextSibling(Visual parent, Visual child)
		{
			var count = parent.Children.Count;
			var index = parent.Children.IndexOf(child);
			var offset = index + 1;
			if (offset < count)
			{
				for (var i = offset; i < count; i++)
				{
					var c = parent.Children[i] as Visual;
					if (c != null)
						return c;
				}
			}
			return NextSibling(parent);
		}

		static Visual PreviousSibling(Visual visual)
		{
			return (visual.Parent != null)
				? PreviousSibling(visual.Parent, visual)
				: null;
		}

		static Visual PreviousSibling(Visual parent, Visual child)
		{
			var offset = parent.Children.IndexOf(child) - 1;
			if (offset >= 0)
			{
				for (var i = offset; i >= 0; i--)
				{
					var c = parent.Children[i] as Visual;
					if (c != null)
						return c;
				}
			}
			return PreviousSibling(parent);
		}

		static Visual FirstVisualChild(Visual visual)
		{
			return visual.FirstChild<Visual>();
		}

		static Visual LastVisualChild(Visual visual)
		{
			return visual.LastChild<Visual>();
		}
	}
}
