using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Scripting;

namespace Fuse
{
	public partial class Visual
	{
		static Visual()
		{
			ScriptClass.Register(typeof(Visual), 
				new ScriptProperty<Visual, string>("Parameter", getParameterProperty, ".notNull().parseJson()"),
				new ScriptMethod<Visual>("onParameterChanged", onParameterChanged),
				new ScriptMethod<Visual>("bringIntoView", bringIntoView));
		}

		class ParameterProperty: Property<string>
		{
			readonly Visual _visual;
			public override PropertyObject Object { get { return _visual; } }
			public override bool SupportsOriginSetter { get { return false; } }
			public override string Get(PropertyObject obj) { return _visual.Parameter; } 
			public override void Set(PropertyObject obj, string value, IPropertyListener origin) { _visual.Parameter = value; }
			static Selector _name = "Parameter";
			public ParameterProperty(Visual visual): base(_name) { _visual = visual; }
		}

		ParameterProperty _parameterProperty;
		static Property<string> getParameterProperty(Visual v)
		{
			if (v._parameterProperty == null) v._parameterProperty = new ParameterProperty(v);
			return v._parameterProperty;
		}
		
		/**
			Requests that this visual be brought into the visible are of the screen. Typically a containing
			`ScrollView` will scroll to ensure it is visible.
			
			@scriptmethod bringIntoView()
		*/
		static void bringIntoView(Visual n)
		{
			n.BringIntoView();
		}

		/**
			Registers a function to be called whenever the routing parameter is changed. 

			This is typically used in conjunction with the @Router type that allows parameters to be
			specified in the @Router.goto and @Router.push operations.

			## Example
			
			This method is deprecated - use the following pattern instead:
			
				<Panel ux:Name="channelView">
					<JavaScript>
						channelView.Parameter.onValueChanged(module, function(param) {
							// lookup channel with id "param"
						})
					</JavaScript>

			@scriptmethod onParameterChanged( callback )
			@param callback The script method to call when the parameter changes. This is guaranted to be
				called at least once at registration time; you don't need to lookup the parameter another way.
		*/
		static void onParameterChanged(Visual v, object[] args)
		{
			var functionMirror = args[0] as Fuse.Scripting.IFunctionMirror;
			if (functionMirror != null)
				v.AddParameterChangedListener(functionMirror.Function);
		}
	}
}
