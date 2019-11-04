using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;

using Fuse.Scripting;

namespace Fuse
{
	public partial class Visual
	{
		string _parameter;

		/** The parameter data for this visual, encoded as JSON, provided by a router if this visual represents a navigation page.

			When this value is set, the parameter can be accessed in JavaScript through the `.Parameter` property on this object.

			Example:

				<JavaScript>
					router.goto("profile", { id: 3 });
				</JavaScript>
				...
				<Page ux:Name="profile">
					<JavaScript>
						profile.Parameter.onValueChanged(module, function(param) {
							// param holds the deserialized object { id: 3 }
						});
					</JavaScript>
				</Page>
		*/
		public string Parameter
		{
			get { return _parameter; }
			set
			{
				if (_parameter != value)
				{
					_parameter = value;
					OnParameterChanged();
				}
			}
		}
		
		static PropertyHandle _parameterChangedHandle = Fuse.Properties.CreateHandle();

		/** Raised when the `Parameter` property changes.
			@advanced */
		public event EventHandler ParameterChanged
		{
			add { AddEventHandler(_parameterChangedHandle, VisualBits.ParameterChanged, value); }
			remove { RemoveEventHandler(_parameterChangedHandle, VisualBits.ParameterChanged, value); }
		}
		

		List<Function> _parameterListeners;

		void AddParameterChangedListener(Function func)
		{
			if (_parameterListeners == null)
				_parameterListeners = new List<Function>();

			_parameterListeners.Add(func);

			if (_parameter != null)
			{
				var so = this as IScriptObject;
				if (so != null)
					func.Call(so.ScriptContext, so.ScriptContext.ParseJson(_parameter));
			}
		}

		internal static Selector ParameterName = "Parameter";

		void OnParameterChanged()
		{
			if (_parameterListeners != null)
			{
				var so = this as IScriptObject;
				if (so != null)
				{
					var param = so.ScriptContext.ParseJson(_parameter);
					for (int i = 0; i < _parameterListeners.Count; i++)
						_parameterListeners[i].Call(so.ScriptContext, param);
				}
			}
			OnPropertyChanged(ParameterName);
			RaiseEvent(_parameterChangedHandle, VisualBits.ParameterChanged);
		}

		void ResetParameterListeners()
		{
			_parameterListeners = null;
		}
		
		/**
			Prepares a visual with a new parameter. This is meant to indicate a high-level transition, such as navigation to a new page.
			
			Overrides are expected to call `base.Prepare` or perform the same behaviour. Callers will expect the parmaeter to be taken as-is.
		*/
		internal virtual void Prepare(string parameter)
		{
			Parameter = parameter;
		}
	}
}
