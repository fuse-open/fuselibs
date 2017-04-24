using Uno;
using Uno.IO;
using Uno.Threading;
using Uno.Collections;

namespace Fuse.FileSystem
{
	internal class FileSystemOperations
	{
		private IDispatcher _dispatcher;


		public FileSystemOperations() : this(null) { }


		public FileSystemOperations(IDispatcher dispatcher)
		{
			_dispatcher = dispatcher;
		}


		public Future<Nothing> AppendTextToFile(string path, string text)
		{
			return RunTask<string, string, Nothing>(AppendTextToFileSync, path, text);
		}


		public Nothing AppendTextToFileSync(string path, string text)
		{
			File.AppendAllText(path, text);
			return default(Nothing);
		}


		public Future<Nothing> CreateDirectory(string path)
		{
			return RunTask<string, Nothing>(CreateDirectorySync, path);
		}


		public Nothing CreateDirectorySync(string path)
		{
			Directory.CreateDirectory(path);
			return default(Nothing);
		}


		public Future<Nothing> Delete(string path, bool recursive)
		{
			return RunTask<string, bool, Nothing>(DeleteSync, path, recursive);
		}


		public Nothing DeleteSync(string path, bool recursive)
		{
			if (Directory.Exists(path))
				Directory.Delete(path, recursive);
			else
				File.Delete(path);

			return default(Nothing);
		}


		public Future<bool> Exists(string path)
		{
			return RunTask<string, bool>(ExistsSync, path);
		}


		public bool ExistsSync(string path)
		{
			// File.Exists also returns true special files like named pipes etc in .NET (mono and MS implementation)
			// and also in uBase::Disk->IsFile. This makes the following work for all file system entries:
			return File.Exists(path) || Directory.Exists(path);
		}


		public Future<FileSystemInfo> GetDirectoryInfo(string path)
		{
			return RunTask<string, FileSystemInfo>(GetDirectoryInfoSync, path);
		}


		public FileSystemInfo GetDirectoryInfoSync(string path)
		{
			return new DirectoryInfo(path);
		}


		public Future<FileSystemInfo> GetFileInfo(string path)
		{
			return RunTask<string, FileSystemInfo>(GetFileInfoSync, path);
		}


		public FileSystemInfo GetFileInfoSync(string path)
		{
			return new FileInfo(path);
		}


		public Future<string[]> ListDirectories(string path)
		{
			return RunTask<string, string[]>(ListDirectoriesSync, path);
		}


		public string[] ListDirectoriesSync(string path)
		{
			return Directory.EnumerateDirectories(path).Select<string, string>(PathTools.NormalizePath).ToArray();
		}


		public Future<string[]> ListEntries(string path)
		{
			return RunTask<string, string[]>(ListEntriesSync, path);
		}


		public string[] ListEntriesSync(string path)
		{
			return Directory.EnumerateFileSystemEntries(path).Select<string, string>(PathTools.NormalizePath).ToArray();
		}


		public Future<string[]> ListFiles(string path)
		{
			return RunTask<string, string[]>(ListFilesSync, path);
		}


		public string[] ListFilesSync(string path)
		{
			return Directory.EnumerateFiles(path).Select<string, string>(PathTools.NormalizePath).ToArray();
		}


		public Future<Nothing> Move(string source, string destination)
		{
			return RunTask<string, string, Nothing>(MoveSync, source, destination);
		}


		public Nothing MoveSync(string source, string destination)
		{
			if (Directory.Exists(source))
				Directory.Move(source, destination);
			else
				File.Move(source, destination);
			return default(Nothing);
		}


		public Future<Nothing> Copy(string source, string destination)
		{
			return RunTask<string, string, Nothing>(CopySync, source, destination);
		}


		public Nothing CopySync(string source, string destination)
		{
			if (Directory.Exists(source))
				CopyDirectory(source, destination);
			else
				File.Copy(source, destination);
			return default(Nothing);
		}

		private void CopyDirectory(string source, string destination)
		{
			if (!Directory.Exists(destination))
				Directory.CreateDirectory(destination);

			// Get the files in the directory and copy them to the new location.
			string[] files = ListEntriesSync(source);
			foreach (string file in files)
			{
				if (Directory.Exists(file)){
					CopyDirectory(file, destination);
					continue;
				}

				string temppath = file.Replace(source, destination);
				File.Copy(file, temppath);
			}
		}


		public Future<byte[]> ReadBufferFromFile(string path)
		{
			return RunTask<string, byte[]>(ReadBufferFromFileSync, path);
		}


		public byte[] ReadBufferFromFileSync(string path)
		{
			// Do we have support for tasklike IO completion or is using a thread just fine?
			return File.ReadAllBytes(path);
		}


		public Future<string> ReadTextFromFile(string path)
		{
			return RunTask<string, string>(ReadTextFromFileSync, path);
		}


		public string ReadTextFromFileSync(string path)
		{
			// Do we have support for tasklike IO completion or is using a thread just fine?
			return File.ReadAllText(path);
		}


		public Future<Nothing> WriteBufferToFile(string path, byte[] data)
		{
			return RunTask<string, byte[], Nothing>(WriteBufferToFileSync, path, data);
		}


		public Nothing WriteBufferToFileSync(string path, byte[] data)
		{
			File.WriteAllBytes(path, data);
			return default(Nothing);
		}


		public Future<Nothing> WriteTextToFile(string path, string text)
		{
			return RunTask<string, string, Nothing>(WriteTextToFileSync, path, text);
		}


		public Nothing WriteTextToFileSync(string path, string text)
		{
			File.WriteAllText(path, text);
			return default(Nothing);
		}


		private Future<T> RunTask<T>(Func<T> del)
		{
			if (_dispatcher == null)
				return Promise<T>.Run(del);
			return Promise<T>.Run(_dispatcher, del);
		}


		private Future<TResult> RunTask<T1, TResult>(Func<T1, TResult> del, T1 arg1)
		{
			return RunTask<TResult>(new Closure<T1, TResult>(del, arg1).Invoke);
		}


		private Future<TResult> RunTask<T1, T2, TResult>(Func<T1, T2, TResult> del, T1 arg1, T2 arg2)
		{
			return RunTask<TResult>(new Closure<T1, T2, TResult>(del, arg1, arg2).Invoke);
		}


		private class Closure<T1, TResult>
		{
			readonly Func<T1, TResult> _del;
			readonly T1 _arg1;

			public Closure(Func<T1, TResult> del, T1 arg1)
			{
				_del = del;
				_arg1 = arg1;
			}

			public TResult Invoke()
			{
				return _del(_arg1);
			}
		}


		private class Closure<T1, T2, TResult>
		{
			readonly Func<T1, T2, TResult> _del;
			readonly T1 _arg1;
			readonly T2 _arg2;

			public Closure(Func<T1, T2, TResult> del, T1 arg1, T2 arg2)
			{
				_del = del;
				_arg1 = arg1;
				_arg2 = arg2;
			}

			public TResult Invoke()
			{
				return _del(_arg1, _arg2);
			}
		}
	}
}
