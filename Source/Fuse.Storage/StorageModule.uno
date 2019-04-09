using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;

namespace Fuse.Storage
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/Storage
		
		The storage API allows you to read from and write to files in the application directory.
		
			var Storage = require("FuseJS/Storage");

		Check out the individual functions for documentation on how to use them.
	*/
	public sealed class StorageModule : NativeModule
	{
		static readonly StorageModule _instance;
		public StorageModule()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Storage");
			AddMember(new NativeFunction("writeSync", Write));
			AddMember(new NativeFunction("readSync", Read));
			AddMember(new NativeFunction("removeSync", Remove));
			// Note: 'delete' is a reserved word in TypeScript, so similar methods in the FileSystem module
			// were renamed to 'remove'. The 'removeSync' method in this module was renamed to match this.
			// Calling 'deleteSync' will still work to avoid breaking existing code.
			AddMember(new NativeFunction("deleteSync", Remove));
			AddMember(new NativePromise<bool, bool>("write", WriteAsync, null));
			AddMember(new NativePromise<string, string>("read", ReadAsync, null));
		}

		/**
			@scriptmethod write(filename, contents)
			@param filename (String) The file to write to
			@param contents (String) The contents to write to the file
			@return (Promise) A promise of a boolean, which will be `true` if the write succeeded.
			
			Asynchronously writes to a file.
			
				var Storage = require("FuseJS/Storage");
				
				Storage.write("myfile.txt", "Hello from Fuse!")
					.then(function(succeeded) {
						if(succeeded) {
							console.log("Successfully wrote to file");
						}
						else {
							console.log("Couldn't write to file.");
						}
					});
		*/
		static Future<bool> WriteAsync(object[] args)
		{
			if (args.Length > 0)
			{
				var filename = args[0] as string;
				var value = args[1] as string;
				return Fuse.Storage.ApplicationDir.WriteAsync(filename ?? "", value ?? "");
			}

			return Fuse.Storage.ApplicationDir.WriteAsync("", "");
		}

		/**
			@scriptmethod read(filename)
			@param filename (String) The file to read
			@return (Promise) A promise of the file's contents.
			
			Asynchronously reads a file and returns a promise of its contents.
			
				var Storage = require("FuseJS/Storage");
				
				Storage.read("myfile.txt")
					.then(function(contents) {
						console.log(contents);
					}, function(error) {
						console.log(error);
					});
		*/
		static Future<string> ReadAsync(object[] args)
		{
			if (args.Length > 0)
			{
				var filename = args[0] as string;
				return Fuse.Storage.ApplicationDir.ReadAsync(filename ?? "");
			}
			return Fuse.Storage.ApplicationDir.ReadAsync("");	
		}

		/**
			@scriptmethod removeSync(filename)
			@param filename (String) The file to delete
			@return (boolean) `true` if the file was deleted, `false` otherwise.

			Synchrounously deletes a file inside the application folder.
			
				var Storage = require("FuseJS/Storage");
				
				var success = Storage.removeSync("uselessFile.txt");
				if(success) {
					console.log("Deleted file");
				}
				else {
					console.log("An error occured!");
				}

			> Warning: This call will block until the operation is finished.
		*/
		static object Remove(Scripting.Context c, object[] args)
		{
			if (args.Length > 0)
			{
				var filename = args[0] as string;
				return Fuse.Storage.ApplicationDir.Delete(filename);
			}
			return false;
		}

		/**
			@scriptmethod writeSync(filename, contents)
			@param filename (String) The file to write to
			@return (boolean) `true` if the write was successful, `false` otherwise
			
			Synchrounously writes data to a file inside the application folder.
			
				var Storage = require("FuseJS/Storage");
				
				var success = Storage.writeSync("myfile.txt", "Hello from Fuse!");
				if(success) {
					console.log("Successfully wrote to file");
				}
				else {
					console.log("An error occured!");
				}
			
			> Warning: This call will block until the operation is finished. Use write() if you are writing large amounts of data.
		*/
		static object Write(Scripting.Context c, object[] args)
		{
			if (args.Length > 0)
			{
				var filename = args[0] as string;
				var value = args[1] as string;
				return Fuse.Storage.ApplicationDir.Write(filename ?? "", value ?? "");
			}

			return Fuse.Storage.ApplicationDir.Write("", "");
		}

		/**
			@scriptmethod readSync(filename)
			@param filename (String) The file to read from
			@return (String) The contents of the file
			
			Synchrounously reads data from a file inside the application folder.
			
				var Storage = require("FuseJS/Storage");
				
				var contents = Storage.readSync("myfile.txt");
				console.log(contents);
			
			> Warning: This call will block until the operation is finished. Use read() if you are reading large amounts of data.
		*/
		static object Read(Scripting.Context c, object[] args)
		{
			string filename = null;
			if (args.Length > 0)
				filename = args[0] as string;

			string content;
			if (Fuse.Storage.ApplicationDir.TryRead(filename ?? "", out content))
				return content;
			else
				return string.Empty; // HACK!!
		}
	}
}
