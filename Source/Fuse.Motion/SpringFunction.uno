using Uno;
using Uno.UX;
using Fuse.Reactive;

namespace Fuse.Motion
{
	[UXFunction("spring")]
	public class SpringFunction: Expression
	{
		public Expression Value { get; private set; }

		[UXConstructor]
		public SpringFunction([UXParameter("Value")] Expression value)
		{
			Value = value;
		}

		/** See `IExpression.Subscribe` for docs.	*/
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new Subscription(this, context, listener);
		}

		class Subscription: IDisposable, IListener
		{
			SpringFunction _sf;
			bool _isSimulating;
			bool _hasStartValue;
			Simulation.ElasticForce<float4> _sim = Simulation.ElasticForce<float4>.CreatePoints();
			IDisposable _valueSub;
			IListener _listener;

			public Subscription(SpringFunction sf, IContext context, IListener listener)
			{
				_sf = sf;
				_listener = listener;
				_valueSub = sf.Value.Subscribe(context, this);
			}

			public void Dispose()
			{
				if (_valueSub != null)
					_valueSub.Dispose();

				_valueSub = null;
				_listener = null;
				StopSimulation();
			}

			void IListener.OnNewData(IExpression source, object value)
			{
				var v = Marshal.ToFloat4(value);

				if (!_hasStartValue)
				{
					_sim.Reset(v);
					_hasStartValue = true;
					_listener.OnNewData(_sf, v);
				}
				else if (_sim.Destination != v)
				{
					_sim.Destination = v;
					StartSimulation();
				}
			}
			
			void IListener.OnLostData(IExpression source)
			{ 
				StopSimulation();
				if (_listener != null)
					_listener.OnLostData( source );
			}

			void StartSimulation()
			{
				if (_isSimulating) return;
				UpdateManager.AddAction(Simulate);
				_isSimulating = true;
			}

			void StopSimulation()
			{
				if (!_isSimulating) return;
				UpdateManager.RemoveAction(Simulate);
				_isSimulating = false;
			}

			void Simulate()
			{
				_sim.Update(Time.FrameInterval);
				_listener.OnNewData(_sf, _sim.Position);
				if (_sim.IsStatic) StopSimulation();
			}
		}
	}
}
