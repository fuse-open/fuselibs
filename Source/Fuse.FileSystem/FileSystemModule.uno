using Uno;
using Uno.IO;
using Uno.Time;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.FileSystem
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/FileSystem
		
		Provides an interface to the file system.

			var FileSystem = require("FuseJS/FileSystem");

		Using the asynchronous Promise based functions is recommended to keep your UI responsive,
		although synchronous variants are also available if preferred.

		When saving files private to the application you can use the `dataDirectory` property
		as a base path.

		## Example

		This example writes a text to a file, and then reads it back:

			var FileSystem = require("FuseJS/FileSystem");
			var path = FileSystem.dataDirectory + "/" + "testfile.tmp";

			FileSystem.writeTextToFile(path, "hello world")
				.then(function() {
					return FileSystem.readTextFromFile(path);
				})
				.then(function(text) {
					console.log("The read file content was: " + text);
				})
				.catch(function(error) {
					console.log("Unable to read file due to error:" + error);
				});
	*/
	public class FileSystemModule : NativeModule
	{
		static readonly FileSystemModule _instance;
		readonly FileSystemOperations _operations = new FileSystemOperations(); // TODO: Find out if we can use SyncDispatcher here

		public FileSystemModule()
		{
			if (_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/FileSystem");


			AddMember(new NativeProperty<string, string>("cacheDirectory", GetCacheDirectory));

			AddMember(new NativeProperty<string, string>("dataDirectory", GetDataDirectory));

			if defined(Android)
			{
				AddMember(new NativeProperty<Dictionary<string, string>, Scripting.Object>("androidPaths", GetAndroidPaths, null, ToScriptingObject));
			}
			if defined(iOS)
			{
				AddMember(new NativeProperty<Dictionary<string, string>, Scripting.Object>("iosPaths", GetIosPaths, null, ToScriptingObject));
			}

			AddMember(new NativePromise<Nothing, Scripting.Object>("createDirectory", CreateDirectory));
			AddMember(new NativeFunction("createDirectorySync", CreateDirectorySync));
			AddMember(new NativePromise<Nothing, Scripting.Object>("remove", Remove));
			AddMember(new NativeFunction("removeSync", RemoveSync));
			// Note: 'delete' is a reserved word in TypeScript, so the method was renamed to 'remove'.
			// The 'deleteSync' method was renamed to 'removeSync' to match.
			// Calling 'delete' and 'deleteSync' will still work to avoid breaking existing code.
			AddMember(new NativePromise<Nothing, Scripting.Object>("delete", Remove));
			AddMember(new NativeFunction("deleteSync", RemoveSync));
			AddMember(new NativePromise<bool, bool>("exists", Exists));
			AddMember(new NativeFunction("existsSync", ExistsSync));
			AddMember(new NativePromise<FileSystemInfo, Scripting.Object>("getDirectoryInfo", GetDirectoryInfo, ToScriptingObject));
			AddMember(new NativeFunction("getDirectoryInfoSync", GetDirectoryInfoSync));
			AddMember(new NativePromise<FileSystemInfo, Scripting.Object>("getFileInfo", GetFileInfo, ToScriptingObject));
			AddMember(new NativeFunction("getFileInfoSync", GetFileInfoSync));
			AddMember(new NativePromise<string[], Scripting.Array>("listDirectories", ListDirectories, ToScriptingArray));
			AddMember(new NativeFunction("listDirectoriesSync", ListDirectoriesSync));
			AddMember(new NativePromise<string[], Scripting.Array>("listEntries", ListEntries, ToScriptingArray));
			AddMember(new NativeFunction("listEntriesSync", ListEntriesSync));
			AddMember(new NativePromise<string[], Scripting.Array>("listFiles", ListFiles, ToScriptingArray));
			AddMember(new NativeFunction("listFilesSync", ListFilesSync));
			AddMember(new NativePromise<byte[], Scripting.Object>("readBufferFromFile", ReadBufferFromFile));
			AddMember(new NativeFunction("moveSync", MoveSync));
			AddMember(new NativePromise<Nothing, Scripting.Object>("move", Move));
			AddMember(new NativeFunction("copySync", CopySync));
			AddMember(new NativePromise<Nothing, Scripting.Object>("copy", Copy));
			AddMember(new NativeFunction("readBufferFromFileSync", ReadBufferFromFileSync));
			AddMember(new NativePromise<string, string>("readTextFromFile", ReadTextFromFile));
			AddMember(new NativeFunction("readTextFromFileSync", ReadTextFromFileSync));
			AddMember(new NativePromise<Nothing, Scripting.Object>("writeBufferToFile", WriteBufferToFile));
			AddMember(new NativeFunction("writeBufferToFileSync", WriteBufferToFileSync));
			AddMember(new NativePromise<Nothing, Scripting.Object>("writeTextToFile", WriteTextToFile));
			AddMember(new NativeFunction("writeTextToFileSync", WriteTextToFileSync));
			AddMember(new NativePromise<Nothing, Scripting.Object>("appendTextToFile", AppendTextToFile));
			AddMember(new NativeFunction("appendTextToFileSync", AppendTextToFileSync));
		}


		/**
			@scriptmethod appendTextToFile(filename)
			@param filename (String) Path to a file
			@param text (String) Text to append to file
			@return (Promise) A Promise of nothing.

			Asynchronously appends a string to a UTF-8 encoded file.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.appendTextToFile(FileSystem.dataDirectory + "/" + "myfile.txt", "Hello buddy")
					.then(function() {
						console.log("Successful append");
					}, function(error) {
						console.log(error);
					});
		*/
		Future<Nothing> AppendTextToFile(object[] args)
		{
			var path = GetPathFromArgs(args);
			var text = GetArg<string>(args, 1, "Second argument \"text\" is required to be a string");
			return _operations.AppendTextToFile(path, text);
		}


		/**
			@scriptmethod appendTextToFileSync(filename)
			@param filename (String) Path to a file
			@param text (String) Text to append to the file

			Synchronously appends a string to a UTF-8 encoded file.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.appendTextToFileSync("myfile.txt", "Hello buddy");
		*/
		object AppendTextToFileSync(Context context, object[] args)
		{
			var path = GetPathFromArgs(args);
			var text = GetArg<string>(args, 1, "Second argument \"text\" is required to be a string");
			_operations.AppendTextToFileSync(path, text);
			return null;
		}


		/**
			@scriptmethod createDirectory(path)
			@param path (String) Path of directory to be created.
			@return (Promise) A Promise of nothing

			Asynchronously creates a directory.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.createDirectory(FileSystem.dataDirectory + "/" + "new-directory")
					.then(function() {
						console.log("Directory created!");
					}, function(error) {
						console.log("Error trying to create directory.");
					});
		*/
		public Future<Nothing> CreateDirectory(object[] args)
		{
			return _operations.CreateDirectory(GetPathFromArgs(args));
		}


		/**
			@scriptmethod createDirectorySync(path)
			@param path (String) Path of the directory to be created.

			Synchronously creates a directory.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.createDirectory(FileSystem.dataDirectory + "/" + "new-directory");
		*/
		public object CreateDirectorySync(Context context, object[] args)
		{
			_operations.CreateDirectorySync(GetPathFromArgs(args));
			return null;
		}


		/**
			@scriptmethod remove(path)
			@param path (String) Path to a file or directory
			@param recursive (Boolean) Delete directory recursively (ignored for files)
			@return (Promise) A Promise of nothing

			Asynchronously delete a file.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.remove("myfile.txt")
					.then(function() {
						console.log("Delete succeeded");
					}, function(error) {
						console.log("Unable to delete file");
					});
		*/
		Future<Nothing> Remove(object[] args)
		{
			var recursive = (args.Length > 1 && args[1] is bool) ? (bool)args[1] : false;
			return _operations.Delete(GetPathFromArgs(args), recursive);
		}


		/**
			@scriptmethod removeSync(path)
			@param path (String) Path to a file or directory
			@param recursive (Boolean) Delete directory recursively (ignored for files)

			Synchronously delete a file.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.removeSync("myfile.txt");
		*/
		object RemoveSync(Context context, object[] args)
		{
			var recursive = (args.Length > 1 && args[1] is bool) ? (bool)args[1] : false;
			_operations.DeleteSync(GetPathFromArgs(args), recursive);
			return null; /* Should rather return undefined */
		}


		/**
			@scriptmethod exists(path)
			@param path (String) Path to a file or directory
			@return (Promise) A Promise that resolves to true if the file exists, false if not, and rejects if the file's existence could not be determined.

			Asynchronously check if a file exists.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.exists("myfile.txt")
					.then(function(x) {
						console.log(x ? "it's there! =)" : "it's missing :/");
					}, function(error) {
						console.log("Unable to check if file exists");
					});
		*/
		Future<bool> Exists(object[] args)
		{
			return _operations.Exists(GetPathFromArgs(args));
		}


		/**
			@scriptmethod existsSync(path)
			@param path (String) Path to a file or directory
			@return (Boolean) true if file exists, false if not

			Synchronously check if a file exists.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				console.log(FileSystem.existsSync("myfile.txt") ? "It's there!" : "It's missing :/");
		*/
		object ExistsSync(Context context, object[] args)
		{
			return _operations.ExistsSync(GetPathFromArgs(args));
		}


		/**
			@scriptproperty androidPaths

			An object containing paths only exposed on Android devices:

			* `externalCache` –  The directory acquired by calling `Context.getExternalCacheDir()`
			* `externalFiles` –  The directory acquired by calling `Context.getExternalFilesDir(null)`
			* `cache` –  The directory acquired by calling `Context.getCacheDir()`
			* `files` –  The directory acquired by calling `Context.getFilesDir()`
		*/
		Dictionary<string, string> GetAndroidPaths()
		{
			if defined(Android)
			{
				return AndroidPaths.GetPathDictionary();
			}
			else
			{
				throw new NotSupportedException("Android-specific paths are not supported on other platforms");
			}
		}


		/**
			@scriptproperty cacheDirectory

			A directory to put cached files.

			Note that files in this directory might be automatically removed when space is low, depending on platform.
		*/
		string GetCacheDirectory()
		{
			return UnifiedPaths.GetCacheDirectory();
		}


		/**
			@scriptproperty dataDirectory

			A directory to put data files that are private to the application.

			* iOS - The Library directory for the application.
			* Android - The directory acquired by calling `Context.getFilesDir()`
			* Local preview - `<project dir>/build/Local/Preview/fs_data`

			Note that cleaning or rebuilding your project will delete this directory.
		*/
		string GetDataDirectory()
		{
			return UnifiedPaths.GetDataDirectory();
		}


		/**
			@scriptmethod getDirectoryInfo(path)
			@param path (String) Path to a directory
			@return (Promise) A Promise of an object containing info about the directory.

			Asynchronously gets info about a directory.

			The returned object has the following properties:

			* `exists` –  a boolean value stating whether the directory exists or not.
			* `lastWriteTime` –  A `Date` stating when directory was last changed
			* `lastAccessTime` –  A `Date` stating when directory was accessed

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.createDirectorySync("some-dir");
				FileSystem.getDirectoryInfo("some-dir")
					.then(function(dirInfo) {
						console.log("Directory was modified on " + dirInfo.lastWriteTime);
					})
					.catch(function(error) {
						console.log("Failed to get directory info " + error);
					});
		*/
		Future<FileSystemInfo> GetDirectoryInfo(object[] args)
		{
			return _operations.GetDirectoryInfo(GetPathFromArgs(args));
		}


		/**
			@scriptmethod getDirectoryInfoSync(path)
			@param path (String) Path to a directory
			@return (Object) An object containing info about the directory.

			Synchronously gets info about a directory.

			The returned object has the following properties:

			* `exists` -  A boolean value stating whether the directory exists
			* `lastWriteTime` -  A `Date` stating when directory was last changed
			* `lastAccessTime` -  A `Date` stating when directory was accessed

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.createDirectorySync("some-dir");
				var dirInfo = FileSystem.getDirectoryInfoSync("some-dir");
				console.log("file was modified on " + dirInfo.lastWriteTime);
		*/
		object GetDirectoryInfoSync(Context context, object[] args)
		{
			return ToScriptingObject(context, _operations.GetDirectoryInfoSync(GetPathFromArgs(args)));
		}


		/**
			@scriptmethod getFileInfo(path)
			@param path (String) Path to a file
			@return (Promise) A Promise of an object containing info about the file.

			Asynchronously gets info about a file.

			The returned object has the following properties:

			* `size` –  size of file
			* `exists` –  a boolean value stating whether file exists
			* `lastWriteTime` –  A `Date` stating when file was last changed
			* `lastAccessTime` –  A `Date` stating when file was accessed

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.writeTextToFileSync("some-file.txt", "hello there");
				FileSystem.getFileInfo("some-file.txt")
					.then(function(fileInfo) {
						console.log("file was modified on " + fileInfo.lastWriteTime);
					})
					.catch(function(error) {
						"failed stat " + error
					});
		*/
		Future<FileSystemInfo> GetFileInfo(object[] args)
		{
			return _operations.GetFileInfo(GetPathFromArgs(args));
		}


		/**
			@scriptmethod getFileInfoSync(path)
			@param path (String) Path to a file
			@return (Object) An object containing info about the file.

			Synchronously gets info about a file.

			The returned object has the following properties:

			* `exists` –  a boolean value stating whether file exists
			* `lastWriteTime` –  A `Date` stating when file was last changed
			* `lastAccessTime` –  A `Date` stating when file was accessed

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.writeTextToFileSync("some-file.txt", "hello there");
				var fileInfo = FileSystem.getFileInfoSync("some-file.txt");
				console.log("file was modified on " + fileInfo.lastWriteTime);
		*/
		object GetFileInfoSync(Context context, object[] args)
		{
			return ToScriptingObject(context, _operations.GetFileInfoSync(GetPathFromArgs(args)));
		}


		/**
			@scriptproperty iosPaths

			An object containing paths only exposed on iOS devices:

			* `documents` –  Mapped to `NSDocumentDirectory`
			* `library` –  Mapped to `NSLibraryDirectory`
			* `caches` –  Mapped to `NSCachesDirectory`
			* `temp` –  Mapped to `NSTemporaryDirectory`
		*/
		Dictionary<string, string> GetIosPaths()
		{
			if defined(iOS)
			{
				return IosPaths.GetPathDictionary();
			}
			else
			{
				throw new NotSupportedException("iOS-specific paths are not supported on other platforms");
			}
		}


		/**
			@scriptmethod listDirectories(path)
			@param path (String) Path to a directory
			@return (Promise) Array of directory paths.

			Asynchronously list subdirectories in a directory.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.listDirectories(FileSystem.dataDirectory)
					.then(function(directories) {
						console.log("There are " + directories.length + " subdirectories in directory")
					}, function(error) {
						console.log("Unable to list subdirectories of directory: " + error);
					});
		*/
		Future<string[]> ListDirectories(object[] args)
		{
			return _operations.ListDirectories(GetPathFromArgs(args));
		}


		/**
			@scriptmethod listDirectoriesSync(path)
			@param path (String) Path to a directory
			@return (Array) Array of directory paths

			Synchronously list subdirectories in a directory.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				var directories = FileSystem.listDirectoriesSync(FileSystem.dataDirectory);
				console.log("There are " + directories.length + " subdirectories in directory");
		*/
		object ListDirectoriesSync(Context context, object[] args)
		{
			return ToScriptingArray(context, _operations.ListDirectoriesSync(GetPathFromArgs(args)));
		}


		/**
			@scriptmethod listEntries(path)
			@param path (String) Path to a directory
			@return (Promise) Array of subdirectories and files of directory

			Asynchronously lists both files and subdirectories in a directory.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.listEntries(FileSystem.dataDirectory)
					.then(function(entries) {
						console.log("There are " + entries.length + " entries in directory")
					}, function(error) {
						console.log("Unable to list entries in directory due to error " + error);
					});
		*/
		Future<string[]> ListEntries(object[] args)
		{
			return _operations.ListEntries(GetPathFromArgs(args));
		}


		/**
			@scriptmethod listEntriesSync(path)
			@param path (String) Path to a directory
			@return (Array) Array of subdirectories and files in the directory

			Synchronously lists both files and subdirectories in a directory.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				var entries = FileSystem.listEntriesSync(FileSystem.dataDirectory);
				console.log("There are " + entries.length + " entries in directory");
		*/
		object ListEntriesSync(Context context, object[] args)
		{
			return ToScriptingArray(context, _operations.ListEntriesSync(GetPathFromArgs(args)));
		}


		/**
			@scriptmethod listFiles(path)
			@param path (String) Path to a directory
			@return (Promise) Array of filenames in the directory

			Asynchronously list files in directory.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.listFiles(FileSystem.dataDirectory)
					.then(function(files) {
						console.log("There are " + files.length + " files in directory")
					}, function(error) {
						console.log("Unable to list files in directory due to error " + error);
					});
		*/
		Future<string[]> ListFiles(object[] args)
		{
			return _operations.ListFiles(GetPathFromArgs(args));
		}


		/**
			@scriptmethod listFilesSync(path)
			@param path (String) Path to a directory
			@return (Array) Array of filenames in the directory

			Synchronously list files in directory.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				var files = FileSystem.listFilesSync(FileSystem.dataDirectory);
				console.log("There are " + files.length + " files in directory");
		*/
		object ListFilesSync(Context context, object[] args)
		{
			return ToScriptingArray(context, _operations.ListFilesSync(GetPathFromArgs(args)));
		}


		/**
			@scriptmethod move(source, destination)
			@param source (String) Source path
			@param destination (String) Destination path
			@return Promise of nothing

			Asynchronously moves a file or directory from source to destination path

			## Example

				FileSystem = require("FuseJS/FileSystem");

				FileSystem.writeTextToFile("to-be-moved.txt", "hello world")
					.then(function() {
						return FileSystem.move("to-be-moved.txt", "destination-reached.txt");
					})
					.catch(function(err) {
						console.log("Unable to move file");
					});
		*/
		Future<Nothing> Move(object[] args)
		{
			var source = GetArg<string>(args, 0, "First argument `source` has to be a valid path");
			var destination = GetArg<string>(args, 1, "Second argument `destination` has to be a valid path");
			return _operations.Move(source, destination);
		}

		/**
			@scriptmethod moveSync(source, destination)
			@param source (String) Source path
			@param destination (String) Destination path

			Synchronously moves a file or directory from source to destination path

			## Example

				FileSystem = require("FuseJS/FileSystem");

				FileSystem.writeTextToFileSync("to-be-moved.txt", "hello world");
				FileSystem.moveSync("to-be-moved.txt", "destination-reached.txt");
		*/
		object MoveSync(Context context, object[] args)
		{
			var source = GetArg<string>(args, 0, "First argument `source` has to be a valid path");
			var destination = GetArg<string>(args, 1, "Second argument `destination` has to be a valid path");
			_operations.MoveSync(source, destination);
			return null;
		}


		/**
			@scriptmethod copy(source, destination)
			@param source (String) Source path
			@param destination (String) Destination path
			@return Promise of nothing

			Asynchronously copies a file or directory recursively from source to destination path

			## Example

				FileSystem = require("FuseJS/FileSystem");

				FileSystem.writeTextToFile("to-be-copied.txt", "hello world")
					.then(function() {
						return FileSystem.copy("to-be-copied.txt", "destination-reached.txt");
					})
					.catch(function(err) {
						console.log("Unable to copy file");
					});
		*/
		Future<Nothing> Copy(object[] args)
		{
			var source = GetArg<string>(args, 0, "First argument `source` has to be a valid path");
			var destination = GetArg<string>(args, 1, "Second argument `destination` has to be a valid path");
			return _operations.Copy(source, destination);
		}

		/**
			@scriptmethod copySync(source, destination)
			@param source (String) Source path
			@param destination (String) Destination path

			Synchronously copies a file or directory recursively from source to destination path

			## Example

				FileSystem = require("FuseJS/FileSystem");

				FileSystem.writeTextToFileSync("to-be-copied.txt", "hello world");
				FileSystem.copySync("to-be-copied.txt", "destination-reached.txt");
		*/
		object CopySync(Context context, object[] args)
		{
			var source = GetArg<string>(args, 0, "First argument `source` has to be a valid path");
			var destination = GetArg<string>(args, 1, "Second argument `destination` has to be a valid path");
			_operations.CopySync(source, destination);
			return null;
		}


		/**
			@scriptmethod readBufferFromFile(filename)
			@param filename (String) Path to file
			@return (Promise) A Promise of the file's contents as an ArrayBuffer.

			Asynchronously reads a file and returns a Promise of an ArrayBuffer with its contents.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.readBufferFromFile("myfile.txt")
					.then(function(contents) {
						console.log(contents);
					}, function(error) {
						console.log(error);
					});
		*/
		Future<byte[]> ReadBufferFromFile(object[] args)
		{
			return _operations.ReadBufferFromFile(GetPathFromArgs(args));
		}


		/**
			@scriptmethod readBufferFromFileSync(filename)
			@param filename (String) Path to file
			@return (ArrayBuffer) The file's contents as an ArrayBuffer.

			Synchronously reads a file and returns an ArrayBuffer with its contents.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				var data = FileSystem.readBufferFromFileSync("myfile.txt");
		*/
		object ReadBufferFromFileSync(Context context, object[] args)
		{
			return _operations.ReadBufferFromFileSync(GetPathFromArgs(args));
		}


		/**
			@scriptmethod readTextFromFile(filename)
			@param filename (String) Path to file
			@return (Promise) A Promise of the file's contents as a String.

			Asynchronously reads a file and returns a Promise of its contents.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.readTextFromFile("myfile.txt")
					.then(function(contents) {
						console.log(contents);
					}, function(error) {
						console.log(error);
					});
		*/
		Future<string> ReadTextFromFile(object[] args)
		{
			return _operations.ReadTextFromFile(GetPathFromArgs(args));
		}


		/**
			@scriptmethod readTextFromFileSync(filename)
			@param filename (String) Path to file
			@return (String) The contents of the file as a String.

			Synchronously reads a file and returns its contents as a string.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				var content =  FileSystem.readTextFromFileSync(FileSystem.dataDirectory + "/" + "myfile.txt");
				console.log("The file contains " + content));
		*/
		object ReadTextFromFileSync(Context context, object[] args)
		{
			return _operations.ReadTextFromFileSync(GetPathFromArgs(args));
		}


		/**
			@scriptmethod writeBufferToFile(filename, data)
			@param filename (String) Path to file
			@param data (ArrayBuffer) Data to write to the file
			@return (Promise) A Promise of nothing.

			Asynchronously writes an `ArrayBuffer` to a file.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				var data = new ArrayBuffer(4);
				var view = new Int32Array(data);
				view[0] = 0x1337;

				FileSystem.writeBufferToFile(FileSystem.dataDirectory + "/" + "myfile.txt", data)
					.then(function() {
						console.log("Successful write");
					}, function(error) {
						console.log(error);
					});
		*/
		Future<Nothing> WriteBufferToFile(object[] args)
		{
			var path = GetPathFromArgs(args);
			var data = GetArg<byte[]>(args, 1, "Second argument \"data\" is required to be an ArrayBuffer");
			return _operations.WriteBufferToFile(path, data);
		}


		/**
			@scriptmethod writeBufferToFileSync(filename, data)
			@param filename (String) Path to file
			@param data (ArrayBuffer) Data to write to the file

			Synchronously writes an `ArrayBuffer` to a file.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				var data = new ArrayBuffer(4);
				var view = new Int32Array(data);
				view[0] = 0x1337;

				FileSystem.writeBufferToFileSync(FileSystem.dataDirectory + "/" + "myfile.txt", data);
		*/
		object WriteBufferToFileSync(Context context, object[] args)
		{
			var path = GetPathFromArgs(args);
			var data = GetArg<byte[]>(args, 1, "Second argument \"data\" is required to be an ArrayBuffer");
			_operations.WriteBufferToFileSync(path, data);
			return null;
		}


		/**
			@scriptmethod writeTextToFile(filename, text)
			@param filename (String) Path to file
			@param text (String) Text to write to the file
			@return (Promise) A Promise of nothing.

			Asynchronously writes a string to a UTF-8 encoded file.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.writeTextToFile(FileSystem.dataDirectory + "/" + "myfile.txt", "Hello buddy")
					.then(function() {
						console.log("Successful write");
					}, function(error) {
						console.log(error);
					});
		*/
		Future<Nothing> WriteTextToFile(object[] args)
		{
			var path = GetPathFromArgs(args);
			var text = GetArg<string>(args, 1, "Second argument \"text\" is required to be a string");
			return _operations.WriteTextToFile(path, text);
		}


		/**
			@scriptmethod writeTextToFileSync(filename, text)
			@param filename (String) Path to file
			@param text (String) Text to write to the file

			Synchronously writes a string to a UTF-8 encoded file.

			## Example

				var FileSystem = require("FuseJS/FileSystem");

				FileSystem.writeTextToFileSync("myfile.txt", "Hello buddy");
		*/
		object WriteTextToFileSync(Context context, object[] args)
		{
			var path = GetPathFromArgs(args);
			var text = GetArg<string>(args, 1, "Second argument \"text\" is required to be a string");
			_operations.WriteTextToFileSync(path, text);
			return null;
		}


		private static T GetArg<T>(object[] args, int index, string error)
			where T : class
		{
			if (args == null)
				throw new ArgumentNullException(nameof(args));

			var val = args.Length > index ? args[index] as T : null;
			if (val == null)
			{
				throw new Scripting.Error(error);
			}
			return val;
		}


		private static string GetPathFromArgs(object[] args)
		{
			if (args == null)
				throw new ArgumentNullException(nameof(args));

			var filename = args.Length > 0 ? args[0] as string : null;
			if (filename == null)
			{
				throw new Scripting.Error("first argument path is required to be a string");
			}
			return filename;
		}


		private static Scripting.Array ToScriptingArray<T>(Context context, T[] sourceArray)
		{
			var convertedArray = ((IEnumerable<T>)sourceArray).OfType<T,object>().ToArray();
			return context.NewArray(convertedArray);
		}


		private static Scripting.Object ToScriptingObject(Context context, FileSystemInfo info)
		{
			var jsobj = context.NewObject();

			// TODO: Map timestamps
			var fileInfo = info as FileInfo;
			if (fileInfo != null)
				jsobj["length"] = (double)fileInfo.Length;
			jsobj["exists"] = info.Exists;
			jsobj["fullName"] = PathTools.NormalizePath(info.FullName);
			jsobj["lastWriteTime"] = ToScriptingDate(context, info.LastWriteTimeUtc);
			jsobj["lastAccessTime"] = ToScriptingDate(context, info.LastAccessTimeUtc);
			return jsobj;
		}


		private static object ToScriptingDate(Context context, ZonedDateTime time)
		{
			var msSinceUnixEpoch = ((time.ToInstant() - Uno.Time.Constants.UnixEpoch).Ticks)
										/ Uno.Time.Constants.TicksPerMillisecond;
			return context.Evaluate("(Date Converter)", string.Format("new Date({0})", msSinceUnixEpoch));
		}


		private static Scripting.Object ToScriptingObject<T>(Context context, Dictionary<string, T> dict)
		{
			var jsobj = context.NewObject();
			foreach (var kvp in dict)
			{
				jsobj[kvp.Key] = kvp.Value;
			}
			return jsobj;
		}
	}
}
