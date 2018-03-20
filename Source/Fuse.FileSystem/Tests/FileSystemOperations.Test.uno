using Uno;
using Uno.IO;
using Uno.Collections;
using Uno.Testing;
using Uno.Threading;
using Uno.Text;
using FuseTest;

namespace Fuse.FileSystem.Test
{
	public class FileSystemTest : TestBase
	{
		FileSystemOperations _operations = new FileSystemOperations();


		[Test]
		public void AppendTextToFile_when_file_does_not_exist_creates_file()
		{
			var tempFile = GetNonExistingFileName();
			try
			{
				var content = "trololol";
				WaitForSuccessAndGetValue(_operations.AppendTextToFile(tempFile, content));
				Assert.IsTrue(File.Exists(tempFile), "No file seems to be written");
				Assert.AreEqual(File.ReadAllText(tempFile), content);
			}
			finally
			{
				File.Delete(tempFile);
			}
		}


		[Test]
		public void AppendTextToFile_when_file_exist_appends_to_file()
		{
			var tempFile = WriteSampleFile();
			try
			{
				var appended = " tralala";
				WaitForSuccessAndGetValue(_operations.AppendTextToFile(tempFile, appended));
				Assert.IsTrue(File.Exists(tempFile), "No file seems to be written");
				Assert.AreEqual(File.ReadAllText(tempFile), "trololol" + appended);
			}
			finally
			{
				File.Delete(tempFile);
			}
		}


		[Test]
		public void AppendTextToFileSync_when_file_does_not_exist_creates_file()
		{
			var tempFile = GetNonExistingFileName();
			try
			{
				var content = "trololol";
				_operations.AppendTextToFileSync(tempFile, content);
				Assert.IsTrue(File.Exists(tempFile), "No file seems to be written");
				Assert.AreEqual(File.ReadAllText(tempFile), content);
			}
			finally
			{
				File.Delete(tempFile);
			}
		}


		[Test]
		public void AppendTextToFileSync_when_file_exist_appends_to_file()
		{
			var tempFile = WriteSampleFile();
			try
			{
				var appended = " tralala";
				_operations.AppendTextToFileSync(tempFile, appended);
				Assert.IsTrue(File.Exists(tempFile), "No file seems to be written");
				Assert.AreEqual(File.ReadAllText(tempFile), "trololol" + appended);
			}
			finally
			{
				File.Delete(tempFile);
			}
		}


		[Test]
		public void CreateDirectory_creates_directory()
		{
			var dirName = GetNonExistingFileName();
			try
			{
				WaitForSuccessAndGetValue(_operations.CreateDirectory(dirName));
				Assert.IsTrue(Directory.Exists(dirName));
			}
			finally
			{
				Directory.Delete(dirName, true);
			}
		}


		[Test]
		public void CreateDirectory_does_not_throw_exception_when_directory_already_exists()
		{
			var dirName = GetNonExistingFileName();
			try
			{
				Directory.CreateDirectory(dirName);
				Assert.IsTrue(Directory.Exists(dirName));
				WaitForSuccessAndGetValue(_operations.CreateDirectory(dirName));
				Assert.IsTrue(Directory.Exists(dirName));
			}
			finally
			{
				Directory.Delete(dirName, true);
			}
		}


		[Test]
		public void CreateDirectorySync_creates_directory()
		{
			var dirName = GetNonExistingFileName();
			try
			{
				_operations.CreateDirectorySync(dirName);
				Assert.IsTrue(Directory.Exists(dirName));
			}
			finally
			{
				Directory.Delete(dirName, true);
			}
		}


		[Test]
		public void Delete_when_file_exists_deletes_file()
		{
			var tempFilePath = WriteSampleFile();
			WaitForSuccessAndGetValue(_operations.Delete(tempFilePath, false));
			Assert.IsFalse(File.Exists(tempFilePath));
		}


		[Test]
		public void Delete_can_delete_empty_directory()
		{
			var dirName = GetNonExistingFileName();
			try
			{
				Directory.CreateDirectory(dirName);
				Assert.IsTrue(Directory.Exists(dirName));
				WaitForSuccessAndGetValue(_operations.Delete(dirName, false));
				Assert.IsFalse(Directory.Exists(dirName));
			}
			finally
			{
				if (Directory.Exists(dirName))
					Directory.Delete(dirName, true);
			}
		}


		[Test]
		public void DeleteSync_when_file_exists_deletes_file()
		{
			var tempFilePath = WriteSampleFile();
			_operations.DeleteSync(tempFilePath, false);
			Assert.IsFalse(File.Exists(tempFilePath));
		}


