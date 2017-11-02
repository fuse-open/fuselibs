using Uno;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Fuse;
using Fuse.Navigation;
using Fuse.Android.Controls.WebViewUtils;
using Fuse.Android.Controls.WebViewUtils.WebViewForeign;
using Fuse.Controls;

namespace Fuse.Android.Controls
{	
	
	extern (Android) public class WebView :
		Fuse.Controls.Native.Android.LeafView,
		Fuse.Controls.IWebView
	{
		Java.Object _webChromeClientHandle;
		Java.Object _webViewClientHandle;
		Java.Object _webViewHandle;
		
		public event ValueChangedHandler<double> ProgressChanged;
		public event EventHandler BeginLoading;
		public event EventHandler UrlChanged;
		public event EventHandler PageLoaded;
		public event EventHandler URISchemeHandler;
		
		Fuse.Controls.WebView _webViewHost;
		JSEvalRequestManager _evalRequestMgr;
		string[] _uriSchemes;

		public static WebView Create(Fuse.Controls.WebView webViewHost, string[] schemes)
		{
			var handle = WebViewForeign.CreateWebView(webViewHost.ZoomEnabled, webViewHost.ScrollEnabled);
			return new WebView(webViewHost, handle, schemes);
		}

		WebView(Fuse.Controls.WebView host, Java.Object handle, string[] schemes) : base(handle)
		{
			_webViewHost = host;
			_webViewHandle = handle;
			
			_evalRequestMgr = new JSEvalRequestManager(_webViewHandle);
			
			_webChromeClientHandle = _webViewHandle.CreateAndSetWebChromeClient(OnProgressChanged);				
			_webViewClientHandle = _webViewHandle.CreateAndSetWebViewClient(
				OnPageLoaded, 
				OnBeginloading, 
				OnUrlChanged, 
				OnCustomURI, 
				schemes, 
				HasURISchemeHandler
			);
			_uriSchemes = schemes;

			_webViewHost.WebViewClient = this;
		}
		
		public bool HasURISchemeHandler()
		{
			return URISchemeHandler!=null;
		}
		
		void OnCustomURI(string url)
		{
			if(URISchemeHandler!=null)
				URISchemeHandler(this, new URISchemeEventArgs(url));
		}
		
		void OnPageLoaded()
		{
			if(PageLoaded!=null)
				PageLoaded(this, EventArgs.Empty);
		}
		
		void OnBeginloading()
		{
			if(BeginLoading!=null)
				BeginLoading(this, EventArgs.Empty);
		}
		
		void OnUrlChanged()
		{
			if(UrlChanged!=null)
				UrlChanged(this, EventArgs.Empty);
		}

		public void Eval(string js, Action<string> resultHandler)
		{
			_evalRequestMgr.EvaluateJs(js, resultHandler);
		}

		public void Eval(string js)
		{
			_evalRequestMgr.EvaluateJs(js, null);
		}

		public string BaseUrl { get; set; }

		string _source;
		public string Source
		{
			get { return _source; }
			set { LoadHtml(_source = value); }
		}

		public string Url
		{
			get { return _webViewHandle.GetUrl(); }
			set { LoadUrl(value); }
		}

		public string DocumentTitle
		{
			get { return _webViewHandle.GetTitle(); }
		}

		public bool CanGoBack
		{
			get { return _webViewHandle.CanGoBack(); }
		}

		public bool CanGoForward
		{
			get { return _webViewHandle.CanGoForward(); }
		}

		public void GoBack()
		{
			_webViewHandle.GoBack();
		}

		public void GoForward()
		{
			_webViewHandle.GoForward();
		}

		public void Reload()
		{
			_webViewHandle.Reload();
		}

		public void Stop()
		{
			_webViewHandle.StopLoading();
		}

		public event HistoryChangedHandler HistoryChanged;

		void OnHistoryChanged()
		{
			if (HistoryChanged != null)
			{
				HistoryChanged(_webViewHost);
			}
		}
		
		public void LoadHtml(string html)
		{
			LoadHtml(html, null);
		}
		
		public void LoadHtml(string html, string baseUrl)
		{
			if(html == null || html == "") return;
			_webViewHandle.LoadHtml(html, baseUrl ?? BaseUrl ?? "");

			// Should OnHistoryChanged be called here?
			OnHistoryChanged();
		}

		public void LoadUrl(string url)
		{
			if (url == null || url== "") url = "about:blank";
			//This extra check is needed on android since setting the Url directly doesn't trigger shouldOverrideUrlLoading
			if(HasURISchemeHandler())
			{
				foreach(string uri in _uriSchemes)
				{
					if(url.IndexOf(uri) == 0)
					{
						OnCustomURI(url);
						return;
					}
				}
			}
			_webViewHandle.LoadUrl(url);
			OnHistoryChanged();
		}
		
		void OnProgressChanged(int newProgress)
		{
			if (ProgressChanged != null)
				ProgressChanged(this, new ValueChangedArgs<double>(newProgress/100.0));
		}
		
		public double Progress
		{
			get { return _webViewHandle.GetProgress() / 100.0; }
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
		
		public bool ZoomEnabled { get; set; }
		public bool ScrollEnabled { get; set; }
	}
}
