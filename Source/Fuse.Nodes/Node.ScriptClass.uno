using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Scripting;

namespace Fuse
{
	public partial class Node
	{
		static Node()
		{
			ScriptClass.Register(typeof(Node),
				new ScriptMethod<Node>("_createWatcher", _createWatcher, ExecutionThread.JavaScript),
				new ScriptMethod<Node>("_destroyWatcher", _destroyWatcher, ExecutionThread.JavaScript),
				new ScriptMethodInline("findData", ExecutionThread.JavaScript, "function(key) { return Observable._getDataObserver(this, key); }"));
		}

		static object _createWatcher(Context c, Node n, object[] args)
		{
			var key = (string)args[0];
			var callback = (Scripting.Function)args[1];
			return new External(new DataWatcher(n, c, callback, key));			
		}

		static void _destroyWatcher(Context c, Node n, object[] args)
		{
			if (args[0] != null)
			{
				var watcher = (DataWatcher)((External)args[0]).Object;
				watcher.Dispose();
			}
		}

		class DataWatcher: Node.DataFinder, IDataListener
		{
			Node _node;
			Scripting.Context _context;
			Scripting.Function _updateCallback;

			public DataWatcher(Node node, Scripting.Context context, Scripting.Function updateCallback, string key): base(key)
			{
				_node = node;
				_context = context;
				_updateCallback = updateCallback;

				UpdateManager.PostAction(Subscribe);
			}

			void Subscribe()
			{
				_node.EnumerateData(this);
				_node.AddDataListener(Key, this);
			}

			void Unsubscribe()
			{
				_node.RemoveDataListener(Key, this);
			}

			void IDataListener.OnDataChanged()
			{
				_node.EnumerateData(this);
			}

			public void Dispose()
			{
				UpdateManager.PostAction(Unsubscribe);
			}

			object _data;
			protected override void Resolve(IObject provider, object data)
			{
				_data = data;
				_context.Dispatcher.Invoke(Update);
			}

			void Update()
			{
				_updateCallback.Call(_context.Unwrap(_data));
			}
		}
	}
}
