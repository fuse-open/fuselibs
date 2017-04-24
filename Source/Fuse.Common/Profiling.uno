using Uno;
using Uno.Text;
using Uno.Collections;
using Uno.Net;
using Uno.Net.Sockets;


namespace Fuse
{
	extern(FUSELIBS_PROFILING) public interface IProfileClient
	{
		void Write(Buffer data, int count);
	}

	extern(FUSELIBS_PROFILING) public class ProfileClient : Fuse.IProfileClient
	{
		readonly Socket _socket;

		public ProfileClient(string host, int port)
		{
			try
			{
				_socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
				_socket.Connect(host, port);
			}
			catch (Exception e)
			{
				_socket = null;
				throw;
			}
		}

		public void Write(Buffer buffer, int count)
		{
			if (_socket != null)
			{
				var buf = new byte[count];
				for (int i = 0; i < count; i++)
				{
					buf[i] = buffer[i];
				}
				_socket.Send(buf);
			}
		}

	}

	extern(FUSELIBS_PROFILING) class BufferEntry
	{
		public readonly Buffer Buf;
		public readonly int Count;

		public BufferEntry(Buffer buf, int count)
		{
			Buf = buf;
			Count = count;
		}
	}

	extern(FUSELIBS_PROFILING) public enum Command
	{
		ERROR,
		BeginRegion,
		EndRegionByte,
		EndRegionInt,
		BeginUpdate,
		EndUpdateByte,
		EndUpdateInt,
		LogEventByte,
		LogEventInt,
		NewFramebufferByte,
		NewFramebufferInt,
		CacheString,
	}

	extern(FUSELIBS_PROFILING) class CommandBuffer
	{
		readonly Buffer _buffer;
		readonly int _size;
		int _offset;

		public int Offset { get { return _offset; } }
		public int Size { get { return _size; } }

		public CommandBuffer(int sizeInBytes)
		{
			_buffer = new Buffer(sizeInBytes);
			_size = sizeInBytes;
			_offset = 0;
		}

		public Buffer GetBuffer() { return _buffer; }

		public void Write(Command c) { Write(((byte)c)); }
		public void Write(byte b) { _buffer.Set(_offset, b); _offset += sizeof(byte); }
		public void Write(short s) { _buffer.Set(_offset, s); _offset += sizeof(short); }
		public void Write(int i) { _buffer.Set(_offset, i); _offset += sizeof(int); }
		public void Write(long l) { _buffer.Set(_offset, l); _offset += sizeof(long); }
		public void Write(float f) { _buffer.Set(_offset, f); _offset += sizeof(float); }
		public void Write(double d) { _buffer.Set(_offset, d); _offset += sizeof(double); }
		public void Write(byte[] b) { for (int i = 0; i < b.Length; i++) Write(b[i]); }

	}

	extern(FUSELIBS_PROFILING) class StringCache
	{
		class Cache
		{
			public string Value { get; private set; }
			public double LastTimeUsed { get; private set; }
			public int StringHash { get; private set; }
			public double IdleTime
			{
				get { return Uno.Diagnostics.Clock.GetSeconds() - LastTimeUsed; }
			}

			public Cache(string s)
			{
				Value = s;
				StringHash = s.GetHashCode();
				UpdateLastTimeUsed();
			}
			public override int GetHashCode()
			{
				return Value.GetHashCode();
			}
			public void UpdateLastTimeUsed()
			{
				LastTimeUsed = Uno.Diagnostics.Clock.GetSeconds();
			}
		}

		readonly Cache[] _cache = new Cache[0xff];

		public bool IsStringCached(string s)
		{
			var hash = s.GetHashCode();
			for (byte b = (byte)(_cache.Length - 1); b != 0x00; b--)
			{
				var c = _cache[b];
				if (c != null && c.StringHash == hash)
					return true;
			}
			return false;
		}

		public byte CacheString(string s)
		{
			var stringHash = s.GetHashCode();
			short leastUsedIndex = -1;
			short availableIndex = -1;
			var maxIdle = 0.0;
			for (byte b = 0; b < _cache.Length; b++)
			{
				var c = _cache[b];
				if (c == null)
				{
					availableIndex = b;
				}
				else if (c.StringHash == stringHash)
				{
					c.UpdateLastTimeUsed();
					return b;
				}
				else
				{
					var idleTime = c.IdleTime;
					if (maxIdle < idleTime)
					{
						maxIdle = idleTime;
						leastUsedIndex = b;
					}
				}
			}

			if (availableIndex != -1)
			{
				_cache[availableIndex] = new Cache(s);
				return (byte)availableIndex;
			}
			else if (leastUsedIndex != -1)
			{
				_cache[leastUsedIndex] = new Cache(s);
				return (byte)leastUsedIndex;
			}

			throw new Exception("String cache error, leastUsedIndex=" + leastUsedIndex + ", availableIndex=" + availableIndex);
		}

	}

