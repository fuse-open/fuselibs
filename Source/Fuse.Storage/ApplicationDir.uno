using Uno;
using Uno.IO;
using Uno.Threading;

namespace Fuse.Storage
{
	internal static class ApplicationDir
	{
		public static bool Write(string filename, string value)
		{
			if (filename == null)
				throw new ArgumentNullException(nameof(filename));

			if (value == null)
				throw new ArgumentNullException(nameof(value));

			var filepath = Path.Combine(Directory.GetUserDirectory(UserDirectory.Data), filename);
			CreateFile(filepath);
			File.WriteAllText(filepath, value);

			return true;
		}
		
		static void CreateFile(string filepath)
		{
			using(var stream = File.Open(filepath, FileMode.Create))
			{}
		}

		public static bool TryRead(string filename, out string content)
		{
			if (filename == null)
				throw new ArgumentNullException(nameof(filename));

			var filepath = Path.Combine(Directory.GetUserDirectory(UserDirectory.Data), filename);
			if (!File.Exists(filepath))
			{
				content = string.Empty;
				return false;
			}

			content = File.ReadAllText(filepath);
			return true;
		}

		public static string Read(string filename)
		{
			string content;
			if (TryRead(filename, out content))
				return content;
			else
				throw new Exception("File does not exist.");
		}

		public static bool Delete(string filename)
		{
			if (filename == null)
				throw new ArgumentNullException(nameof(filename));
			
			var filepath = Path.Combine(Directory.GetUserDirectory(UserDirectory.Data), filename);
			if(!File.Exists(filepath)) return false;
		
			try
			{
				File.Delete(filepath);
				return true;
			} catch(Exception e) {}
			return false;
		}

		public static Future<bool> WriteAsync(string filename, string value)
		{
			return Promise<bool>.Run(new WriteClosure(filename, value).Invoke);
		}

		public static Future<bool> WriteAsync(IDispatcher dispatcher, string filename, string value)
		{
			return Promise<bool>.Run(dispatcher, new WriteClosure(filename, value).Invoke);
		}

		public static Future<string> ReadAsync(string filename)
		{
			return Promise<string>.Run(new ReadClosure(filename).Invoke);
		}

		public static Future<string> ReadAsync(IDispatcher dispatcher, string filename)
		{
			return Promise<string>.Run(dispatcher, new ReadClosure(filename).Invoke);
		}

		class WriteClosure
		{
			readonly string _filename;
			readonly string _value;

			public WriteClosure(string filename, string value)
			{
				_filename = filename;
				_value = value;
			}

			public bool Invoke()
			{
				return ApplicationDir.Write(_filename, _value);
			}
		}

		class ReadClosure
		{
			readonly string _filename;

			public ReadClosure(string filename)
			{
				_filename = filename;
			}

			public string Invoke()
			{
				return ApplicationDir.Read(_filename);
			}
		}

	}
}
