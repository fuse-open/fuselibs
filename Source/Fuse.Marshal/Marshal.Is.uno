using Uno;

namespace Fuse
{
	public partial class Marshal
	{
		public static bool Is(object obj, Type t)
		{
			if (obj == null) return false;

			if (t.IsInterface)
			{
				var intf = obj.GetType().GetInterfaces();
				for (var i = 0; i < intf.Length; i++)
					if (intf[i] == t) return true;				
			}
			else
			{
				var objType = obj.GetType();
				if (t == objType || obj.GetType().IsSubclassOf(t)) return true;
			}
			return false;
		}
	}
}