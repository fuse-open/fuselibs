using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	class EventRecord : IEventRecord, IEventSerializer
	{
		readonly Node _node;
		readonly object _data;
		readonly Selector _sender;
		Dictionary<string, object> _args;

		internal EventRecord(IScriptEvent args, object sender)
		{
			//data must be captured node since the node could be unrooted/changed prior to `Call`
			//https://github.com/fusetools/fuselibs-private/issues/1995
			_node = sender as Node;

			if (_node != null)
			{
				_node.TryGetPrimeDataContext( out _data ); //okay as null if not found
				if (_node.Name != null) _sender = _node.Name;
			}

			if (args != null) args.Serialize(this);
		}

		public Node Node { get { return _node; } }
		public object Data { get { return _data; } }
		public Selector Sender { get { return _sender; } }
		public IEnumerable<KeyValuePair<string, object>> Args { get { return _args; } }
		
		void AddObject(string key, object value)
		{
			if (_args == null) _args = new Dictionary<string, object>();
			_args.Add(key, value);
		}

		void IEventSerializer.AddObject(string key, object value)
		{
			AddObject(key, value);
		}

		void IEventSerializer.AddString(string key, string value)
		{
			AddObject(key, value);
		}

		void IEventSerializer.AddInt(string key, int value)
		{
			AddObject(key, (double)value);
		}

		void IEventSerializer.AddDouble(string key, double value)
		{
			AddObject(key, value);
		}

		void IEventSerializer.AddBool(string key, bool value)
		{
			AddObject(key, value);
		}
	}
}