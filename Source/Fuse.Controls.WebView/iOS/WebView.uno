using Uno;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Fuse;
using Fuse.Elements;
using Fuse.Navigation;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls;

namespace Fuse.iOS.Controls
{
	
	[Require("Source.Include", "iOS/NoZoomDelegate.h")]
	[Require("Source.Include", "WebKit/WebKit.h")]
	static extern(iOS) class WKWebViewHelpers
	{
		[Foreign(Language.ObjC)]
		public static void EvalOnWebViewWithHandler(ObjC.Object webview, string js, Action<string> handler)
		@{
				WKWebView* wv = webview;
				[wv evaluateJavaScript:js completionHandler:^(id result, NSError* error) {
					handler(result);
				}];
		@}

		[Foreign(Language.ObjC)]
		public static void EvalOnWebView(ObjC.Object webview, string js)
		@{
				WKWebView* wv = webview;
				[wv evaluateJavaScript:js completionHandler:nil];
		@}

		[Foreign(Language.ObjC)]
		public static void LoadHTML(ObjC.Object webview, string html, string baseURL)
		@{
				WKWebView* wv = webview;
				[wv loadHTMLString:html baseURL:[NSURL URLWithString:baseURL]];
		@}

		[Foreign(Language.ObjC)]
		public static string GenBaseUrl(string path)
		@{
				NSString *resourcePath = [[[[NSBundle bundleForClass:[StrongUnoObject class]] resourcePath]
					stringByReplacingOccurrencesOfString:@"/" withString:@"//"]
					stringByReplacingOccurrencesOfString:@" " withString:@"%20"];

				return resourcePath;
		@}

		[Foreign(Language.ObjC)]
		public static ObjC.Object CreateWebView(bool zoomEnabled, bool scrollEnabled)
		@{
			WKWebView* wv = [[WKWebView alloc] init];
			wv.scrollView.delegate = zoomEnabled ? NULL : [[NoZoomDelegate alloc] init];
			wv.scrollView.scrollEnabled = scrollEnabled;

			return wv;
		@}

		[Foreign(Language.ObjC)]
		public static string GetURL(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			return wv.URL.absoluteString;
		@}

		[Foreign(Language.ObjC)]
		public static bool GetIsLoading(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			return wv.loading;
		@}

		[Foreign(Language.ObjC)]
		public static void LoadURL(ObjC.Object handle, String url)
		@{
			WKWebView* wv = handle;
			id nsurl = [NSURL URLWithString:url];
			id request = [[NSURLRequest alloc] initWithURL:nsurl];
			[wv loadRequest:request];
		@}

		[Foreign(Language.ObjC)]
		public static double GetEstimatedProgress(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			return wv.estimatedProgress;
		@}

		[Foreign(Language.ObjC)]
		public static string GetTitle(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			return wv.title;
		@}

		[Foreign(Language.ObjC)]
		public static bool GetCanGoBack(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			return wv.canGoBack;
		@}

		[Foreign(Language.ObjC)]
		public static void GoBack(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			[wv goBack];
		@}

		[Foreign(Language.ObjC)]
		public static bool GetCanGoForward(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			return wv.canGoForward;
		@}

		[Foreign(Language.ObjC)]
		public static void GoForward(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			[wv goForward];
		@}

		[Foreign(Language.ObjC)]
		public static void Reload(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			[wv reload];
		@}

		[Foreign(Language.ObjC)]
		public static void StopLoading(ObjC.Object handle)
		@{
			WKWebView* wv = handle;
			[wv stopLoading];
		@}

		[Foreign(Language.ObjC)]
		public static void FreeMemory()
		@{
			id cache = [NSURLCache sharedURLCache];
			if(cache!=nil)
				[cache removeAllCachedResponses];
		@}

		[Foreign(Language.ObjC)]
		public static void SetNavigationDelegate(ObjC.Object webViewHandle, ObjC.Object delegateHandle)
		@{
			[webViewHandle setNavigationDelegate:delegateHandle];
		@}
	}

