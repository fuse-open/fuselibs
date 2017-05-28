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
	public sealed class Parameter: UnaryOperator
	{
		[UXConstructor]
		public Parameter([UXParameter("Operand")] Fuse.Reactive.Expression visual): base(visual) {} 
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new ParameterSubscription(this, context, listener);
		}

		class ParameterSubscription: Subscription
		{
			Parameter _parameter;
			public ParameterSubscription(Parameter parameter, IContext context, IListener listener): base(parameter, listener)
			{
				_parameter = parameter;
				Init(context);
			}

			public override void Dispose()
			{
				UnsubscribeVisual();
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

			protected override void OnNewOperand(object obj)
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

				PushNewData(data);
			}
		}
	}
}