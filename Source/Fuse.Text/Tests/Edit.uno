using Uno;
using Uno.Collections;
using Uno.Testing;

using FuseTest;

using Fuse.Text.Test;

namespace Fuse.Text.Edit.Test
{
	public class EditTest : TestBase
	{
		string[] _singleRunStrings = new string[] {
			"",
			"car",
			"abcxyz",
		};

		string[] _singleDirStrings = new string[] {
			"",
			"car",
			"abc xyz",
			"abc xyz lol",
		};

		string[] _singleLineStrings = new string[] {
			"",
			"car",
			"abc xyz",
			"abc xyz lol",
			"CAR",
			"abc XYZ",
			"ABC xyz",
			"ABC xyz LOL",
			"abc XYZ lol",
			"ABC xyz LOL",
			"ABC XYZ lol",
		};

		string[] _strings = new string[] {
			"",
			"car",
			"abc xyz",
			"abc xyz lol",
			"abc\nxyz lol",
			"abc xyz\nlol",
			"abc\nxyz\nlol",
			"CAR",
			"abc XYZ",
			"ABC xyz",
			"ABC xyz LOL",
			"abc XYZ lol",
			"abc\nXYZ lol",
			"abc XYZ\nlol",
			"abc\nXYZ\nlol",
			"ABC\nxyz LOL",
			"ABC xyz\nLOL",
			"ABC\nxyz\nLOL",
			"ABC xyz\nLOL",
			"\nABC\nxyz\nLOL",
			"\n\nABC\n\nxyz\n\n\nLOL",
		};

		static CaretContext MockCaretContext(string source, int level = 0)
		{
			var pruns = Util.MockPositionedRuns(source, level);
			return new CaretContext(pruns, source);
		}

		[Test]
		public void LeftRightMost()
		{
			for (var level = 0; level < 2; ++level)
			foreach (var source in _strings)
			{
				var cc = MockCaretContext(source, level);
				if (source.Length > 0)
					Assert.IsTrue((int)cc.LeftMost() < (int)cc.RightMost());
				else
					Assert.AreEqual(cc.LeftMost(), cc.RightMost());
			}
		}

		[Test]
		public void MoveRight()
		{
			for (var level = 0; level < 2; ++level)
			foreach (var source in _strings)
			{
				var cc = MockCaretContext(source, level);

				var caret = cc.LeftMost();

				while (true)
				{
					var newCaret = cc.MoveRight(caret);
					if (newCaret == caret)
					{
						caret = newCaret;
						break;
					}
					Assert.IsTrue((int)newCaret > (int)caret, "Moved right: " + caret + " -> " + newCaret);
					caret = newCaret;
				}

				Assert.AreEqual(cc.RightMost(), caret);
			}
		}

		[Test]
		public void MoveLeft()
		{
			for (var level = 0; level < 2; ++level)
			foreach (var source in _strings)
			{
				var cc = MockCaretContext(source, level);

				var caret = cc.RightMost();

				while (true)
				{
					var newCaret = cc.MoveLeft(caret);
					if (newCaret == caret)
					{
						caret = newCaret;
						break;
					}
					Assert.IsTrue((int)newCaret < (int)caret, "Moved left: " + caret + " -> " + newCaret);
					caret = newCaret;
				}

				Assert.AreEqual(cc.LeftMost(), caret);
			}
		}

		[Test]
		public void MoveUpFirstLine()
		{
			var cc = MockCaretContext("abc def");
			var caret = cc.LeftMost();
			while (true)
			{
				var upCaret = cc.MoveUp(caret);
				Assert.AreEqual(cc.LeftMost(), upCaret);
				var newCaret = cc.MoveRight(caret);
				if (newCaret == caret)
				{
					caret = newCaret;
					break;
				}
				caret = newCaret;
			}
		}

		[Test]
		public void MoveDownLastLine()
		{
			var cc = MockCaretContext("abc def");
			var caret = cc.LeftMost();
			while (true)
			{
				var downCaret = cc.MoveDown(caret);
				Assert.AreEqual(cc.RightMost(), downCaret);
				var newCaret = cc.MoveRight(caret);
				if (newCaret == caret)
				{
					caret = newCaret;
					break;
				}
				caret = newCaret;
			}
		}

		[Test]
		public void MoveUp()
		{
			var cc = MockCaretContext("abc\ndef");
			for (int i = 4; i < 8; ++i)
				Assert.AreEqual((CaretIndex)(i - 4), cc.MoveUp((CaretIndex)i));
		}

		[Test]
		public void MoveDown()
		{
			var cc = MockCaretContext("abc\ndef");
			for (int i = 0; i < 4; ++i)
				Assert.AreEqual((CaretIndex)(i + 4), cc.MoveDown((CaretIndex)i));
		}

		[Test]
		public void GetVisualPosition()
		{
			for (var level = 0; level < 2; ++level)
			foreach (var source in _singleLineStrings)
			{
				var cc = MockCaretContext(source, level);
				var lastPosition = float2(-100, 0);
				for (int i = 0; i < source.Length + 1; ++i)
				{
					var position = cc.GetVisualPosition((CaretIndex)i);
					Assert.IsTrue(lastPosition.X < position.X);
				}
			}
		}

		[Test]
		public void GetClosest()
		{
			for (var level = 0; level < 2; ++level)
			foreach (var source in _singleLineStrings)
			{
				var cc = MockCaretContext(source, level);
				var closestLeft = cc.GetClosest(float2(0, 0), 20);
				var closestRight = cc.GetClosest(float2(100, 0), 20);
				if (source.Length > 0)
					Assert.IsTrue((int)closestLeft < (int)closestRight);
			}
		}