	extern (iOS) public class WebView :
		Fuse.Controls.Native.iOS.LeafView,
		Fuse.Controls.IWebView
	{

		public event ValueChangedHandler<double> ProgressChanged;
		Fuse.Controls.WebView _webViewHost;
		readonly ObjC.Object Handle;
		readonly ObjC.Object NavigationDelegate;

		public static WebView Create(Fuse.Controls.WebView webViewHost, string[] schemes)
		{
			var wv = WKWebViewHelpers.CreateWebView(webViewHost.ZoomEnabled, webViewHost.ScrollEnabled);
			return new WebView(webViewHost, wv, schemes);
		}

		WebView(Fuse.Controls.WebView webViewHost, ObjC.Object wvHandle, string[] schemes) : base(wvHandle)
		{
			_webViewHost = webViewHost;
			Handle = wvHandle;
			NavigationDelegate = NavDelegate.Create(OnBeginNavigation, OnFinishNavigation, OnURLChanged, OnCustomURI, schemes, HasURISchemeHandler);
			WKWebViewHelpers.SetNavigationDelegate(Handle, NavigationDelegate);
			Fuse.Platform.AppEvents.LowMemoryWarning += OnLowMemory;
			_webViewHost.WebViewClient = this;
		}

		public override void Dispose()
		{
			_webViewHost.WebViewClient = null;
			_webViewHost = null;
			base.Dispose();
		}

		public event HistoryChangedHandler HistoryChanged
		{
			add { throw new NotImplementedException(); }
			remove { throw new NotImplementedException(); }
		}

		~WebView()
		{
			if (Handle != null)
				Fuse.Platform.AppEvents.LowMemoryWarning -= OnLowMemory;
			if(_isUpdating)
				_isUpdating = false;
				UpdateManager.RemoveAction(OnUpdate);
		}

		void OnLowMemory()
		{
			debug_log "low mem in WebView";
			WKWebViewHelpers.FreeMemory();
		}

		public string BaseUrl { get; set; }

		string _source;
		public string Source
		{
			get { return _source; }
			set { LoadHtml(_source = value); }
		}

		public void LoadHtml(string html)
		{
			LoadHtml(html, "");
		}

		public void LoadHtml(string html, string baseUrl)
		{
			WKWebViewHelpers.LoadHTML(Handle, html, baseUrl);
			StartProgressUpdate();
		}

		public string Url
		{
			get { return WKWebViewHelpers.GetURL(Handle); }
			set { LoadUrl(value); }
		}

		public void LoadUrl(string url)
		{
			if (url == null || url == "") url = "about:blank";
			WKWebViewHelpers.LoadURL(Handle, url);
			StartProgressUpdate();
		}

		bool _isUpdating = false;
		void StartProgressUpdate()
		{
			if (!_isUpdating)
				UpdateManager.AddAction(OnUpdate);
		}

		void OnUpdate()
		{
			OnProgressChanged();
			if (!Loading)
			{
				_isUpdating = false;
				UpdateManager.RemoveAction(OnUpdate);
			}
		}

		public void Eval(string js)
		{
			WKWebViewHelpers.EvalOnWebView(Handle, js);
		}

		public void Eval(string js, Action<string> onResult)
		{
			WKWebViewHelpers.EvalOnWebViewWithHandler(Handle, js, onResult);
		}

		FileSource _file;
		public FileSource File
		{
			get { return _file; }
			set
			{
				_file = value;
				if (_file != null)
					LoadFile(_file);
			}
		}

		void LoadFile(FileSource file)
		{
			string data = "";
			try{
				data = file.ReadAllText();
			}catch(Uno.Exception e){
				data = e.ToString();
			}finally{
				LoadHtml(data);
			}
		}

		void OnProgressChanged()
		{
			if (ProgressChanged != null)
				ProgressChanged(this, new ValueChangedArgs<double>(Progress));
		}


		void OnBeginNavigation()
		{
			if(BeginLoading != null)
				BeginLoading(this, EventArgs.Empty);
		}

		void OnURLChanged()
		{
			if(UrlChanged != null)
				UrlChanged(this, EventArgs.Empty);
		}
		
		public bool HasURISchemeHandler()
		{
			return URISchemeHandler != null;
		}
		
		void OnCustomURI(string url)
		{
			if(URISchemeHandler!=null)
				URISchemeHandler(this, new URISchemeEventArgs(url));
		}

		void OnFinishNavigation()
		{
			if(PageLoaded != null)
				PageLoaded(this, EventArgs.Empty);
		}

		public bool Loading { get { return WKWebViewHelpers.GetIsLoading(Handle); } }
		public double Progress { get { return WKWebViewHelpers.GetEstimatedProgress(Handle); } }
		public string DocumentTitle { get { return WKWebViewHelpers.GetTitle(Handle); } }
		public bool CanGoBack { get { return WKWebViewHelpers.GetCanGoBack(Handle); } }
		public bool CanGoForward { get { return WKWebViewHelpers.GetCanGoForward(Handle); } }
		public void GoBack() { WKWebViewHelpers.GoBack(Handle); }
		public void GoForward() { WKWebViewHelpers.GoForward(Handle); }
		public void Reload() { WKWebViewHelpers.Reload(Handle); }
		public void Stop() { WKWebViewHelpers.StopLoading(Handle); }
		public event EventHandler BeginLoading;
		public event EventHandler PageLoaded;
		public event EventHandler UrlChanged;
		public event EventHandler URISchemeHandler;
		public bool ZoomEnabled { get; set; }
		public bool ScrollEnabled { get; set; }
	}
}
