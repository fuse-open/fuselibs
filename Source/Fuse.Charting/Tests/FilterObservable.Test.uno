using Uno;
using Uno.Testing;

using Fuse.Charting;

using FuseTest;

namespace Fuse.Test
{
	public class FilterObservableTest: TestBase
	{
		[Test]
		public void Basic()
		{
			//just using a root since ObservableCollector is a behavior
			using (var root = new TestRootPanel())
			{
				var source = new ReadOnlyObservableList<string>();
				var alt  = new FilterAlternate{ Source = source };
				var calt = new FuseTest.ObservableCollector{ Items = alt };
				root.Children.Add(calt);
				root.IncrementFrame();
			
				Assert.AreEqual( "", calt.JoinValues() );
			
				source.Add( "0" );
				source.Add( "1" );
				source.Add( "2" );
				source.Add( "3" );
				root.PumpDeferred();
				Assert.AreEqual( "1,3", calt.JoinValues() );
				
				source.RemoveAt(1);
				root.PumpDeferred();
				Assert.AreEqual( "2", calt.JoinValues() );
			
				source.Add("4");
				root.PumpDeferred();
				Assert.AreEqual( "2,4", calt.JoinValues() );
				
				source.Insert(3,"5");
				root.PumpDeferred();
				Assert.AreEqual( "2,5", calt.JoinValues() );
				
				source.Replace(3,"6");
				root.PumpDeferred();
				Assert.AreEqual( "2,6", calt.JoinValues() );
				
				source.Clear();
				root.PumpDeferred();
				Assert.AreEqual( "", calt.JoinValues() );
			}
		}
		
		[Test]
		public void Random()
		{
			var r = new Random(123);
			using (var root = new TestRootPanel())
			{
				var source = new ReadOnlyObservableList<string>();
				var sa = source as IArray;
				var ends = new FilterEnd2{ Source = source };
				var calt = new FuseTest.ObservableCollector{ Items = ends };
				root.Children.Add(calt);
				root.IncrementFrame();
				
				source.Add( "X" );
				for (int i=0; i < 100; ++i)
				{
					source.Insert( r.NextInt(source.Count), "" + i );
					if (i % 3 == 0)
						source.RemoveAt( r.NextInt(source.Count) );
						
					var q = "";
					for (int j=2; j < sa.Length - 2; ++j)
					{
						if (j > 2)
							q += ",";
						q += sa[j];
					}
					root.PumpDeferred();
					Assert.AreEqual(q, calt.JoinValues() );
				}
				
				root.PumpDeferred();
				Assert.AreEqual( 67, sa.Length );
			}
		}
	}
	
	class FilterAlternate : FilterObservable
	{
		override protected bool Accept(object v, int index, int count)
		{
			return index % 2 == 1;
		}
	}
	
	class FilterEnd2 : FilterObservable
	{
		override protected bool Accept(object v, int index, int count )
		{
			return index >= 2 && index < (count - 2);
		}
	}
}