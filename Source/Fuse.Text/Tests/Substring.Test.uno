using Uno.Collections;
using Uno.Testing;
using Uno;

using FuseTest;

namespace Fuse.Text.Test
{
	public class SubstringTest : TestBase
	{
		string[] _simpleStrings = new string[] { "", "a", "ab", "abc 123" };

		[Test]
		public void ToStringTests()
		{
			foreach (var s in _simpleStrings)
				Assert.AreEqual(new Substring(s).ToString(), s);

			foreach (var s in _simpleStrings)
				for (int start = 0; start < s.Length; ++start)
					Assert.AreEqual(new Substring(s, start).ToString(), s.Substring(start));

			foreach (var s in _simpleStrings)
				for (int start = 0; start < s.Length; ++start)
					for (int end = start; end <= s.Length; ++end)
						Assert.AreEqual(new Substring(s, start, end - start).ToString(), s.Substring(start, end - start));
		}

		[Test]
		public void Indexing()
		{
			foreach (var s in _simpleStrings)
				for (int start = 0; start < s.Length; ++start)
					for (int end = start; end <= s.Length; ++end)
					{
						var substr = new Substring(s, start, end - start).ToString();
						var str = s.Substring(start, end - start);
						Assert.AreEqual(substr.Length, str.Length);
						for (int i = 0; i < substr.Length; ++i)
							Assert.AreEqual(substr[i], str[i]);
					}
		}

		void GetSubstringTest(Substring substr)
		{
			var str = substr.ToString();
			for (int start = 0; start < substr.Length; ++start)
			{
				Assert.AreEqual(substr.GetSubstring(start).ToString(), str.Substring(start));

				for (int end = start; end <= substr.Length; ++end)
					Assert.AreEqual(substr.GetSubstring(start, end - start).ToString(), str.Substring(start, end - start));
			}
		}

		[Test]
		public void GetSubstring()
		{
			foreach (var s in _simpleStrings)
				for (int start = 0; start < s.Length; ++start)
					for (int end = start; end <= s.Length; ++end)
						GetSubstringTest(new Substring(s, start, end - start));
		}

		string[] _lineStrings = new string[]
		{
			"",
			"\n",
			"abc 1",
			"\nabc 1",
			"abc 1\n",
			"abc 1\nabc 2",
			"abc 1\n\rabc 2",
			"abc 1\r\nabc 2",
			"abc 1\nabc 2\nabc 3",
			"abc 1\nabc 2\nabc 3\n",
			"\nabc 1\nabc 2\nabc 3",
		};

		[Test]
		public void Lines1()
		{
			foreach (var s in _lineStrings)
			{
				for (int start = 0; start < s.Length; ++start)
					for (int end = start; end <= s.Length; ++end)
					{
						Assert.AreCollectionsEqual(
							new Substring(s, start, end - start).Lines,
							new Substring(s.Substring(start, end - start)).Lines);
					}
			}
		}

		[Test]
		public void Lines2()
		{
			Assert.AreCollectionsEqual(
				new Substring("").Lines,
				new Substring[] { new Substring("") });

			Assert.AreCollectionsEqual(
				new Substring("\n").Lines,
				new Substring[] { new Substring(""), new Substring("\n") });

			Assert.AreCollectionsEqual(
				new Substring("abc 1").Lines,
				new Substring[] { new Substring("abc 1") });

			Assert.AreCollectionsEqual(
				new Substring("\nabc 1").Lines,
				new Substring[] { new Substring(""), new Substring("\nabc 1") });

			Assert.AreCollectionsEqual(
				new Substring("abc 1\n").Lines,
				new Substring[] { new Substring("abc 1"), new Substring("\n") });

			Assert.AreCollectionsEqual(
				new Substring("abc 1\nabc 2").Lines,
				new Substring[] { new Substring("abc 1"), new Substring("\nabc 2") });

			Assert.AreCollectionsEqual(
				new Substring("abc 1\n\rabc 2").Lines,
				new Substring[] { new Substring("abc 1"), new Substring("\n\rabc 2") });

			Assert.AreCollectionsEqual(
				new Substring("abc 1\r\nabc 2").Lines,
				new Substring[] { new Substring("abc 1"), new Substring("\r\nabc 2") });

			Assert.AreCollectionsEqual(
				new Substring("abc 1\nabc 2\nabc 3").Lines,
				new Substring[] { new Substring("abc 1"), new Substring("\nabc 2"), new Substring("\nabc 3") });

			Assert.AreCollectionsEqual(
				new Substring("abc 1\nabc 2\nabc 3\n").Lines,
				new Substring[] { new Substring("abc 1"), new Substring("\nabc 2"), new Substring("\nabc 3"), new Substring("\n") });

			Assert.AreCollectionsEqual(
				new Substring("\nabc 1\nabc 2\nabc 3").Lines,
				new Substring[] { new Substring(""), new Substring("\nabc 1"), new Substring("\nabc 2"), new Substring("\nabc 3")});
		}

		[Test]
		public void Lines3()
		{
			foreach (var s in _lineStrings)
			{
				var str = "";
				foreach (var line in new Substring(s).Lines)
					str += line;
				Assert.AreEqual(s, str);
			}
		}
	}
}