		[Test]
		public void Exists_when_file_exists_returns_true()
		{
			var tempFile = WriteSampleFile();
			Assert.IsTrue(WaitForSuccessAndGetValue(_operations.Exists(tempFile)));
		}


		[Test]
		public void Exists_when_directory_exists_returns_true()
		{
			var dirName = GetNonExistingFileName();
			try
			{
				Directory.CreateDirectory(dirName);
				Assert.IsTrue(WaitForSuccessAndGetValue(_operations.Exists(dirName)));
			}
			finally
			{
				Directory.Delete(dirName, true);
			}
		}


		[Test]
		public void Exists_when_special_file_exists_returns_true()
		{
			var windowsNamedPipeExists = WaitForSuccessAndGetValue(_operations.Exists("\\\\.\\pipe\\lsass"));
			var unixNullExists = WaitForSuccessAndGetValue(_operations.Exists("/dev/null"));
			Assert.IsTrue(windowsNamedPipeExists || unixNullExists);
		}


		[Test]
		public void ExistsSync_when_directory_exists_returns_true()
		{
			var dirName = GetNonExistingFileName();
			try
			{
				Directory.CreateDirectory(dirName);
				Assert.IsTrue(_operations.ExistsSync(dirName));
			}
			finally
			{
				Directory.Delete(dirName, true);
			}
		}


		[Test]
		public void Exists_when_file_does_not_exist_returns_false()
		{
			var tempFile = GetNonExistingFileName();
			Assert.IsFalse(WaitForSuccessAndGetValue(_operations.Exists(tempFile)));
		}


		[Test]
		public void ExistsSync_when_file_exists_returns_true()
		{
			var tempFile = WriteSampleFile();
			Assert.IsTrue(_operations.ExistsSync(tempFile));
		}


		[Test]
		public void ExistsSync_when_file_does_not_exist_returns_false()
		{
			var tempFile = GetNonExistingFileName();
			Assert.IsFalse(_operations.ExistsSync(tempFile));
		}


		[Test]
		public void ListDirectories_lists_subdirectories_in_directory()
		{
			string dirName = null;
			try
			{
				dirName = CreateTempDirWithFileAndDirectory();
				var files = WaitForSuccessAndGetValue(_operations.ListDirectories(dirName));
				Assert.AreEqual(files.Length, 1);
				Assert.AreEqual(files[0], Path.Combine(dirName, "thesubdir").Replace("\\", "/"));
			}
			finally
			{
				if (dirName != null)
					Directory.Delete(dirName, true);
			}
		}


		[Test]
		public void ListEntries_lists_all_entries_in_directory()
		{
			string dirName = null;
			try
			{
				dirName = CreateTempDirWithFileAndDirectory();
				var files = WaitForSuccessAndGetValue(_operations.ListEntries(dirName)).AsEnumerable().ToList();
				Assert.AreEqual(files.Count, 2);
				Assert.IsTrue(files.Contains(Path.Combine(dirName, "thefile").Replace("\\", "/")));
				Assert.IsTrue(files.Contains(Path.Combine(dirName, "thesubdir").Replace("\\", "/")));
			}
			finally
			{
				if (dirName != null)
					Directory.Delete(dirName, true);
			}
		}


		[Test]
		public void ListFiles_lists_files_in_directory()
		{
			string dirName = null;
			try
			{
				dirName = CreateTempDirWithFileAndDirectory();
				var files = WaitForSuccessAndGetValue(_operations.ListFiles(dirName));
				Assert.AreEqual(files.Length, 1);
				Assert.AreEqual(files[0], Path.Combine(dirName, "thefile").Replace("\\", "/"));
			}
			finally
			{
				if (dirName != null)
					Directory.Delete(dirName, true);
			}
		}


		[Test]
		public void Move_file_is_successful()
		{
			var source = WriteSampleFile();
			var destination = source + ".moved";
			try
			{
				WaitForSuccessAndGetValue(_operations.Move(source, destination));
				Assert.IsFalse(File.Exists(source));
				Assert.IsTrue(File.Exists(destination));
			}
			finally
			{
				try
				{
					File.Delete(destination);
					File.Delete(source);
				}
				catch
				{ }
			}
		}


		[Test]
		public void ReadBufferFromFile_when_file_exists_is_successful()
		{
			var tempFile = WriteSampleFile();
			var content = WaitForSuccessAndGetValue(_operations.ReadBufferFromFile(tempFile));
			Assert.AreCollectionsEqual((IEnumerable<byte>)content,
									   (IEnumerable<byte>)Utf8.GetBytes("trololol"));
		}


