using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.IO;
using Uno.Collections;
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
			AddMember(new NativeFunction("readSync", ReadSync));
			AddMember(new NativePromise<string, string>("read", ReadAsync, null));
			AddMember(new NativePromise<string, Fuse.Scripting.Object>("extract", Extract, null));
			AddMember(new NativePromise<IEnumerable<BundleFile>, Fuse.Scripting.Array>("list", GetList, ListConverter));
			AddMember(new NativePromise<byte[], string>("readBuffer", ReadBuffer));
		}
		
		/**
			@scriptmethod readBuffer(bundlePath)
			@return (Promise) A promise of an ArrayBuffer of data
			
			Read a bundled file as an ArrayBuffer of bytes 
			
			```
			var Observable = require("FuseJS/Observable");
			var Bundle = require("FuseJS/Bundle");
			var ImageTools = require("FuseJS/ImageTools");
			var imageUrlToDisplay = Observable();
			
			Bundle.readBuffer("assets/image.jpg").then(function(buffer) {
				//Do something with the image data here
			});
			```
		*/
		public static Future<byte[]> ReadBuffer(object[] args)
		{
			var searchPath = args.ValueOrDefault<string>(0, "");
			if(searchPath=="")
				return Reject<byte[]>("Argument 0 (bundle path) can not be undefined");
				
			return Promise<byte[]>.Run(new ReadBufferClosure(searchPath).Invoke);
		}

		static Fuse.Scripting.Array ListConverter(Context context, IEnumerable<BundleFile> list)
		{
			var output = context.NewArray();
			var i = 0;
			foreach(var b in list)
				output[i++] = b.SourcePath;
			return output;
		}
		

		/**
			@scriptmethod list()
			@return (Promise) A promise of an array of bundle file paths
			
			Fetch a list of every file bundled with the application. 
			
			```
			var Bundle = require("FuseJS/Bundle");
			
			Bundle.list().then(function(list) {
				//list is an array of paths, such as "assets/image.jpg"
			});
			```
		*/
		public static Future<IEnumerable<BundleFile>> GetList(object[] args = null)
		{
			var p = new Promise<IEnumerable<BundleFile>>();
			var files = Uno.IO.Bundle.AllFiles;
			p.Resolve(files);
			return p;
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
		static Future<T> Reject<T>(string reason)
		{
			var p = new Promise<T>();
			p.Reject(new Exception(reason));
			return p;
		}
		

		/**
			@scriptmethod extract(bundleFilePath, destinationPath)
			@param bundleFilePath (String) The path of the bundled file to read (ie 'assets/image.jpg')
			@param destinationPath (String) The absolute path to write the file to (ie 'c:/someDirectory/image.jpg')
			@return (Promise) A promise of the path the file was written to (echo)
			
			Asynchronously reads a file from the application bundle and writes it to a destination on the device.
			Use with `FuseJS/FileSystem` to determine destination paths. This is useful for extracting html and associated content for local use with WebView via `file://` protocol.
			
			```
			var Bundle = require("FuseJS/Bundle");
			var FileSystem = require("FuseJS/FileSystem");
			var Observable = require("FuseJS/Observable");
			var urlForWebView = Observable();
			
			Bundle.extract("assets/site/page.html", FileSystem.dataDirectory + "site/page.html").then(function(resultPath) {
				urlForWebView.value = "file://" + resultPath;
			});
			```
		*/
		public static Future<string> Extract(object[] args)
		{
			var searchPath = args.ValueOrDefault<string>(0, "");
			var destinationPath = args.ValueOrDefault<string>(1, "");
			var overwrite = args.ValueOrDefault<bool>(2,false);
			
			if(searchPath=="")
				return Reject<string>("Argument 0 (bundle path) can not be undefined");
			if(destinationPath=="")
				return Reject<string>("Argument 1 (destination path) can not be undefined");
			
			return Promise<string>.Run(new ExtractClosure(searchPath, destinationPath, overwrite).Invoke);
		}

		/**
			@scriptmethod read(filename)
			@param filename (String) The name of the bundled file to read
			@return (Promise) A promise of the file's contents
			
			Asynchronously reads a file from the application bundle
			
			```
			var Bundle = require("FuseJS/Bundle");
			
			Bundle.read("someData.json").then(function(contents) {
				console.log(contents);
			}, function(error) {
				console.log("Error!", error);
			});
			```
		*/
		public static Future<string> ReadAsync(object[] args)
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
		static object ReadSync(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				var filename = args[0] as string;
				return ReadSync(filename);
			}
			return "";
		}
		
		public static string ReadSync(string filename)
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
		
		class ExtractClosure
		{
			readonly string _searchPath;
			readonly string _destPath;
			readonly bool _overwrite;
			public ExtractClosure(string searchPath, string destinationPath, bool overwriteIfExists)
			{
				_searchPath = searchPath;
				_destPath = destinationPath;
				_overwrite = overwriteIfExists;
			}
			public string Invoke()
			{
				BundleFile bfile;
				if(TryGetBundleFile(_searchPath, out bfile))
				{
					if(_overwrite || !File.Exists(_destPath))
					{
						Directory.CreateDirectory(Path.GetDirectoryName(_destPath));
						File.WriteAllBytes(_destPath, bfile.ReadAllBytes());
					}
				}
				return _destPath;
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
				return Bundle.ReadSync(_filename);
			}
		}
		
		class ReadBufferClosure
		{
			readonly string _filename;

			public ReadBufferClosure(string filename)
			{
				_filename = filename;
			}
			public byte[] Invoke()
			{
				BundleFile bfile;
				if(TryGetBundleFile(_filename, out bfile))
				{
					return bfile.ReadAllBytes();
				}
				return new byte[] {};
			}
		}
	}
}
