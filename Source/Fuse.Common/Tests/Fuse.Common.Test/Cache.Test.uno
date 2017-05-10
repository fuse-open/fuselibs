using Fuse.Internal;
using Uno;
using Uno.Collections;
using Uno.Testing;

using FuseTest;

namespace Fuse.Test
{
	public class CacheTest : TestBase
	{
		static int _disposals;
		static int _constructions;
		static int _lastDisposed;

		public class IntClass : IDisposable
		{
			public int Value;
			public IntClass(int value)
			{
				Value = value;
				++_constructions;
			}
			public void Dispose()
			{
				++_disposals;
				_lastDisposed = Value;
			}
		}

		IntClass IntClassFactory(int input)
		{
			return new IntClass(input);
		}

		[Test]
		public void GetCaches()
		{
			using (var cache = new Cache<int, IntClass>(IntClassFactory))
			{
				_constructions = 0;

				for (int i = 0; i < 10; ++i)
				{
					var item = cache.Get(i);
					Assert.AreEqual(i, item.Key);
					Assert.AreEqual(i, item.Value.Value);
					Assert.AreEqual(i + 1, _constructions);

					var item2 = cache.Get(i);
					Assert.AreEqual(i, item2.Key);
					Assert.AreEqual(i, item2.Value.Value);
					Assert.AreEqual(i + 1, _constructions);
				}
			}
		}

		[Test]
		public void CachesUnused()
		{
			using (var cache = new Cache<int, IntClass>(IntClassFactory, 2))
			{
				_constructions = 0;
				_disposals = 0;

				var _cacheItems = new List<CacheItem<int, IntClass>>();

				var n = 10;

				for (int i = 0; i < n; ++i)
					_cacheItems.Add(cache.Get(i));

				Assert.AreEqual(n, _constructions);
				Assert.AreEqual(0, _disposals);

				for (int i = 0; i < n; ++i)
				{
					_cacheItems[i].Dispose();
					_cacheItems[i] = cache.Get(i);
					Assert.AreEqual(n, _constructions);
					Assert.AreEqual(0, _disposals);
				}
			}
		}

		[Test]
		public void DisposesUnused()
		{
			var maxUnused = 5;
			var n = 10;
			using (var cache = new Cache<int, IntClass>(IntClassFactory, maxUnused))
			{
				_constructions = 0;
				_disposals = 0;

				var _cacheItems = new List<CacheItem<int, IntClass>>();

				for (int i = 0; i < n; ++i)
					_cacheItems.Add(cache.Get(i));

				Assert.AreEqual(n, _constructions);
				Assert.AreEqual(0, _disposals);

				for (int i = 0; i < n; ++i)
				{
					_cacheItems[i].Dispose();
					if (i < maxUnused)
						Assert.AreEqual(0, _disposals);
					else
						Assert.AreEqual(i - maxUnused + 1, _disposals);
				}
			}
		}

		[Test]
		public void DisposesLeastRecentlyUsedFirst()
		{
			using (var cache = new Cache<int, IntClass>(IntClassFactory, 2))
			{
				_constructions = 0;
				_disposals = 0;
				_lastDisposed = -1;

				var _cacheItems = new List<CacheItem<int, IntClass>>();

				_cacheItems.Add(cache.Get(0));
				_cacheItems.Add(cache.Get(1));
				_cacheItems.Add(cache.Get(2));
				_cacheItems.Add(cache.Get(3));
				Assert.AreEqual(4, _constructions);
				Assert.AreEqual(0, _disposals);
				_cacheItems[0].Dispose();
				Assert.AreEqual(0, _disposals);
				_cacheItems[1].Dispose();
				Assert.AreEqual(0, _disposals);
				_cacheItems[0] = cache.Get(0);
				Assert.AreEqual(4, _constructions);
				_cacheItems[0].Dispose();
				Assert.AreEqual(0, _disposals);
				_cacheItems[2].Dispose();
				Assert.AreEqual(1, _disposals);
				Assert.AreEqual(1, _lastDisposed);
				_cacheItems[3].Dispose();
				Assert.AreEqual(2, _disposals);
				Assert.AreEqual(0, _lastDisposed);
			}
		}
	}
}
