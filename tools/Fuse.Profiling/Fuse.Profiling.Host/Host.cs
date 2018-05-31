using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net.Sockets;
using System.IO;

namespace Fuse.Profiling
{
	
	public class Host
	{

		readonly TcpListener _tcpListener;

		public Host()
		{
			_tcpListener = new TcpListener(1337);
			_tcpListener.Start();
		}

		public ProfileClient AcceptProfileClient(IProfiler profiler)
		{
			var commands = CommandTranslator.CreateCommands();

			return new ProfileClient(_tcpListener.AcceptTcpClient(), profiler, commands);
		}

	}

	public interface IProfiler
	{
		void Error();
		void BeginDrawNode(byte stringId);
		void EndDrawNodeByte(byte duration);
        void EndDrawNodeInt(int duration);
		void BeginDraw(int frameIndex);
		void EndDrawByte(byte duration);
        void EndDrawInt(int duration);
		void LogEventByte(byte duration, byte stringId);
		void LogEventInt(int duration, byte stringId);
		void NewFramebufferByte(byte duration, int x, int y);
		void NewFramebufferInt(int duration, int x, int y);
		void CacheString(byte id, string str);
	}

	public class ProfileClient
	{
		readonly TcpClient _tcpClient;
		readonly IProfiler _profiler;
		readonly Command[] _commands;

		public ProfileClient(TcpClient tcpClient, IProfiler profiler, Command[] commands)
		{
			_tcpClient = tcpClient;
			_profiler = profiler;
			_commands = commands;
			
			Task.Run(() => ReadLoop());
		}

		void ReadLoop()
		{
			try
			{
				using (var binaryReader = new BinaryReader(_tcpClient.GetStream()))
				{
					while (_tcpClient.Connected)
					{
						var command = binaryReader.ReadByte();

						if (command >= _commands.Length)
							throw new Exception("Illegal command");

						_commands[command].Execute(_profiler, binaryReader);
					}
				}
			}
			catch(EndOfStreamException eos)
			{

			}
			catch (Exception e)
			{
		
			}
		}
	}
}
