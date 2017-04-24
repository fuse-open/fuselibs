using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.IO;
using Fuse.Scripting;

namespace FuseJS
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/Bundle
		
		The bundle API allows you to read files that is bundled with the application, defined in the project file (using `<filename>:Bundle`).
		
		```
		var Bundle = require("FuseJS/Bundle");
		```

		You can read up on bundling files [here](/docs/assets/bundle)
	*/
	public sealed class Bundle : NativeModule
	{
		static readonly Bundle _instance;

		public Bundle()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Bundle");
			AddMember(new NativeFunction("readSync", Read));
			AddMember(new NativePromise<string, string>("read", ReadAsync, null));
		}

		static bool TryGetBundleFile(string sourcePath, out BundleFile bundleFile)
		{
			bundleFile = null;
			foreach(var bf in Uno.IO.Bundle.AllFiles)
			{
				if(bf.SourcePath == sourcePath)
				{
					bundleFile = bf;
					return true;
				}
			}
			return false;
		}

		/**
			@scriptmethod read(filename)
			@param filename (String) The name of the bundled file to read
			@return (Promise) A promise of the file's contents
			
			Asynchronously reads a file from the application bundle
			
			```
			var Bundle = require("FuseJS/Bundle");
			
			Bundle.read("someData.json")
				.then(function(contents) {
					console.log(contents);
				}, function(error) {
					console.log("Error!", error);
				});
			```
		*/
		static Future<string> ReadAsync(object[] args)
		{
			if (args.Length > 0)
			{
				var filename = args[0] as string;
				return ReadAsync(filename ?? "");
			}
			return ReadAsync("");	
		}

		/**
			@scriptmethod readSync(filename)
			@param filename (String) The name of the bundled file to read
			@return (String) The contents of the file
			
			Synchronously reads a file from the application bundle
			
			```
			var Bundle = require("FuseJS/Bundle");
			
			var contents = Bundle.readSync("someData.json");
			console.log(contents);
			```
			
			> Warning: This call will block until the operation is finished. If you are reading large amounts of data, use read() instead.
		*/
		static object Read(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				var filename = args[0] as string;
				return Read(filename);
			}
			return "";
		}
		
		static string Read(string filename)
		{
			try
			{
				BundleFile bundleFile;
				if(TryGetBundleFile(filename, out bundleFile))
				{
					return bundleFile.ReadAllText();
				}
				return "";
			}
			catch(Exception e)
			{
				return ""; // HACK!!
			}	
		}

		static Future<string> ReadAsync(string filename)
		{
			return Promise<string>.Run(new ReadClosure(filename).Invoke);
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
				return Bundle.Read(_filename);
			}
		}
	}
}
