using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;

namespace Fuse.Profiling
{
	public delegate void ExecuteCommand(IProfiler profiler, object[] param);
	public delegate object ReadFunction(BinaryReader stream);

	public class Command
	{
		readonly ExecuteCommand _executeCommand;
		readonly ReadFunction[] _readFunctions;
		readonly object[] _paramCache;

		public Command(
			ExecuteCommand executeCommand,
			ReadFunction[] readCallbacks)
		{
			_executeCommand = executeCommand;
			_readFunctions = readCallbacks;
			_paramCache = new object[_readFunctions.Length];
		}

		public void Execute(IProfiler profiler, BinaryReader stream)
		{
			for (int i = 0; i < _readFunctions.Length; i++)
				_paramCache[i] = _readFunctions[i](stream);

			_executeCommand(profiler, _paramCache);
		}

	}

	public static class CommandTranslator
	{
		public static Command[] CreateCommands()
		{
			return typeof(IProfiler).GetMethods().Select(CreateCommand).ToArray();
		}

		static Command CreateCommand(MethodInfo method)
		{
			var m = method;
			var readFunctions = m.GetParameters().Select(ResolveParameter).ToArray();
			return new Command((x, y) => m.Invoke(x, y), readFunctions);
		}

		static ReadFunction ResolveParameter(ParameterInfo parameter)
		{
			var type = parameter.ParameterType;

			if (type == typeof(byte)) return x => x.ReadByte();
			if (type == typeof(sbyte)) return x => x.ReadSByte();
			if (type == typeof(short)) return x => x.ReadInt16();
			if (type == typeof(ushort)) return x => x.ReadUInt16();
			if (type == typeof(int)) return x => x.ReadInt32();
			if (type == typeof(uint)) return x => x.ReadUInt32();
			if (type == typeof(long)) return x => x.ReadInt64();
			if (type == typeof(ulong)) return x => x.ReadUInt64();
			if (type == typeof(bool)) return x => x.ReadBoolean();
			if (type == typeof(float)) return x => x.ReadSingle();
			if (type == typeof(double)) return x => x.ReadDouble();
			if (type == typeof(string))
				return x =>
				{
					var length = x.ReadInt32();
					var bytes = x.ReadBytes(length);
					return Encoding.UTF8.GetString(bytes);
				};
			throw new Exception("Unsupported datatype: " + type);
		}
	}
}
