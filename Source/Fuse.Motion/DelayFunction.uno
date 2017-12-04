using Uno;
using Uno.UX;
using Fuse.Reactive;

namespace Fuse.Motion
{
	[UXFunction("delay")]
	// TODO: Should not derive from BinaryOperator
	// https://github.com/fusetools/fuselibs-public/issues/829
	public class DelayFunction: BinaryOperator
	{
		[UXConstructor]
		public DelayFunction([UXParameter("Value")] Expression value, [UXParameter("Delay")] Expression delay): base(value, delay) {}

		internal override bool OnNewOperands(IListener listener, object value, object delay)
		{
			Timer.Wait(Marshal.ToDouble(delay), new SetClosure(this, listener, value).Run);
			return true;
		}

		class SetClosure
		{
			readonly DelayFunction _func;
			readonly IListener _target;
			readonly object _v;
			public SetClosure(DelayFunction func, IListener target, object v)
			{
				_func = func;
				_target = target;
				_v = v;
			}
			public void Run()
			{
				_target.OnNewData(_func, _v);
			}
		}
	}
}