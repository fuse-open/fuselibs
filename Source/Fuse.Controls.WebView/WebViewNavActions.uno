using Uno;
using Uno.UX;
using Fuse.Controls;
using Fuse.Scripting;

namespace Fuse.Triggers.Actions
{

	public abstract class WebViewNavAction : TriggerAction
	{
		internal WebViewNavAction() {}

		protected override void Perform(Node target)
		{
			var webView = target.FindByType<WebView>();
			if (webView != null)
				Execute(webView);
		}

		abstract void Execute(WebView webview);

	}

	/**
		@mount UI Components / WebView
		Reloads the currently loaded URL
	*/
	public sealed class Reload : WebViewNavAction
	{
		override void Execute(WebView webview)
		{
			webview.Reload();
		}
	}

	/**
		@mount UI Components / WebView
		Stops loading the currently loading URL
	*/
	public sealed class StopLoading : WebViewNavAction
	{
		override void Execute(WebView webview)
		{
			webview.Stop();
		}
	}

	/**
		@mount UI Components / WebView
		Loads a new URL into the WebView
	*/
	public sealed class LoadUrl : WebViewNavAction
	{
		[UXContent]
		public string Url { get; set; }

		override void Execute(WebView webview)
		{
			if(Url != "")
			{
				webview.LoadUrl(Url);
			}
		}
	}

	/**
		@mount UI Components / WebView
		Load arbitrary HTML into the webview.

		```HTML
		<WebView ux:Name="webview"/>
		<Button>
			<Clicked>
				<LoadHtml TargetNode="webview">
					<HTML>
						<![CDATA[
							<h1>Hello world!</h1>
						]]>
					</HTML>
				</LoadHtml>
			</Clicked
		</Button>
		```
		
		You may optionally specify a base URL to use when resolving relative links and enforcing JavaScript's
		[same origin policy](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy).
		
			<LoadHtml BaseUrl="https://example.com/">
				<HTML>
					...
				</HTML>
			</LoadHtml>
	*/
	public sealed class LoadHtml : WebViewNavAction, ISourceReceiver
	{
		HTML _html;

		public string Source { get; set; }

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

		/**
			The base URL used to resolve relative links and enforce JavaScript's
			[same origin policy](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy).
		*/
		public string BaseUrl { get; set; }

		override void Execute(WebView webview)
		{
			if(Source != "")
			{
				webview.LoadHtml(Source, BaseUrl);
			}
		}
	}
}
