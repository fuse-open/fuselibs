using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Input;
using Fuse.Gestures;
using Fuse.Animations;
using Fuse.Elements;
using Fuse.Triggers;
using Fuse.Scripting;
using Fuse.Navigation;

namespace Fuse.Controls
{

	public interface ISourceReceiver
	{
		string Source { get; set; }
	}

	public interface IWebView : IProgress, IBaseNavigation, ISourceReceiver
	{
		void Eval(string js, Action<string> resultHandler);
		void Eval(string js);
		string BaseUrl { get; set; }
		string Url { get; set; }
		string DocumentTitle { get; }
		event EventHandler PageLoaded;
		event EventHandler BeginLoading;
		event EventHandler UrlChanged;
		event EventHandler URISchemeHandler;
		void LoadHtml(string html);
		void LoadHtml(string html, string baseUrl);
		void LoadUrl(string url);
		void Stop();
		void Reload();
		FileSource File { get; set; }
		bool ZoomEnabled { get; set; }
		bool ScrollEnabled { get; set; }
	}

	/**
		`<HTML/>` is a semantic utility node used to feed a @WebView component or a @LoadHtml action with raw HTML:

		```XML
		<NativeViewHost>
			<WebView>
				<HTML>
					<![CDATA[
						<h1>Boom!</h1>
					]]>
				</HTML>
			</WebView>
		</NativeViewHost>

		<LoadHtml>
			<HTML>
				<![CDATA[
					<h1>Bang!</h1>
				]]>
			</HTML>
		</LoadHtml>
		```
	*/
	public sealed class HTML : Uno.UX.PropertyObject
	{
		internal ISourceReceiver Receiver;

		[UXContent]
		public string Source
		{
			get
			{
				return Receiver.Source;
			}
			set
			{
				Receiver.Source = value;
			}
		}
	}

	/**
		Displays web content natively on android and iOS.
		
		As the WebView is native only, it needs to be contained in a @NativeViewHost.

		The WebView can be used to present web content either over the http protocol or by loading HTML as a string, and hooks into some useful triggers for building a customized browsing experience, such as @PageBeginLoading, @WhilePageLoading and @PageLoaded.
		Navigation triggers like @GoBack and @GoForward are complemented with WebView-specific ones, like @Reload, @LoadUrl and @LoadHtml. It can also be used to drive a @ProgressAnimation.

		The @EvaluateJS trigger is noteworthy, since it allows arbitrary JavaScript to be run in the WebView's context and the resulting data be fed back into Fuse:

		```XML
		<App Background="#333">
			<JavaScript>
					module.exports = {
						onPageLoaded : function(res) {
							console.log("WebView arrived at "+ JSON.parse(res.json).url);
					}
				};
			</JavaScript>
			<DockPanel>
				<StatusBarBackground Dock="Top"/>
				<NativeViewHost>
					<WebView Dock="Fill" Url="http://www.google.com">
						<PageLoaded>
							<EvaluateJS Handler="{onPageLoaded}">
								var result = {
									url : document.location.href
								};
								return result;
							</EvaluateJS>
						</PageLoaded>
					</WebView>
				</NativeViewHost>

				<BottomBarBackground Dock="Bottom" />
			</DockPanel>
		</App>
		```

		WebViews can also be fed raw HTML to display by wrapping an @HTML node or via the @LoadHtml trigger action:

		`<LoadHtml TargetNode="myWebView" BaseUrl="http://my.domain" Source="{html}"/>`
	*/
	public partial class WebView : Panel, IWebView
	{

		
		static string PreprocUriScheme(string inScheme)
		{
			return inScheme.Contains(":") ? inScheme : (inScheme + ":");
		}
		
		protected override Fuse.Controls.Native.IView CreateNativeView()
		{
			if defined(Android || iOS)
			{
				string scheme = @(Project.Mobile.UriScheme);
				scheme = PreprocUriScheme(scheme);
				string[] schemes = scheme!="" ? new string[]{scheme} :  new string[]{};

				if defined(Android)
					return Fuse.Android.Controls.WebView.Create(this, schemes);
				else if defined(iOS)
					return Fuse.iOS.Controls.WebView.Create(this, schemes);
				else
					build_error;
			}

			return base.CreateNativeView();
		}

		public double Progress
		{
			get { return WebViewClient.Progress; }
		}

		public event ValueChangedHandler<double> ProgressChanged;
		/**
			Callback that fires when the page has completed loading
		*/
		public event EventHandler PageLoaded;
		/**
			Callback that fires when a new page begins loading
		*/
		public event EventHandler BeginLoading;
		/**
			Callback that fires when the current url is changed
		*/
		public event EventHandler UrlChanged;
		/**
			Callback that fires if a URL request matching the app's UriScheme is made
		*/
		public event EventHandler URISchemeHandler;


