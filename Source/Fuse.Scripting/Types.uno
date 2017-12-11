using Uno;

namespace Fuse.Scripting
{
	/** A JavaScript array handle.

		@advanced
	*/
	public abstract class Array : IArray
	{
		/** @advanced */
		public abstract object this[int index] { get; set; }
		public abstract int Length { get; }
		public abstract bool Equals(Array a);

		public override bool Equals(object o)
		{
			var a = o as Array;
			return a != null && Equals(a);
		}

		public override int GetHashCode()
		{
			return base.GetHashCode();
		}
	}

	/** A JavaScript object handle.

		@advanced
	*/
	public abstract class Object : IObject
	{
		/** @advanced */
		public abstract object this[string key] { get; set; }
		public abstract string[] Keys { get; }

		public abstract bool InstanceOf(Context context, Function type);
		[Obsolete("use InstanceOf(Context, Function) instead")]
		public abstract bool InstanceOf(Function type);

		public abstract object CallMethod(Context context, string name, params object[] args);
		[Obsolete("use CallMethod(Context, Function) instead")]
		public abstract object CallMethod(string name, params object[] args);

		public abstract bool ContainsKey(string key);
		public abstract bool Equals(Object o);

		public override bool Equals(object o)
		{
			var a = o as Object;
			return a != null && Equals(a);
		}

		public override int GetHashCode()
		{
			return base.GetHashCode();
		}
	}

	/** A JavaScript function handle.

		@advanced
	*/
	public abstract class Function
	{
		public abstract object Call(Context context, params object[] args);

		[Obsolete("use Call(Context, params object[]) instead")]
		public abstract object Call(params object[] args);

		internal void CallDiscardingResult(Context context, params object[] args)
		{
			Call(context, args);
		}

		public abstract Scripting.Object Construct(Context context, params object[] args);
		[Obsolete("use Construct(Context, params object[]) instead")]
		public abstract Scripting.Object Construct(params object[] args);

		public abstract bool Equals(Function f);

		public override bool Equals(object o)
		{
			var a = o as Function;
			return a != null && Equals(a);
		}

		public override int GetHashCode()
		{
			return base.GetHashCode();
		}
	}

	/** An Uno error catchable in JavaScript.

		@advanced
	*/
	public class Error: Uno.Exception
	{
		public Error(string message) : base(message) {}
	}

	public static class Value
	{
		public static double ToNumber(object obj)
		{
			if (obj is double) return (double)obj;
			if (obj is float) return (double)(float)obj;
			if (obj is int) return (double)(int)obj;
			if (obj is uint) return (double)(uint)obj;
			return 0;
		}
	}

	/** An Uno object wrapped for being passed to and from JavaScript.

		@advanced
	*/
	public sealed class External
	{
		public readonly object Object;

		public External(object o)
		{
			Object = o;
		}

		public override bool Equals(object o)
		{
			var that = o as External;
			return that != null && Object.Equals(that.Object);
		}

		public override int GetHashCode()
		{
			return Object.GetHashCode();
		}
	}

	/** A JavaScript to Uno callback.

		@advanced
	*/
	public delegate object Callback(Context context, object[] args);
}
