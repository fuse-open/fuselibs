using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Returns the parameter of the given page (visual), parsed from a JSON string.

		Usage:

			<Text Value="parameter(this).title" />

		The parameter can be ommited
	*/
	[UXFunction("parameter")]
	public sealed class Parameter: Expression
	{
		Expression Visual;
		
		[UXConstructor]
		public Parameter([UXParameter("Operand")] Fuse.Reactive.Expression visual)
		{
			Visual = visual;
		}
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new Subscription(this, context, listener);
		}

		class Subscription: InnerListener
		{
			Parameter _parameter;
			IListener _listener;
			IDisposable _sub;
			
			public Subscription(Parameter parameter, IContext context, IListener listener)
			{
				_parameter = parameter;
				_listener = listener;
				_sub = _parameter.Visual.Subscribe(context, this);
			}

			public override void Dispose()
			{
				UnsubscribeVisual();
				_listener = null;
				if (_sub != null)
				{
					_sub.Dispose();
					_sub = null;
				}
				base.Dispose();
			}

			void UnsubscribeVisual()
			{
				if (_visual != null)
				{
					_visual.ParameterChanged -= OnParameterChanged;
					_visual = null;
				}
			}

			Visual _visual;

			protected override void OnNewData(IExpression source, object obj)
			{
				ClearDiagnostic();

				UnsubscribeVisual();
				
				try
				{
					_visual = (Visual)obj;
					_visual.ParameterChanged += OnParameterChanged;
				}
				catch (Exception e)
				{
					SetDiagnostic("Failed to fetch parameter: " + e.Message, _parameter);
					return;
				}

				OnParameterChanged(null, null);
			}
			
			protected override void OnLostData(IExpression source)
			{
				ClearDiagnostic();
				UnsubscribeVisual();
				_listener.OnLostData(_parameter);
			}

			void OnParameterChanged(object sender, EventArgs args)
			{
				if (_visual == null) return;
				if (_visual.Parameter == null) return;

				ClearDiagnostic();

				object data = null;
				try
				{
					data = Json.Parse(_visual.Parameter);
				}
				catch (Exception e)
				{
					SetDiagnostic("Failed to parse parameter: " + e.Message, _parameter);
					return;
				}

				_listener.OnNewData(_parameter,data);
			}
		}
	}
}