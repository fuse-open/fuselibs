using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	/**
		Binds to the prime context data of this node.
		
		Behaviors like @With, @Each, and @Instance introduce a prime data context for their children.  @JavaScript and the `Model` tag do not introduce a prime data context.
		
		Use `data()` when you wish to bind directly to the prime data context. This is for when your data contains a simple value rather than a data structure.
		
			<JavaScript>
				exports.items = Observable(1,2,3)
			</JavaScript>
			<Each Items="{items}">
				<Text Value="{= data() }"/>
			</Each>
	*/
	[UXFunction("data")]
	public class DataFunction : Expression
	{
		[UXConstructor]
		public DataFunction()
		{
		}
		
		public override string ToString()
		{
			return "data()";
		}
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			var sub = new Subscription(this, listener, context.Node);
			sub.Init();
			return sub;
		}
		
		class Subscription : IDisposable, Node.IDataListener
		{
			DataFunction _expr;
			IListener _listener;
			Node _node;
			
			Node.NodeDataSubscription _dataSub;
			
			public Subscription(DataFunction expr, IListener listener, Node node)
			{
				_expr = expr;
				_listener = listener;
				_node = node;
			}
			
			public void Init()
			{
				_dataSub = _node.SubscribePrimeDataContext(this);
				UpdateData();
			}
			
			void Node.IDataListener.OnDataChanged()
			{
				UpdateData();
			}
			
			void UpdateData()
			{
				if (_dataSub == null)
					return;
					
				if (!_dataSub.HasData)
					_listener.OnLostData(_expr);
				else
					_listener.OnNewData(_expr, _dataSub.Data);
			}
			
			public void Dispose()
			{
				if (_dataSub != null)
				{
					_dataSub.Dispose();
					_dataSub = null;
				}
				_expr = null;
				_listener = null;
				_node = null;
			}
		}
	}
}
