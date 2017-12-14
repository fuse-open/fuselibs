using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	[UXUnaryOperator("DataToResource")]
	/**
		Binds to a resource with the key provided in a context variable. This allows selecting resources from @JavaScript by key name.
		
		In this example three different fonts are created as resources. The font is selected by name in the exported JavaScript items.
		
			<Font File="../../Assets/fonts/Roboto-Bold.ttf" ux:Key="Bold"/>
			<Font File="../../Assets/fonts/Roboto-Regular.ttf" ux:Key="Regular"/>
			<Font File="../../Assets/fonts/Roboto-Italic.ttf" ux:Key="Italic"/>
			
			<JavaScript>
				exports.items = [
					{ font: "Bold" },
					{ font: "Regular" },
					{ font: "Italic" },
				]
			</JavaScript>
			<StackPanel>
				<Each Items="{items}">
					<Text Value="Sample Text" Font="{DataToResource font}"/>
				</Each>
			</StackPanel>
		
		`{DataToResource variableKey}` is similar to `{Resource key}`, except it allows a variable key name instead of a static one.
		
		@see Fuse.Resources.ResourceBinding
	*/
	public class DataToResource: Expression
	{
		Expression _data;
		[UXConstructor]
		public DataToResource([UXParameter("Data")] Expression data)
		{
			_data = data;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			var dtr = new DataToResourceSubscription(this, context, listener);
			dtr.Init(context);
			return dtr;
		}

		class DataToResourceSubscription: ExpressionListener
		{
			Node _node;
			public DataToResourceSubscription(DataToResource dtr, IContext context, IListener listener): 
				base(dtr, listener, new Expression[]{ dtr._data }, Flags.None)
			{
				_node = context.Node;
			}

			public override void Dispose()
			{
				base.Dispose();
				_node = null;
				Unsubscribe();
			}

			string _key;

			protected override void OnArguments(Argument[] args)
			{
				Unsubscribe();
				_key = args[0].Value as string;
				Subscribe();
				OnChanged();
			}

			void Subscribe()
			{
				if (_key != null)
					Fuse.Resources.ResourceRegistry.AddResourceChangedHandler(_key, OnChanged);
			}

			void Unsubscribe()
			{
				if (_key != null)
					Fuse.Resources.ResourceRegistry.RemoveResourceChangedHandler(_key, OnChanged);
			}

			void OnChanged()
			{
				object v = null;
				if (_key != null && _node != null && _node.TryGetResource(_key, null, out v))
					SetData(v);
				else
					ClearData();
			}
		}
	}
}