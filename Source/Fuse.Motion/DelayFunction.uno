using Uno;
using Uno.UX;
using Fuse.Reactive;

namespace Fuse.Motion
{
	[UXFunction("delay")]
	public class DelayFunction: BinaryOperator
	{
		[UXConstructor]
		public DelayFunction([UXParameter("Value")] Expression value, [UXParameter("Delay")] Expression delay): base(value, delay) {}

		protected override void OnNewOperands(IListener listener, object value, object delay)
		{
			Timer.Wait(Marshal.ToDouble(delay), new SetClosure(this, listener, value).Run);
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