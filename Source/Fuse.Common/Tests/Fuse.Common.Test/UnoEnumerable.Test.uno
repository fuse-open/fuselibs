using Uno;
using Uno.Collections;
using Uno.Testing;

using Fuse.Internal;

using FuseTest;

namespace Fuse.Test
{
	class SomeEnumerable<T> : IEnumerable<T> where T : class
	{
		public IEnumerator<T> GetEnumerator()
		{
			return new Enumerator(this);
		}

		public int EnumCount;
		
		class Enumerator : IEnumerator<T>, IDisposable
		{
			int _steps = 5;
			SomeEnumerable<T> _source;
			public Enumerator(SomeEnumerable<T> source)
			{
				_source = source;
				_source.EnumCount++;
			}
			
			public bool MoveNext() { 
				return --_steps > 0; 
			}
			public T Current { get { return null; } }
			public void Reset() { } 
			
			public void Dispose()
			{
				_source.EnumCount--;
			}
		}
	}
	
	public class UnoEnumerableTest : TestBase
	{
		[Test]
		public void ForeachDispose()
		{
			var q = new SomeEnumerable<string>();
			foreach (var s in q) { }
			Assert.AreEqual(0, q.EnumCount);
		}
		
		[Test]
		public void ForeachDisposeException()
		{
			var q = new SomeEnumerable<string>();
			try 
			{
				foreach (var s in q) 
				{
					throw new Exception( "Ensure dispose called" );
				}
			} 
			catch (Exception e) 
			{
			}
			Assert.AreEqual(0, q.EnumCount);
		}
		
		[Test]
		public void UsingDispose()
		{
			var q = new SomeEnumerable<string>();
			using (var iter = q.GetEnumerator())
			{
				while (iter.MoveNext()) { }
			}
			Assert.AreEqual(0, q.EnumCount);
		}
		
		[Test]
		public void UsingDisposeException()
		{
			var q = new SomeEnumerable<string>();
			try 
			{
				using (var iter = q.GetEnumerator())
				{
					while (iter.MoveNext()) 
					{ 
						throw new Exception( "Ensure Dispose called" );
					}
				}
			}
			catch (Exception e) 
			{
			}
			Assert.AreEqual(0, q.EnumCount);
		}
	}
}
