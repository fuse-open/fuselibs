using Uno;
using Uno.UX;
using Uno.Net.Http;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Reactive.FuseJS
{
	[UXGlobalModule]
	/**@hide
	*/
	public class Http : NativeModule
	{
		static readonly Http _instance;
		public Http()
		{
			if (_instance != null) return;
			Uno.UX.Resource.SetGlobalKey(_instance = this, "FuseJS/Http");
		}

		public override void Evaluate(Context c, ModuleResult result)
		{
			result.Object["exports"] = new FunctionClosure(c, CreateClient).Callback;
		}

		object CreateClient(Context context, object[] args)
		{
			return new FuseJSHttpClient(context).Obj;
		}
		
		class FunctionClosure
		{
			Context _context;
			Func<Context, object[], object> _callback;

			public FunctionClosure(Context context, Func<Context, object[], object> callback)
			{
				_context = context;
				_callback = callback;
			}

			object function(object[] args)
			{
				return _callback(_context, args);
			}

			public Callback Callback
			{
				get { return (Callback)this.function; }
			}
		}

		class FuseJSHttpClient
		{
			public Scripting.Object Obj { get; private set; }

			HttpMessageHandler _client;
			Context _context;

			public FuseJSHttpClient(Context context)
			{
				_context = context;
				_client = new HttpMessageHandler();

				Obj = context.NewObject();
				Obj["createRequest"] = (Callback)CreateRequest;
			}

			object CreateRequest(object[] args)
			{
				var method = args[0] as string;
				var url = args[1] as string;

				return new FuseJSHttpRequest(_context, _client.CreateRequest(method, url, _context.Dispatcher)).Obj;
			}
		}

		class FuseJSHttpRequest
		{
			public Scripting.Object Obj { get; private set; }

			HttpMessageHandlerRequest _req;

			string _cachedResponseHeaders;
			object _cachedResponseContent;
			int _cachedResponseStatus;
			HttpResponseType _cachedResponseType;
			HttpRequestState _finalState;


			public FuseJSHttpRequest(Context context, HttpMessageHandlerRequest req)
			{
				_req = req;
				Obj = context.NewObject();

				_req.Aborted += OnAbort;
				_req.Error += OnError;
				_req.Timeout += OnTimeout;
				_req.Done += OnDone;
				_req.StateChanged += OnStateChanged;
				_req.Progress += OnProgress;

				Obj["enableCache"] = (Callback)EnableCache;
				Obj["setTimeout"] = JSCallback.FromAction<int>(SetTimeout);
				Obj["setResponseType"] = (Callback)SetResponseType;
				Obj["getResponseType"] = (Callback)GetResponseType;
				Obj["sendAsync"] = (Callback)SendAsync;
				Obj["abort"] = JSCallback.FromAction(Abort);
				Obj["setHeader"] = JSCallback.FromAction<string, string>(SetHeader);
				Obj["getResponseHeader"] = JSCallback.FromFunc<string, string>(GetResponseHeader);
				Obj["getResponseHeaders"] = JSCallback.FromFunc<string>(GetResponseHeaders);

				Obj["getState"] = (Callback)GetState;
				Obj["getResponseStatus"] = JSCallback.FromFunc<int>(GetResponseStatus);
				Obj["getResponseReasonPhrase"] = (Callback)GetResponseReasonPhrase;
				Obj["getResponseContentString"] = (Callback)GetResponseContentString;
				Obj["getResponseContentByteArray"] = (Callback)GetResponseContentByteArray;
			}

			void DetachRequest()
			{
				_finalState = _req.State;
				_cachedResponseType = _req.HttpResponseType;

				if (_finalState == HttpRequestState.Done)
				{
					GetResponseHeaders();
					GetResponseStatus();
					switch (_req.HttpResponseType)
					{
						case HttpResponseType.ByteArray:
							GetResponseContentByteArray(null);
							break;
						case HttpResponseType.String:
							GetResponseContentString(null);
							break;
					}
				}

				_req.Aborted -= OnAbort;
				_req.Error -= OnError;
				_req.Timeout -= OnTimeout;
				_req.Done -= OnDone;
				_req.StateChanged -= OnStateChanged;
				_req.Progress -= OnProgress;

				_req.Dispose();
				_req = null;

				// Also break the cycle through JS
				Obj = null;
			}

			void Abort()
			{
				if (_req == null)
					return;
				if ((int)_req.State < (int)HttpRequestState.Done)
				{
					try
					{
						_req.Abort();
					}
					catch {}
				}
			}

			void SetHeader(string key, string value)
			{
				CheckIsAttached();
				_req.SetHeader(key, value);
			}

			void SetTimeout(int timeout)
			{
				CheckIsAttached();
				_req.SetTimeout(timeout);
			}

			void CheckIsAttached()
			{
				if (_req == null)
					throw new InvalidOperationException("This operation is illegal after request has finished");
			}

			string GetResponseHeaders()
			{
				if (_cachedResponseHeaders == null)
				{
					CheckIsAttached();
					_cachedResponseHeaders = _req.GetResponseHeaders();
				}
				return _cachedResponseHeaders;
			}

			string GetResponseHeader(string key)
			{
				// NOTE: In theory there can be multiple headers having the same key,
				// the signature of this method don't cover that
				if (_req != null)
				{
					return _req.GetResponseHeader(key);
				}
				// Find first response header from headers
				if (_cachedResponseHeaders == null)
					throw new InvalidOperationException("Unable to get header.");

				return new HttpHeaders(_cachedResponseHeaders).GetValue(key);
			}

			string GetResponseContentString(object[] args)
			{
				if (_cachedResponseContent == null)
				{
					CheckIsAttached();
					_cachedResponseContent = _req.GetResponseContentString();
				}

				var contentAsString = _cachedResponseContent as string;
				if (contentAsString == null)
					throw new InvalidResponseTypeException();

				return contentAsString;
			}

			object GetResponseContentByteArray(object[] args)
			{
				if (_cachedResponseContent == null)
				{
					CheckIsAttached();
					_cachedResponseContent = _req.GetResponseContentByteArray();
				}

				var contentAsBytes = _cachedResponseContent as byte[];
				if (contentAsBytes == null)
					throw new InvalidResponseTypeException();

				return contentAsBytes;
			}

			void OnAbort(HttpMessageHandlerRequest res)
			{
				var func = Obj["onabort"] as Function;
				if (func != null)
					func.Call();
				DetachRequest();
			}

			void OnError(HttpMessageHandlerRequest res, string error)
			{
				var func = Obj["onerror"] as Function;
				if (func != null)
					func.Call(error);
				DetachRequest();
			}

			void OnTimeout(HttpMessageHandlerRequest res)
			{
				var func = Obj["ontimeout"] as Function;
				if (func != null)
					func.Call();
				DetachRequest();
			}

			void OnStateChanged(HttpMessageHandlerRequest res)
			{
				var func = Obj["onstatechanged"] as Function;
				if (func != null)
					func.Call((int)_req.State);
			}

			void OnDone(HttpMessageHandlerRequest res)
			{
				var func = Obj["ondone"] as Function;
				if (func != null)
					func.Call();
				DetachRequest();
			}

			void OnProgress(HttpMessageHandlerRequest res, int current, int total, bool hastotal)
			{
				var func = Obj["onprogress"] as Function;
				if (func != null)
					func.Call(current, total, hastotal);
			}

			object SendAsync(object[] args)
			{
				if (args != null && args.Length > 0)
				{
					var a = args[0];

					if (a is string)
					{
						_req.SendAsync(a as string);
						return null;
					}
					else if (a is byte[])
					{
						var b = a as byte[];
						_req.SendAsync(b);
						return null;
					}
					else
					{
						var obj = a as Scripting.Object;
						if (obj != null && obj["buffer"] != null)
						{
							var b = obj["buffer"] as byte[];
							_req.SendAsync(b);
							return null;
						}
					}
				}
				_req.SendAsync();

				return null;
			}

			object EnableCache(object[] args)
			{
				if (args.Length > 0)
				{
					if defined(!DesignMode) // NOTE: Hack to disable cache for mono. They don't have support for it :(
					{
						_req.EnableCache((bool)args[0]);
					}
				}
				return null;
			}

			object GetState(object[] args)
			{
				return (_req != null) ? (int)_req.State : _finalState;
			}

			int GetResponseStatus()
			{
				if (_cachedResponseStatus == 0)
				{
					CheckIsAttached();
					_cachedResponseStatus = _req.GetResponseStatus();
				}
				return _cachedResponseStatus;
			}

			object GetResponseReasonPhrase(object[] args)
			{
				return HttpStatusReasonPhrase.GetFromStatusCode(GetResponseStatus());
			}

			object SetResponseType(object[] args)
			{
				CheckIsAttached();

				if (args.Length > 0)
				{
					var arg = args[0];
					var value = arg is int ? (int)arg : (int)(double)arg;
					_req.SetResponseType((HttpResponseType)value);
				}
				return null;
			}

			object GetResponseType(object[] args)
			{
				if (_req == null)
				{
					return (int)_cachedResponseType;
				}
				return (int)_req.HttpResponseType;
			}
		}
	}

	internal class HttpHeaders
	{
		readonly Dictionary<string, IList<string>> _headers = new Dictionary<string, IList<string>>();

		internal HttpHeaders(string headers)
		{
			using (var reader = new Uno.IO.StringReader(headers))
			{
				var headerLine = reader.ReadLine();
				while (headerLine != null)
				{
					ParseHeader(headerLine);
					headerLine = reader.ReadLine();
				}
			}
		}

		public string GetValue(string key)
		{
			IList<string> list;
			if (_headers.TryGetValue(key.ToLower(), out list))
			{
				return string.Join(", ", list.ToArray());
			}
			return "";
		}

		void ParseHeader(string headerLine)
		{
			if (string.IsNullOrEmpty(headerLine)) return;

			var colon = headerLine.IndexOf(':');
			if (colon == -1) return;

			var name = headerLine.Substring(0, colon).Trim().ToLower();

			// https://tools.ietf.org/html/rfc7230#section-3.2.4
			var strings = headerLine.Substring(colon + 1, headerLine.Length - (colon + 1)).Trim().Split(';');
			var values = new List<string>();
			foreach (var s in strings)
			{
				values.Add(s.Trim());
			}

			if (_headers.ContainsKey(name))
			{
				foreach (var value in values)
					_headers[name].Add(value);
			}
			else
				_headers.Add(name, values);
		}
	}
}
