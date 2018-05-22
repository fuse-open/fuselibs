using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Motion
{
	[UXFunction("delay")]
	public class DelayFunction: Expression
	{
		Expression _value, _delay;
		
		[UXConstructor]
		public DelayFunction([UXParameter("Value")] Expression value, [UXParameter("Delay")] Expression delay)
		{
			_value = value;
			_delay = delay;
		}

		public sealed override IDisposable Subscribe(IContext context, IListener listener)
		{
			var sub = new Subscription(this,  listener);
			sub.Init(context);
			return sub;
		}
		
		class Subscription : ExpressionListener
		{
			public Subscription( DelayFunction source, IListener listener ) :
				base( source, listener, new Expression[]{ source._value, source._delay }, Flags.None )
			{ }
			
			protected override void OnArguments(Argument[] args)
			{
				//TODO: https://github.com/fuse-open/fuselibs/issues/872  This doesn't deal with lost data correctly
				//TODO: https://github.com/fuse-open/fuselibs/issues/873 doesn't handle invalid Delay
				Timer.Wait(Marshal.ToDouble(args[1].Value), new SetClosure(this, args[0].Value).Run);
			}
			
			public new void SetData(object value)
			{
				base.SetData(value);
			}
		}
		
		class SetClosure
		{
			readonly Subscription _sub;
			readonly object _v;
			public SetClosure(Subscription sub, object v)
			{
				_sub = sub;
				_v = v;
			}
			public void Run()
			{
				_sub.SetData(_v);
			}
		}
	}
}
