using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.IO;
using Uno.Net;
using Uno.Net.Sockets;
using Uno.Text;
using Uno.Threading;
using Fuse;

namespace Fuse.Scripting.V8
{
	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) class Debugger: IDisposable
	{
		readonly int _port;
		[WeakReference]
		readonly Context _context;
		List<string> _offlineMessages;
		Socket _listenSocket;
		object _shutdownMutex = new object();
		/* volatile */ bool _shutdown;
		Action<string> _messageHandler;
		Thread _stateMachine;
		State _currentState;


		public Debugger(Context context, int port)
		{
			_context = context;
			_port = port;
			_offlineMessages = new List<string>();
			_messageHandler = DisconnectedMessageHandler;
			V8SimpleExtensions.SetDebugMessageHandler(_context._context, HandleMessage);
			_stateMachine = new Thread(StateMachine);
			if defined(DotNet)
			{
				_stateMachine.IsBackground = true;
			}
			_currentState = Connect(this);
			_stateMachine.Start();
		}

		void StateMachine()
		{
			while (true)
			{
				lock (_shutdownMutex)
				{
					if (_shutdown)
						break;
				}

				_currentState = _currentState.Run();
			}
			_currentState.Dispose();
		}

		void HandleMessage(Simple.JSString message)
		{
			if (_messageHandler != null)
			{
				_messageHandler(message.ToStr(_context._context));
			}
		}

		public void Dispose()
		{
			V8SimpleExtensions.SetDebugMessageHandler(_context._context, null);
			_messageHandler = null;

			lock (_shutdownMutex)
				_shutdown = true;

			_stateMachine.Join();
		}

		interface State
		{
			State Run();
			void Dispose();
		}

		static State Connect(Debugger parent)
		{
			parent._messageHandler = parent.DisconnectedMessageHandler;
			debug_log "DEBUG_V8: Waiting for a debugger agent to connect on port " + parent._port + "...";
			return new Connecting(parent);
		}

		void DisconnectedMessageHandler(string message)
		{
			_offlineMessages.Add(AddHeader(message));
		}

		static string AddHeader(string body)
		{
			var header = _contentLengthString + Utf8.GetBytes(body).Length + "\r\n\r\n";
			// Problem: The Visual Studio Code debugger fails if we
			// give it a thread ID that is not 1, but V8 sometimes
			// gives thread ID 2 (and possibly others as well?)
			// e.g.  when JS is running on the UI thread, which it
			// started doing recently. (See
			// https://github.com/fusetools/FuseJS/issues/118)
			//
			// Solution: Parse the message to JSON, replace the
			// thread ID, and write it out to a string again.
			//
			// Problem: We have a JSON reader, but no writer.
			//
			// Solution: Alright, let's replace the string the ugly
			// way with a regex.
			//
			// Problem: We have no regex library.
			//
			// Solution:
			var replacedBody = body;
			for (int i = 2; i <= 8; ++i)
			{
				replacedBody = replacedBody.Replace(
					"\"threads\":[{\"current\":true,\"id\":" + i + "}]",
					"\"threads\":[{\"current\":true,\"id\":1}]");
			}
			// Problem: The above is obviously very brittle and
			// should make you queazy (even though 8 thread IDs
			// ought to be enough for anyone).
			//
			// There currently is no solution.
			return header + replacedBody;
		}

		class Connecting: State
		{
			readonly Debugger _parent;
			Socket _listenSocket;

			public Connecting(Debugger parent)
			{
				_parent = parent;
			}

			public State Run()
			{
				try
				{
					if (_listenSocket == null)
					{
						_listenSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
						var endPoint = new IPEndPoint(IPAddress.Any, _parent._port);
						_listenSocket.Bind(endPoint);
						_listenSocket.Listen(1);
					}

					if (!_listenSocket.Poll(100, SelectMode.Read))
						return this;

					var communicationSocket = _listenSocket.Accept();
					Dispose();
					return ToConnected(_parent, communicationSocket);
				}
				catch (Exception e)
				{
					Dispose();
					Thread.Sleep(500);
					return this;
				}
			}

			public void Dispose()
			{
				if (_listenSocket != null)
				{
					try // Since we can't check if we're actually connected
					{
						_listenSocket.Shutdown(SocketShutdown.Both);
					}
					catch (Exception e) { }
					_listenSocket.Close();
					_listenSocket = null;
				}
			}
		}

		static State ToConnected(Debugger parent, Socket communicationSocket)
		{
			var stream = new NetworkStream(communicationSocket);
			var reader = new StreamReader(stream);
			var writer = new StreamWriter(stream);

			var state = new Connected(parent, communicationSocket, reader);

			parent._messageHandler
				= new ConnectedMessageHandler(state, writer).MessageHandler;

			writer.Write("Type: connect\r\nV8-Version: " +
				Simple.Context.GetV8Version() +
				"\r\nProtocol-Version: 1\r\nEmbedding-Host: " +
				@(PACKAGE) + " " + @(PACKAGE_VERSION) +
				"\r\nContent-Length: 0\r\n\r\n");

			foreach (var message in parent._offlineMessages)
			{
				writer.Write(message);
			}
			parent._offlineMessages = new List<string>();
			writer.Flush();

			return state;
		}

		class ConnectedMessageHandler
		{
			Connected _state;
			TextWriter _writer;

			public ConnectedMessageHandler(Connected state, TextWriter writer)
			{
				_state = state;
				_writer = writer;
			}

			public void MessageHandler(string message)
			{
				try
				{
					_writer.Write(AddHeader(message));
					_writer.Flush();
				}
				catch (Exception e)
				{
					_state.Reconnect();
				}
			}
		}

		static readonly string _contentLengthString = "Content-Length: ";
		class Connected: State
		{
			readonly Debugger _parent;
			readonly TextReader _reader;
			readonly Socket _socket;
			bool _reconnect;

			public Connected(Debugger parent, Socket socket, TextReader reader)
			{
				debug_log "DEBUG_V8: Connection to a debugger agent established.";
				_parent = parent;
				_socket = socket;
				_reader = reader;
			}

			bool ReadExactly(char[] buffer, int start, int count)
			{
				if (count == 0)
				{
					return true;
				}

				int read = 0;

				do
				{
					read = _reader.Read(buffer, start, count);
					start += read;
					count -= read;
				} while (read > 0 && count > 0);

				return count == 0;
			}

			public State Run()
			{
				if (_reconnect)
				{
					Dispose();
					Thread.Sleep(500);
					return Connect(_parent);
				}
				try
				{
					if (!_socket.Poll(100, SelectMode.Read))
						return this;

					var line = _reader.ReadLine();
					var i = line == null ? -1 : line.IndexOf(_contentLengthString);
					if (i >= 0)
					{
						int contentLength = int.Parse(
							line.Substring(i + _contentLengthString.Length));
						if (contentLength > 0)
						{
							_reader.ReadLine();
							var buffer = new char[contentLength];
							if (!ReadExactly(buffer, 0, contentLength))
							{
								throw new Exception("Debugger could not read enough");
							}
							var message = new String(buffer);
							var cxt = _parent._context._context;
							Simple.Debug.SendCommand(cxt, message, message.Length);
							_parent._context.ThreadWorker.Invoke(ProcessMessages);
						}
					}
					else
					{
						if (string.IsNullOrEmpty(line))
						{
							Reconnect();
						}
						else
						{
							Thread.Sleep(10);
						}
					}
				}
				catch (Exception e)
				{
					Reconnect();
				}
				return this;
			}

			void ProcessMessages(Scripting.Context context)
			{
				var sContext = ((Context)context)._context;
				Simple.Debug.ProcessMessages(sContext);
			}

			public void Reconnect()
			{
				_reconnect = true;
			}

			public void Dispose()
			{
				_reader.Dispose();
				try // Since we can't check if we're actually connected
				{
					_socket.Shutdown(SocketShutdown.Both);
				}
				catch (Exception e) { }
				_socket.Close();
			}
		}
	}
}
