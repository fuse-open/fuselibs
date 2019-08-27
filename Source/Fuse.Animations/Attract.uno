using Uno;
using Uno.UX;

using Fuse;
using Fuse.Motion;
using Fuse.Motion.Simulation;
using Fuse.Reactive;

namespace Fuse.Animations
{
	/** 
		A configuration for use with the `attract` expression or to an `Attractor` property.

		A single `AttractorConfig` can be used for multiple `attract` expressions.
		
		@see @Attract
	*/
	public class AttractorConfig : DestinationMotionConfig
	{
	}
	
	[UXFunction("attract")]
	/**
		Animates the change in a value.
		
		The syntax is `attract( value, config )`
		
		This requires an @AttractorConfig that defines the style of the animation.
		
		# Example
		
			<AttractorConfig Unit="Points" Easing="SinusoidalInOut" Duration="0.3" ux:Global="asPoints"/>
			
			<Panel>
				<Translation X="attract({xOffset}, asPoints)"/>
			</Panel>
			
		Where `xOffset` is a context variable.
	*/
	public sealed class Attract : Fuse.Reactive.Expression
	{
		Fuse.Reactive.Expression _sourceValue;
		AttractorConfig _config;
		
		[UXConstructor]
		public Attract([UXParameter("Value")] Fuse.Reactive.Expression value, 
			[UXParameter("Config")] AttractorConfig config )
		{
			_config = config;
			_sourceValue = value;
		}
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			var sub = new Subscription(this, context, listener);
			sub.Init(context);
			return sub;
		}
		
		class Subscription : InnerListener
		{
			IListener _target;
			Attract _attract;
			IDisposable _sourceSub;
			
			//we need to support these four possibilties to avoid having special `attract/2/3/4` functions per type
			//TODO: Perhaps this can be simplified if the adapters for simulation (angular) just dealt with
			//non-scale types (we could just use float4 again for everything)
			DestinationBehavior<float4> _simulation4;
			DestinationBehavior<float3> _simulation3;
			DestinationBehavior<float2> _simulation2;
			DestinationBehavior<float> _simulation1;
			int _simSize;
			
			public Subscription(Attract attract, IContext context, IListener target)
			{
				_target = target;
				_attract = attract;
				_simulation4 = new DestinationBehavior<float4>();
				_simulation4.Motion = attract._config;
			}
			
			public void Init(IContext context)
			{
				_sourceSub = _attract._sourceValue.Subscribe(context, this);
			}
			
			void OnValueUpdate<T>(T value)
			{
				if (_target == null) //safety
					return;
				_target.OnNewData(_attract, value);
			}
			void OnValueUpdate4(float4 value) { OnValueUpdate(value); }
			void OnValueUpdate3(float3 value) { OnValueUpdate(value); }
			void OnValueUpdate2(float2 value) { OnValueUpdate(value); }
			void OnValueUpdate1(float value) { OnValueUpdate(value); }

			//these must be filtered out since they'll permanently break the simulation
			bool BadValue( float4 value ) 
			{
				var q = value.X + value.Y + value.Z + value.W;
				return float.IsInfinity(q) || float.IsNaN(q);
			}
			
			protected override void OnNewData( IExpression source, object oValue )
			{
				var value = float4(0);
				int size = 0;
				if (!Marshal.TryToZeroFloat4(oValue, out value, out size) || BadValue(value))
				{
					//invalid values can simply discard the simulation (forcing a new one to be created when
					//a good value arrives)
					CleanSimulation();
					if (_target != null)
						_target.OnLostData(_attract);
					return;
				}

				NeedSim(size);
				
				if (_simulation1 != null)
					_simulation1.SetValue( value.X, OnValueUpdate1 );
				if (_simulation2 != null)
					_simulation2.SetValue( value.XY, OnValueUpdate2 );
				if (_simulation3 != null)
					_simulation3.SetValue( value.XYZ, OnValueUpdate3 );
				if (_simulation4 != null)
					_simulation4.SetValue( value, OnValueUpdate4 );
			}
			
			protected override void OnLostData( IExpression source )
			{
				CleanSimulation();
				if (_target != null)
					_target.OnLostData(_attract);
			}
			
			void NeedSim(int size)
			{
				if (size != _simSize)
				{
					CleanSimulation();
					_simSize = size;
				}
				
				if (size < 0 || size > 4)
				{
					Fuse.Diagnostics.InternalError( "Unexpected size for attract: " + size, this );
					return;
				}
					
				if (size == 1 && _simulation1 == null)
				{
					_simulation1 = new DestinationBehavior<float>();
					_simulation1.Motion = _attract._config;
				}
				else if (size == 2 && _simulation2 == null)
				{
					_simulation2 =new DestinationBehavior<float2>();
					_simulation2.Motion = _attract._config;
				}
				else if (size == 3 && _simulation3 == null)
				{
					_simulation3 =new DestinationBehavior<float3>();
					_simulation3.Motion = _attract._config;
				}
				else if (size == 4 && _simulation4 == null)
				{
					_simulation4 =new DestinationBehavior<float4>();
					_simulation4.Motion = _attract._config;
				}
			}
			
			void CleanSimulation()
			{
				if (_simulation4 != null)
				{
					_simulation4.Unroot();
					_simulation4 = null;
				}
				if (_simulation3 != null)
				{
					_simulation3.Unroot();
					_simulation3 = null;
				}
				if (_simulation2 != null)
				{
					_simulation2.Unroot();
					_simulation2 = null;
				}
				if (_simulation1 != null)
				{
					_simulation1.Unroot();
					_simulation1 = null;
				}
			}
			
			public override void Dispose()
			{
				base.Dispose();
				if (_sourceSub != null)
				{
					_sourceSub.Dispose();
					_sourceSub = null;
				}
				_target = null;
				_attract = null;
				CleanSimulation();
			}
		}
	}
}