		[Test]
		public void InsertLTR()
		{
			foreach (var source in _singleDirStrings)
			{
				var cc = MockCaretContext(source);
				for (int i = (int)cc.LeftMost(); i <= (int)cc.RightMost(); ++i)
				{
					var caret = (CaretIndex)i;
					var result = cc.Insert('0', ref caret);
					Assert.AreEqual(source.Insert(i, "0"), result);
					Assert.AreEqual((int)caret - 1, i);
				}
			}
		}

		[Test]
		public void InsertRTL()
		{
			foreach (var source in _singleRunStrings)
			{
				var cc = MockCaretContext(source, 1);
				for (int i = (int)cc.LeftMost(); i <= (int)cc.RightMost(); ++i)
				{
					var caret = (CaretIndex)i;
					var result = cc.Insert('0', ref caret);
					Assert.AreEqual(source.Insert(source.Length - i, "0"), result);
					if (source.Length > 0)
						Assert.AreEqual((int)caret, i);
				}
			}
		}

		[Test]
		public void DeleteLTR()
		{
			foreach (var source in _singleDirStrings)
			{
				var cc = MockCaretContext(source);
				for (int i = (int)cc.LeftMost(); i <= (int)cc.RightMost(); ++i)
				{
					var caret = (CaretIndex)i;
					var result = cc.Delete(ref caret);
					var ir = i;
					Assert.AreEqual((int)caret, i);
					if (0 <= ir && ir < source.Length)
						Assert.AreEqual(source.DeleteAt(ref ir), result);
					else
						Assert.AreEqual(source, result);
				}
			}
		}

		[Test]
		public void DeleteRTL()
		{
			foreach (var source in _singleRunStrings)
			{
				var cc = MockCaretContext(source, 1);
				for (int i = (int)cc.LeftMost(); i <= (int)cc.RightMost(); ++i)
				{
					var caret = (CaretIndex)i;
					var result = cc.Delete(ref caret);
					if (i > 0)
					{
						var ir = source.Length - i;
						Assert.AreEqual((int)caret, Math.Max(0, i - 1));
						Assert.AreEqual(source.DeleteAt(ref ir), result);
					}
					else
					{
						Assert.AreEqual((int)caret, i);
						Assert.AreEqual(source, result);
					}
				}
			}
		}

		[Test]
		public void BackspaceLTR()
		{
			foreach (var source in _singleDirStrings)
			{
				var cc = MockCaretContext(source);
				for (int i = (int)cc.LeftMost(); i <= (int)cc.RightMost(); ++i)
				{
					var caret = (CaretIndex)i;
					var result = cc.Backspace(ref caret);
					if (i > 0)
					{
						Assert.AreEqual((int)caret, i - 1);
						var ir = i - 1;
						Assert.AreEqual(source.DeleteAt(ref ir), result);
					}
					else
					{
						Assert.AreEqual((int)caret, i);
						Assert.AreEqual(source, result);
					}
				}
			}
		}

		[Test]
		public void BackspaceRTL()
		{
			foreach (var source in _singleRunStrings)
			{
				var cc = MockCaretContext(source, 1);
				for (int i = (int)cc.LeftMost(); i <= (int)cc.RightMost(); ++i)
				{
					var caret = (CaretIndex)i;
					var result = cc.Backspace(ref caret);
					if (i < cc.RightMost())
					{
						Assert.AreEqual((int)caret, i);
						var ir = source.Length - i - 1;
						Assert.AreEqual(source.DeleteAt(ref ir), result);
					}
					else
					{
						Assert.AreEqual((int)caret, i);
						Assert.AreEqual(source, result);
					}
				}
			}
		}

		[Test]
		public void DeleteSpanLTR()
		{
			foreach (var source in _singleDirStrings)
			{
				var cc = MockCaretContext(source);
				for (int i = (int)cc.LeftMost(); i <= (int)cc.RightMost(); ++i)
				for (int j = (int)cc.LeftMost(); j <= (int)cc.RightMost(); ++j)
				{
					var caret = (CaretIndex)j;
					var result = cc.DeleteSpan((CaretIndex)i, ref caret);
					if (i == j)
					{
						Assert.AreEqual(i, (int)caret);
					}
					else
					{
						var start = Math.Min(i, j);
						var end = Math.Max(i, j) - 1;
						Assert.AreEqual(start, (int)caret);
						Assert.AreEqual(source.DeleteSpan(start, end), result);
					}
				}
			}
		}

		[Test]
		public void DeleteSpanRTL()
		{
			foreach (var source in _singleRunStrings)
			{
				var cc = MockCaretContext(source, 1);
				for (int i = (int)cc.LeftMost(); i <= (int)cc.RightMost(); ++i)
				for (int j = (int)cc.LeftMost(); j <= (int)cc.RightMost(); ++j)
				{
					var caret = (CaretIndex)j;
					var result = cc.DeleteSpan((CaretIndex)i, ref caret);
					if (i == j)
					{
						Assert.AreEqual(i, (int)caret);
					}
					else
					{
						var start = Math.Max(i, j);
						var end = Math.Min(i, j);
						var startCluster = source.Length - start;
						var endCluster = source.Length - end - 1;
						Assert.AreEqual(end, (int)caret);
						Assert.AreEqual(source.DeleteSpan(startCluster, endCluster), result);
					}
				}
			}
		}
	}
}
