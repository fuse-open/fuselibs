using Uno;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Fuse;
using Fuse.Navigation;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Android.Controls.WebViewUtils
{
	[ForeignInclude(Language.Java, "com.fuse.webview.JsInterface", "com.fuse.webview.FuseWebViewClient", "com.fuse.webview.FuseWebChromeClient", "android.util.Log", "android.webkit.WebView", "com.fuse.webview.ScrollableWebView")]
	public static class WebViewForeign
	{
		[Foreign(Language.Java)]
		public extern (Android) static Java.Object CreateWebView(bool zoomEnabled, bool scrollEnabled)
		@{
			ScrollableWebView wv = new ScrollableWebView(com.fuse.Activity.getRootActivity());
			wv.getSettings().setJavaScriptEnabled(true);
			wv.getSettings().setUseWideViewPort(true); //enabled viewport meta tag
			wv.getSettings().setLoadWithOverviewMode(true); //mimic iOS Safari and Android Chrome
			wv.getSettings().setSupportZoom(zoomEnabled);
			wv.getSettings().setBuiltInZoomControls(zoomEnabled);
			wv.getSettings().setDomStorageEnabled(true);
			wv.setAllowScroll(scrollEnabled);

			return wv;
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static void AddJavascriptInterface(this Java.Object handle, string name, Action<string> resultHandler)
		@{
				WebView wv = (WebView)handle;
				JsInterface jsi = new JsInterface(resultHandler);
				wv.addJavascriptInterface(jsi, name);
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static Java.Object CreateAndSetWebChromeClient(this Java.Object webViewHandle, Action<int> onProgress)
		@{
			FuseWebChromeClient client = new FuseWebChromeClient(onProgress);
			((WebView)webViewHandle).setWebChromeClient(client);
			return client;
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static Java.Object CreateAndSetWebViewClient(this Java.Object webViewHandle, Action loaded, Action started, Action changed, Action<string> onCustomURI, string[] customURIs, Func<bool> hasUriSchemeHandler)
		@{
			FuseWebViewClient client = new FuseWebViewClient(loaded, started, changed, onCustomURI, customURIs, hasUriSchemeHandler);
			((WebView)webViewHandle).setWebViewClient(client);
			return client;
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static string GetUrl(this Java.Object handle)
		@{
			WebView wv = (WebView)handle;
			return wv.getUrl();
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static string GetTitle(this Java.Object handle)
		@{
			WebView wv = (WebView)handle;
			return wv.getTitle();
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static bool CanGoBack(this Java.Object handle)
		@{
			WebView wv = (WebView)handle;
			return wv.canGoBack();
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static bool CanGoForward(this Java.Object handle)
		@{
			WebView wv = (WebView)handle;
			return wv.canGoForward();
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static void GoBack(this Java.Object handle)
		@{
			WebView wv = (WebView)handle;
			wv.goBack();
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static void GoForward(this Java.Object handle)
		@{
			WebView wv = (WebView)handle;
			wv.goForward();
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static void Reload(this Java.Object handle)
		@{
			WebView wv = (WebView)handle;
			wv.reload();
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static void StopLoading(this Java.Object handle)
		@{
			WebView wv = (WebView)handle;
			wv.stopLoading();
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static void LoadHtml(this Java.Object handle, string html, string baseUrl)
		@{
			WebView wv = (WebView)handle;
			wv.loadDataWithBaseURL(baseUrl, html, "text/html", "UTF-8", null);
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static void LoadUrl(this Java.Object handle, string url)
		@{
			WebView wv = (WebView)handle;
			wv.loadUrl(url);
		@}
		
		[Foreign(Language.Java)]
		public extern (Android) static double GetProgress(this Java.Object handle)
		@{
				WebView wv = (WebView)handle;
				return wv.getProgress();
		@}
		
	}

}