		HTML _html;

		[UXContent]
		public HTML HTMLSource
		{
			get
			{
				return _html;
			}
			set {
				_html = value;
				_html.Receiver = this;
			}
		}

		public WebView()
		{
			ClipToBounds = true;

			if defined(!MOBILE)
			{
				Background = new Fuse.Drawing.SolidColor(float4(0.6f,0.6f,0.6f,1.0f));
				var t = new Fuse.Controls.Text();
				t.Alignment = Alignment.Center;
				t.SetValue("WebView requires a mobile target.", this);
				t.TextAlignment = TextAlignment.Center;
				Children.Add(t);
			}
			WebViewClient = _fallbackClient;
		}

		protected override void OnRooted()
		{
			base.OnRooted();
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
		}

		readonly IWebView _fallbackClient = new FallbackWebViewClient();

		IWebView _webViewClient;
		public IWebView WebViewClient
		{
			get { return _webViewClient ?? _fallbackClient; }
			set
			{
				string url = "about:blank";
				string source = "";
				string baseUrl = null;
				bool zoomEnabled = true;
				bool scrollEnabled = true;
				FileSource file = null;

				if (_webViewClient != null)
				{
					_webViewClient.ProgressChanged -= OnProgressChanged;
					_webViewClient.PageLoaded -= OnPageLoaded;
					_webViewClient.BeginLoading -= OnBeginLoading;
					_webViewClient.UrlChanged -= OnPageChanged;
					_webViewClient.URISchemeHandler -= URISchemeHandler;

					url = _webViewClient.Url;
					source = _webViewClient.Source ?? "";
					baseUrl = _webViewClient.BaseUrl;
					file = _webViewClient.File;
					zoomEnabled = _webViewClient.ZoomEnabled;
					scrollEnabled = _webViewClient.ScrollEnabled;
				}

				_webViewClient = value ?? _fallbackClient;

				if (_webViewClient != null)
				{
					_webViewClient.ProgressChanged += OnProgressChanged;
					_webViewClient.PageLoaded += OnPageLoaded;
					_webViewClient.BeginLoading += OnBeginLoading;
					_webViewClient.UrlChanged += OnPageChanged;
					_webViewClient.URISchemeHandler += URISchemeHandler;

					_webViewClient.BaseUrl = baseUrl;
					_webViewClient.Source = source;
					_webViewClient.ZoomEnabled = zoomEnabled;
					_webViewClient.ScrollEnabled = scrollEnabled;

					if(source == "")
					{
						_webViewClient.Url = url;
					}
					_webViewClient.File = file;

					applyFallbackCalls(_webViewClient);
				}
			}
		}
		
		/**
			Determines if pinch-to-zoom gestures are available in the WebView.
			Defaults to 'true'
		*/
		public bool ZoomEnabled { 
			set { 
				if(WebViewClient != _fallbackClient){
					debug_log("ZoomEnabled cannot be changed once rooted");
					return;
				} 
				WebViewClient.ZoomEnabled = value; 
			} 
			get { return WebViewClient.ZoomEnabled; } 
		}

		/**
			Determines if scrolling gestures are available in the WebView.
			Defaults to 'true'
		*/
		public bool ScrollEnabled { 
			set { 
				if(WebViewClient != _fallbackClient){
					debug_log("ScrollEnabled cannot be changed once rooted");
					return;
				} 
				WebViewClient.ScrollEnabled = value; 
			} 
			get { return WebViewClient.ScrollEnabled; } 
		}

		void applyFallbackCalls(IWebView client)
		{
			FallbackWebViewClient fbc = _fallbackClient as FallbackWebViewClient;
			fbc.ApplyBufferedCalls(client);
		}

		void OnPageChanged(object sender, EventArgs args)
		{
			UpdateRestState();
			if (UrlChanged != null)
				UrlChanged(this, EventArgs.Empty);
		}

		void OnBeginLoading(object sender, EventArgs args)
		{
			if (BeginLoading != null)
				BeginLoading(this, EventArgs.Empty);
		}

		void OnProgressChanged(object sender, EventArgs args)
		{
			if (ProgressChanged != null)
				ProgressChanged(this, new ValueChangedArgs<double>(Progress));
		}

		void OnPageLoaded(object sender, EventArgs args)
		{
			if (PageLoaded != null)
				PageLoaded(this, EventArgs.Empty);
		}

		public string DocumentTitle
		{
			get { return WebViewClient.DocumentTitle; }
		}

		public void LoadHtml(string html, string baseUrl)
		{
			WebViewClient.LoadHtml(html ?? "", baseUrl);
		}
		public void LoadHtml(string html)
		{
			WebViewClient.LoadHtml(html ?? "");
		}
		
		/**
			When loading HTML from source; The base URL serving as scope for the HTML.
		*/
		public string BaseUrl
		{
			get { return WebViewClient.BaseUrl; }
			set { WebViewClient.BaseUrl = value ?? ""; }
		}
		
