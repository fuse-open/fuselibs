using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Reactive
{
	/** Represents a raw JS object */
	interface IRaw
	{
		object Raw { get; }

		/**	The object that JavaScript will see if this object is passed
			back into the VM. TreeObject will override this
		*/
		object ReflectedRaw { get; }
	}

	abstract class ValueMirror: SubscriptionSubject, IRaw
	{
		public abstract void Unsubscribe();

		readonly object _raw;
		public object Raw { get { return _raw; } }
		public virtual object ReflectedRaw { get { return _raw; } }

		protected ValueMirror(object raw)
		{
			_raw = raw;
		}

		public static void Unsubscribe(object obj)
		{
			var vm = obj as ValueMirror;
			if (vm != null) vm.Unsubscribe();
		}
	}

	abstract class ListMirror: ValueMirror, IArray
	{
		public abstract int Length { get; }
		public abstract object this[int index] { get; }

		protected ListMirror(object raw) : base(raw) {}
	}
}