		[Test]
		public void ReadBufferFromFileSync_when_file_exists_is_successful()
		{
			var tempFile = WriteSampleFile();
			var content = _operations.ReadBufferFromFileSync(tempFile);
			Assert.AreCollectionsEqual((IEnumerable<byte>)content,
									   (IEnumerable<byte>)Utf8.GetBytes("trololol"));
		}


		[Test]
		public void ReadTextFromFile_when_file_exists_is_successful()
		{
			var tempFile = WriteSampleFile();
			var content = WaitForSuccessAndGetValue(_operations.ReadTextFromFile(tempFile));
			Assert.AreEqual(content, "trololol");
		}


		[Test]
		public void ReadTextFromFileSync_when_file_exists_is_successful()
		{
			var tempFile = WriteSampleFile();
			var content = _operations.ReadTextFromFileSync(tempFile);
			Assert.AreEqual(content, "trololol");
		}


		[Test]
		public void WriteBufferToFile_when_file_does_not_exist_is_successful()
		{
			var tempFile = GetNonExistingFileName();
			try
			{
				var content = "trololol";
				WaitForSuccessAndGetValue(_operations.WriteBufferToFile(tempFile, Utf8.GetBytes(content)));
				Assert.IsTrue(File.Exists(tempFile), "No file seems to be written");
				Assert.AreEqual(File.ReadAllText(tempFile), content);
			}
			finally
			{
				File.Delete(tempFile);
			}
		}


		[Test]
		public void WriteBufferToFileSync_when_file_does_not_exist_is_successful()
		{
			var tempFile = GetNonExistingFileName();
			try
			{
				var content = "trololol";
				_operations.WriteBufferToFileSync(tempFile, Utf8.GetBytes(content));
				Assert.IsTrue(File.Exists(tempFile), "No file seems to be written");
				Assert.AreEqual(File.ReadAllText(tempFile), content);
			}
			finally
			{
				File.Delete(tempFile);
			}
		}


		[Test]
		public void WriteTextToFile_when_file_does_not_exist_is_successful()
		{
			var tempFile = GetNonExistingFileName();
			try
			{
				var content = "trololol";
				WaitForSuccessAndGetValue(_operations.WriteTextToFile(tempFile, content));
				Assert.IsTrue(File.Exists(tempFile), "No file seems to be written");
				Assert.AreEqual(File.ReadAllText(tempFile), content);
			}
			finally
			{
				File.Delete(tempFile);
			}
		}


		[Test]
		public void WriteTextToFileSync_when_file_does_not_exist_is_successful()
		{
			var tempFile = GetNonExistingFileName();
			try
			{
				var content = "trololol";
				_operations.WriteTextToFileSync(tempFile, content);
				Assert.IsTrue(File.Exists(tempFile), "No file seems to be written");
				Assert.AreEqual(File.ReadAllText(tempFile), content);
			}
			finally
			{
				File.Delete(tempFile);
			}
		}


		private T WaitForSuccessAndGetValue<T>(Future<T> future)
		{
			future.Wait();
			var resultBox = new Box<T>();
			var exceptionBox = new Box<Exception>();
			future.Then(resultBox.Deliver, exceptionBox.Deliver);
			Assert.AreEqual(exceptionBox.Value, null, "Threw exception from future: " + exceptionBox.Value);
			if (!(typeof(T) == typeof(Nothing)))
				Assert.AreNotEqual(resultBox.Value, null);
			return resultBox.Value;
		}


		private static string GetNonExistingFileName()
		{
			var rng = new Random(123456);
			string path = null;
			do {
				path = Path.Combine(Directory.GetUserDirectory(UserDirectory.Data), "testfile-" + rng.Next());
			} while (File.Exists(path));

			return path;
		}


		private string CreateTempDirWithFileAndDirectory()
		{
			var dirName = GetNonExistingFileName();
			Directory.CreateDirectory(dirName);
			var fileName = Path.Combine(dirName, "thefile");
			File.WriteAllText(fileName, "lol");
			var subdirName = Path.Combine(dirName, "thesubdir");
			Directory.CreateDirectory(subdirName);
			return dirName;
		}


		private string WriteSampleFile()
		{
			var dataDirectory = Directory.GetUserDirectory(UserDirectory.Data);
			var tempFile = Path.Combine(dataDirectory, "nanana.txt");
			File.WriteAllText(tempFile, "trololol");
			return tempFile;
		}


		// Simple wrapper to get value from Future
		private class Box<T>
		{
			T _value;

			public T Value { get { return _value; } }

			public void Deliver(T value)
			{
				_value  = value;
			}
		}
	}
}
