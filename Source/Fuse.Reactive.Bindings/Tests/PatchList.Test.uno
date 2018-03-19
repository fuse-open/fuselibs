using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Internal.Test
{
	public class PatchListTest : TestBase
	{
		List<string> Split(string a)
		{
			var l = new List<string>();
			if (a == "")
				return l; //split creates a 1-length item in this case
			var s = a.Split(',');
			for (int i=0; i < s.Length; ++i)
			{
				if (s[i] == "null")
					l.Add(null);
				else
					l.Add(s[i]);
			}
			return l;
		}
		
		void Check( string from, string to, PatchAlgorithm algo, string ops )
		{
			var fromList = Split(from);
			var toList = Split(to);
			var l = PatchList.Patch( fromList, toList, algo, null );
			var patch = PatchList.Format(l);
			Assert.AreEqual( ops, patch );
			
			Assert.AreEqual( Join(toList), Join(Patch(fromList,toList,l)) );
		}
		
		void Check<T>( List<T> fromList, List<T> toList, PatchAlgorithm algo, T emptyKey )
		{
			var l = PatchList.Patch( fromList, toList, algo, emptyKey );
			Assert.AreEqual( Join(toList), Join(Patch(fromList,toList,l)) );
		}
		
		List<T> Patch<T>( List<T> from, List<T> to, IList<PatchItem> ops )
		{	
			var res = new List<T>(from.Count);
			res.AddRange(from);
			
			for( int i=0; i < ops.Count; ++i)
			{
				var op = ops[i];
				switch (op.Op)
				{
					case PatchOp.Remove:
						res.RemoveAt(op.A);
						break;
					case PatchOp.Insert:
						res.Insert(op.A, to[op.Data]);
						break;
					case PatchOp.Update:
						res[op.A] = to[op.Data];
						break;
				}
			}
			
			return res;
		}
		
		[Test]
		public void RemoveAll()
		{
			Check( "1,2,3,4,5", "5,2,3", PatchAlgorithm.RemoveAll, "R0,R0,R0,R0,R0,I0=0,I1=1,I2=2");
			Check( "1,null,3", "null,2", PatchAlgorithm.RemoveAll, "R0,R0,R0,I0=0,I1=1");
		}
		
		[Test]
		public void Simple()
		{
			Check( "1,2,3", "", PatchAlgorithm.Simple, "R0,R0,R0" );
			Check( "", "1,2,3", PatchAlgorithm.Simple, "I0=0,I1=1,I2=2" );
			
			Check( "1,2,3", "1,3", PatchAlgorithm.Simple, "U0=0,R1,U1=1" );
			Check( "1,2,3,4,5,6,7", "2,3,6,8", PatchAlgorithm.Simple, "R0,U0=0,U1=1,R2,R2,U2=2,R3,I3=3" );
			Check( "1,2,3", "3,2", PatchAlgorithm.Simple, "I1=0,R0,U1=1,R2" );
			Check( "1,2,3,4,5,6", "2,5,1,4,7", PatchAlgorithm.Simple, "I0=0,I1=1,U2=2,R3,R3,U3=3,R4,R4,I4=4" );
			
			Check( "null,1", "1", PatchAlgorithm.Simple, "R0,U0=0" );
			Check( "1,2,null,3", "1,3,null", PatchAlgorithm.Simple, "U0=0,R1,R1,U1=1,I2=2" );
			Check( "null,null,null", "null,null", PatchAlgorithm.RemoveAll, "R0,R0,R0,I0=0,I1=1");
			
			//came from testing Each (ensure patch isn't failing, but each is)
			Check( "1,3,5", "6,3,7,5,8", PatchAlgorithm.Simple, "I1=0,R0,U1=1,I2=2,U3=3,I4=4" );
		}
		
		Random rand = new Random(0);
		
		[Test]
		// tests random sequences.
		public void SimpleRandom()
		{
			//was set to a really high number to test, no errors found, so just back to a low value
			for (int i=0; i < 100; ++i)
			{
				var from = ShuffledList( rand.Next(50) );
				var to = ShuffledList( rand.Next(50) );
				Check( from, to, PatchAlgorithm.Simple, -1 );
			}
		}
		
		List<int> ShuffledList(int count)
		{
			var list = new List<int>(count);
			for (int i=0; i < count; ++i)
				list.Add(i);
				
			for (int i=count-1; i > 0; --i)
			{
				var swap = rand.Next(i);
				var t = list[i];
				list[i] = list[swap];
				list[swap] = t;
			}
			
			return list;
		}
		
		static string Join<T>( List<T> t )
		{
			var q = "";
			for (int i=0; i < t.Count; ++i)
			{
				if (i>0) q += ",";
				q += t[i];
			}
			return q;
		}
		
	}
}