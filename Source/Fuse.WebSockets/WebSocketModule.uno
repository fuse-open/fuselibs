using Fuse;
using Uno;
using Fuse.Scripting;
using Fuse.Reactive;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.WebSocket
{
	public abstract class NativeFunctionModule : NativeModule
	{
		static readonly NativeFunctionModule _instance;

		protected NativeFunctionModule(string name)
		{
			if (string.IsNullOrEmpty(name))
				throw new ArgumentNullException(name);

			if (_instance != null) return;
			Resource.SetGlobalKey(_instance = this, name);
		}

		public override void Evaluate(Context c, ModuleResult result)
		{
			result.GetObject(c)["exports"] = new FunctionClosure(c, Create).Callback;
		}

		protected abstract object Create(Context context, object[] args);

		class FunctionClosure
		{
			Context _context;
			Func<Context, object[], object> _callback;

			public FunctionClosure(Context context, Func<Context, object[], object> callback)
			{
				_context = context;
				_callback = callback;
			}

			object function(Context context, object[] args)
			{
				return _callback(_context, args);
			}

			public Callback Callback
			{
				get { return (Callback)this.function; }
			}
		}
	}

	[UXGlobalModule]
	public class WebSocketClientModule : NativeFunctionModule
	{
		public WebSocketClientModule() : base("FuseJS/WebSocketClient")
		{
			this.Reset += this.OnReset;
		}

		public void OnReset(object o, EventArgs e) {

		}

		protected override object Create(Context context, object[] args)
		{
			return new WebSocketClientWrapper(args).EvaluateExports(context, null);
		}
	}

	internal class WebSocketClientWrapper : NativeEventEmitterModule
	{
		WebSocketClient _client;

		public WebSocketClientWrapper(object[] args) : base(true, "open", "error", "close", "receive")
		{
			var uri = args.Length > 0 ? args[0] as string : null;

			if (uri == null)
				throw new Exception("Could not get uri to service");

			var protocols = new string[0];
			if (args.Length > 1) {
				object p = args[1];
				if (p is string)
				{
					protocols = new string [] { p as string };
				}
				else if (p is Scripting.Array)
				{
					var arr = p as Scripting.Array;
					protocols = new string[arr.Length];
					for(var i = 0; i < arr.Length; i++)
						protocols[i] = arr[i] as string;
				}
			}

			_client = new WebSocketClient(uri, protocols);
			_client.MessageReceived = MessageReceived;
			_client.DataReceived = DataReceived;
			_client.Opened = Opened;
			_client.ErrorReceived = ErrorReceived;
			_client.Closed = Closed;

			AddMember(new NativeFunction("connect", Connect));
			AddMember(new NativeFunction("send", Send));
			AddMember(new NativeFunction("close", Close));
		}

		object Connect(Context c, object[] args)
		{
			_client.Connect();
			return null;
		}

		object Send(Context c, object[] args)
		{
			if (args != null && args.Length > 0)
			{
				var a = args[0];

				if (a is string)
				{
					_client.Send(a as string);
				}
				else if (a is byte[])
				{
					var b = a as byte[];
					_client.Send(b);
				}
				else
				{
					var obj = a as Scripting.Object;
					if (obj != null && obj["buffer"] != null)
					{
						var b = obj["buffer"] as byte[];
						_client.Send(b);
					}
				}
			}
			return null;
		}

		object Close(Context c, object[] args)
		{
			_client.Close();
			return null;
		}

		void Opened()
		{
			Emit("open", "");
		}

		void ErrorReceived(string message)
		{
			Emit("error", message);
		}

		void Closed()
		{
			Emit("close", "");
		}

		void MessageReceived(string message)
		{
			Emit("receive", message);
		}

		void DataReceived(byte[] data)
		{
			Emit("receive", data);
		}
	}
}
