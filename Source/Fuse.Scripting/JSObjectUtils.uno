namespace Fuse.Scripting
{
	public static class JSObjectUtils
	{
		public static T ValueOrDefault<T>(this Scripting.Object obj, string name, T defaultValue)
		{
			var v = obj[name];
			if(v==null) return defaultValue;
			return Marshal.ToType<T>(v);
		}

		public static T ValueOrDefault<T>(this object[] args, int index, T defaultValue = default(T))
		{
			if(index < 0 || index > args.Length-1) return defaultValue;
			return Marshal.ToType<T>(args[index]);
		}
		
		public static T Value<T>(this Scripting.Object obj, string name)
		{
			var v = obj[name];
			if(v==null) throw new Uno.ArgumentException("Property '"+name+"' does not exist on object");
			return Marshal.ToType<T>(v);
		}
		
		public static T Value<T>(this object[] args, int index)
		{
			return Marshal.ToType<T>(args[index]);
		}

		public static void Freeze(this Scripting.Object ob, Context c)
		{
			var freeze = (Scripting.Function)c.Evaluate("(Object Freeze)", "Object.freeze");
			freeze.Call(c, ob);
		}
	}
}
