using Uno;
using Uno.Collections;

namespace Fuse.Text.Bidirectional
{
	public struct Run
	{
		public readonly Substring String;
		public readonly int Level;

		public Run(Substring str, int level)
		{
			String = str;
			Level = level;
		}

		public bool IsLeftToRight { get { return Level % 2 == 0; } }
		public bool IsRightToLeft { get { return Level % 2 != 0; } }
		public TextDirection Direction { get { return IsLeftToRight ? TextDirection.LeftToRight : TextDirection.RightToLeft; } }

		internal int LogicalStart { get { return String._start; } }
		internal int LogicalEnd { get { return String._start + String.Length; } }

		internal int VisualLeft { get { return IsLeftToRight ? LogicalStart : LogicalEnd; } }
		internal int VisualRight { get { return IsLeftToRight ? LogicalEnd : LogicalStart; } }
	}

	public static class Runs
	{
		public static List<Run> GetLogical(Substring text)
		{
			if defined(USE_ICU)
				return Implementation.UBidiRuns.GetLogical(text);
			else if defined(Android)
				return Implementation.JavaRuns.GetLogical(text);
			else build_error;
		}

		public static List<ShapedRun> GetVisual(List<ShapedRun> runs)
		{
			var resultLinkedList = GetVisual(SinglyLinkedList<ShapedRun>.FromEnumerable(runs));
			var result = new List<ShapedRun>();
			if (resultLinkedList != null)
				result.AddRange(resultLinkedList);
			assert result.Count == runs.Count;
			return result;
		}

		public static List<List<ShapedRun>> GetVisual(List<List<ShapedRun>> lines)
		{
			var result = new List<List<ShapedRun>>();
			foreach (var line in lines)
				result.Add(GetVisual(line));
			return result;
		}

		// UAX #9: Unicode Bidirectional Algorithm, 3.4, L2
		// See also: https://github.com/behdad/linear-reorder/blob/master/linear-reorder.c
		static SinglyLinkedList<ShapedRun> GetVisual(SinglyLinkedList<ShapedRun> run)
		{
			if (run == null)
				return null;

			var ranges = new Stack<Range>();

			while (run != null)
			{
				var runLevel = run.Value.Run.Level;
				var nextRun = run.Next;

				while (TryMergeRangeWithPrevious(ranges, runLevel))
				{
				}

				if (ranges.Count >= 1 && ranges.Peek().Level >= runLevel)
				{
					var range = ranges.Peek();
					if (IsRightToLeft(runLevel))
					{
						run.Next = range.Left;
						range.Left = run;
					}
					else
					{
						range.Right.Next = run;
						range.Right = run;
					}
					range.Level = runLevel;
				}
				else
				{
					ranges.Push(new Range(runLevel, run, run));
				}

				run = nextRun;
			}

			assert ranges.Count >= 1;

			while (ranges.Count >= 2)
			{
				var range = ranges.Pop();
				MergeRange(ranges, range);
			}

			var resultRange = ranges.Pop();
			resultRange.Right.Next = null;
			return resultRange.Left;
		}

		static bool IsRightToLeft(int level)
		{
			return level % 2 != 0;
		}

		static void MergeRange(Stack<Range> ranges, Range range)
		{
			assert ranges.Count >= 1;

			var previous = ranges.Peek();

			assert previous.Level < range.Level;

			if (IsRightToLeft(previous.Level))
			{
				range.Right.Next = previous.Left;
				previous.Left = range.Left;
			}
			else
			{
				previous.Right.Next = range.Left;
				previous.Right = range.Right;
			}
		}

		static bool TryMergeRangeWithPrevious(Stack<Range> ranges, int runLevel)
		{
			if (ranges.Count >= 2 && ranges.Peek().Level > runLevel)
			{
				var range = ranges.Pop();

				if (ranges.Peek().Level >= runLevel)
				{
					MergeRange(ranges, range);
					return true;
				}

				ranges.Push(range);
			}
			return false;
		}

		class Range
		{
			public int Level;
			public SinglyLinkedList<ShapedRun> Left;
			public SinglyLinkedList<ShapedRun> Right;

			public Range(int level, SinglyLinkedList<ShapedRun> left, SinglyLinkedList<ShapedRun> right)
			{
				Level = level;
				Left = left;
				Right = right;
			}
		}
	}
}