		/**
			The HTML source code to display.
		*/
		public string Source
		{
			get { return WebViewClient.Source; }
			set { WebViewClient.Source = value ?? ""; }
		}

		internal void UpdateRestState()
		{
			OnPropertyChanged(_urlName, this);
			OnHistoryChanged();
		}

		static Selector _urlName = "Url";

		public void SetUrl(string value, IPropertyListener origin)
		{
			OnPropertyChanged(_urlName, origin);
			WebViewClient.Url = value;
			UpdateRestState();
		}

		[UXOriginSetter("SetUrl")]
		/**
			The URL from which to load content
		*/
		public string Url
		{
			get { return WebViewClient.Url; }
			set { SetUrl(value ?? "about:blank", this); }
		}
		
		/**
			The File from which to load HTML
		*/
		public FileSource File
		{
			get { return WebViewClient.File; }
			set { WebViewClient.File = value; }
		}

		public bool CanGoBack
		{
			get { return WebViewClient.CanGoBack; }
		}

		public bool CanGoForward
		{
			get { return WebViewClient.CanGoForward; }
		}

		public void Eval(string js)
		{
			WebViewClient.Eval(js ?? "");
		}

		public void Eval(string js, Action<string> resultHandler)
		{
			WebViewClient.Eval(js ?? "", resultHandler);
		}

		public void GoBack()
		{
			WebViewClient.GoBack();
		}

		public void GoForward()
		{
			WebViewClient.GoForward();
		}

		public void Reload()
		{
			WebViewClient.Reload();
		}

		public void Stop()
		{
			WebViewClient.Stop();
		}

		public void LoadUrl(string url)
		{
			WebViewClient.LoadUrl(url ?? "about:blank");
		}

		public event HistoryChangedHandler HistoryChanged;

		protected void OnHistoryChanged()
		{
			if (HistoryChanged != null)
				HistoryChanged(this);
		}
	}

	internal interface BufferedWebViewCall
	{
		void Apply(IWebView wv);
	}

	internal class LoadHtmlCall : BufferedWebViewCall
	{
		readonly string html;
		readonly string baseUrl;
		public LoadHtmlCall(string html, string baseUrl)
		{
			this.html = html;
			this.baseUrl = baseUrl;
		}
		public void Apply(IWebView wv)
		{
			wv.LoadHtml(html,baseUrl);
		}
	}

	internal class JavaScriptCall : BufferedWebViewCall
	{
		public readonly Action<string> Handler;
		public readonly string Script;

		public JavaScriptCall(string script, Action<string> handler)
		{
			Script = script;
			Handler = handler;
		}

		public void Apply(IWebView wv)
		{
			if (Handler != null)
			{
				wv.Eval(Script, Handler);
			}
			else
			{
				wv.Eval(Script);
			}
		}

	}

	internal class FallbackWebViewClient : IWebView
	{
		public FileSource File { get; set; }

		List<BufferedWebViewCall> _bufferedCalls;

		public FallbackWebViewClient()
		{
			_bufferedCalls = new List<BufferedWebViewCall>();
			ZoomEnabled = true;
			ScrollEnabled = true;
		}

		public void ApplyBufferedCalls(IWebView wv)
		{
			while(_bufferedCalls.Count > 0)
			{
				var call = _bufferedCalls[0];
				call.Apply(wv);
				_bufferedCalls.Remove(call);
			}
		}

		public string Source { get; set; }
		public string BaseUrl { get; set; }
		public string Url { get; set; }
		public bool CanGoBack { get { return false; } }
		public bool CanGoForward { get { return false; } }
		public string DocumentTitle { get { return ""; } }
		public event HistoryChangedHandler HistoryChanged;
		public void GoBack() { }
		public void GoForward() { }
		public void Reload() { }
		public void Stop() { }
		public void Eval(string js)
		{
			_bufferedCalls.Add(new JavaScriptCall(js, null));
		}
		public void Eval(string js, Action<string> resultHandler)
		{
			_bufferedCalls.Add(new JavaScriptCall(js, resultHandler));
		}
		public void LoadUrl(string url) { }
		public void LoadHtml(string html)
		{
			LoadHtml(html, "");
		}
		public void LoadHtml(string html, string baseUrl)
		{
			_bufferedCalls.Add(new LoadHtmlCall(html,baseUrl));
		}
		public event ValueChangedHandler<double> ProgressChanged;
		public event EventHandler PageLoaded;
		public event EventHandler BeginLoading;
		public event EventHandler UrlChanged;
		public event EventHandler URISchemeHandler;
		public double Progress { get { return 0.0; } }
		public bool ZoomEnabled { get; set; }
		public bool ScrollEnabled { get; set; }
	}

}