	extern(FUSELIBS_PROFILING) public static class Profiling
	{
		public static IProfileClient ProfileClient { get; set; }

		static readonly double _startTime;

		static double CurrentTime
		{
			get { return Uno.Diagnostics.Clock.GetSeconds() - _startTime; }
		}

		static Profiling()
		{
			_startTime = Uno.Diagnostics.Clock.GetSeconds();
		}

		static CommandBuffer _commandBuffer = new CommandBuffer(512);
		static CommandBuffer CommandBuffer
		{
			get { return _commandBuffer; }
			set
			{
				if (_commandBuffer != null && ProfileClient != null)
				{
					ProfileClient.Write(_commandBuffer.GetBuffer(), _commandBuffer.Offset);
				}

				_commandBuffer = value;
			}
		}

		static StringCache _stringCache = new StringCache();

		static void CheckBuffer(int requiredSize)
		{
			var newSize = CommandBuffer.Offset + requiredSize;
			if (newSize > CommandBuffer.Size)
				CommandBuffer = new CommandBuffer(Math.Max(requiredSize, 512));
		}

		public static void LogEvent(string log, double duration)
		{
			if (ProfileClient == null)
				return;

			var id = CacheString(log);

			var ms100 = (int)(duration * 100000.0);

			if (ms100 < 255.0)
			{
				Write(Command.LogEventByte);
				Write((byte)ms100);
			}
			else
			{
				Write(Command.LogEventInt);
				Write(ms100);
			}

			Write(id);
		}

		public static void NewFramebuffer(framebuffer fb, double duration)
		{
			if (ProfileClient == null)
				return;

			var ms100 = (int)(duration * 100000.0);

			if (ms100 < 255.0)
			{
				Write(Command.NewFramebufferByte);
				Write((byte)(ms100));
			}
			else
			{
				Write(Command.NewFramebufferInt);
				Write(ms100);
			}

			Write(fb.Size.X);
			Write(fb.Size.Y);
		}

		static double _beginUpdateTime;

		public static void BeginUpdate()
		{
			if (ProfileClient == null)
				return;

			_beginUpdateTime = Uno.Diagnostics.Clock.GetSeconds();

			Write(Command.BeginUpdate);
			Write(Fuse.UpdateManager.FrameIndex);

			BeginRegion("Update");
		}

		public static void EndUpdate()
		{
			if (ProfileClient == null)
				return;

			var duration = Uno.Diagnostics.Clock.GetSeconds() - _beginUpdateTime;
			EndRegion(duration);

			var ms100 = (int)(duration * 100000.0);

			if (ms100 < 255.0)
			{
				Write(Command.EndUpdateByte);
				Write((byte)ms100);
			}
			else
			{
				Write(Command.EndUpdateInt);
				Write(ms100);
			}

		}

		public static void BeginDraw()
		{
			if defined(!MOBILE)
				BeginUpdate();
		}

		public static void EndDraw()
		{
			if defined(!MOBILE)
				EndUpdate();
		}

		public static void BeginRegion(string str)
		{
			if (ProfileClient == null)
				return;

			var id = CacheString(str);
			Write(Command.BeginRegion);
			Write(id);
		}

		private static byte CacheString(string str)
		{
			var isCached = _stringCache.IsStringCached(str);
			var id = _stringCache.CacheString(str);

			if (isCached)
				return id;

			debug_log("Caching string to remote: " + str);

			Write(Command.CacheString);
			Write(id);
			Write(str);

			return id;
		}

		public static void EndRegion(double duration)
		{
			if (ProfileClient == null)
				return;

			var ms100 = (int)(duration * 100000.0);

			if (ms100 < 255.0)
			{
				Write(Command.EndRegionByte);
				Write((byte)(ms100));
			}
			else
			{
				Write(Command.EndRegionInt);
				Write(ms100);
			}
		}

		static void Write(Command command)
		{
			CheckBuffer(GetSize(command));
			CommandBuffer.Write(command);
		}

		static void Write(byte b)
		{
			CheckBuffer(GetSize(b));
			CommandBuffer.Write(b);
		}

		static void Write(byte[] data)
		{
			CheckBuffer(data.Length);
			CommandBuffer.Write(data);
		}

		static void Write(short s)
		{
			CheckBuffer(GetSize(s));
			CommandBuffer.Write(s);
		}

		static void Write(int i)
		{
			CheckBuffer(GetSize(i));
			CommandBuffer.Write(i);
		}

		static void Write(long l)
		{
			CheckBuffer(GetSize(l));
			CommandBuffer.Write(l);
		}

		static void Write(float f)
		{
			CheckBuffer(GetSize(f));
			CommandBuffer.Write(f);
		}

		static void Write(double d)
		{
			CheckBuffer(GetSize(d));
			CommandBuffer.Write(d);
		}

		static void Write(string str)
		{
			var bytes = Uno.Text.Utf8.GetBytes(str);
			var length = bytes.Length;
			Write(length);
			Write(bytes);
		}

		static int GetSize(Command c) { return sizeof(byte); }
		static int GetSize(byte b) { return sizeof(byte); }
		static int GetSize(short s) { return sizeof(short); }
		static int GetSize(int i) { return sizeof(int); }
		static int GetSize(long l) { return sizeof(long); }
		static int GetSize(float f) { return sizeof(float); }
		static int GetSize(double d) { return sizeof(double); }
	}
}
