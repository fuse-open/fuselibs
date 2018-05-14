using Uno.Collections;

using Fuse.Controls;

namespace Fuse.Charting.Test
{
	static class Util
	{
		static public string GetText(Visual p)
		{
			var q = "";
			for (int i=0; i < p.Children.Count; ++i)
			{
				var c = p.Children[i];
				var t = c as Text;
				if (t != null)
				{
					if (q != "")
						q += ",";
					q += t.Value;
				}
			}
			return q;
		}
		
		//missing functionality in our IList
		static public int IndexOf( IList<Node> list, Node obj )
		{
			for (int i=0; i < list.Count; ++i)
				if (list[i] == obj)
					return i;
			return -1;
		}
		
		static public int CountChildren<T>( Visual v )
		{
			var c = 0;
			for (int i=0; i < v.Children.Count; ++i)
			{
				if (v.Children[i] is T)
					c++;
			}
			return c;
		}
		
		static public T[] Children<T>( Visual v ) where T : class
		{
			var list = new List<T>();
			for (int i=0; i < v.Children.Count; ++i)
			{
				var q = v.Children[i] as T;
				if (q != null)
					list.Add(q);
			}
			return list.ToArray();
		}
	}
}