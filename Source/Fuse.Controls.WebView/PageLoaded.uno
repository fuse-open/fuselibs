using Fuse.Controls;
namespace Fuse.Triggers
{
	/**
		Triggers when a @WebView finishes loading a page

		## Example

		This example will blink the blue background green when the page finishes
		loading:

			<Panel ux:Name="panel" Color="Blue">
				<NativeViewHost Height="50%">
					<WebView Url="http://interwebs.com">
						<PageLoaded>
							<Change DurationBack="0.5" panel.Color="Green" />
						</PageLoaded>
					</WebView>
				</NativeViewHost>
			</Panel>
	*/
	public class PageLoaded : Trigger
	{
		IWebView _webView;

		protected override void OnRooted()
		{
			base.OnRooted();
			if (Parent is IWebView)
			{
				_webView = Parent as IWebView;
				_webView.PageLoaded += OnPageLoaded;
			}
			else
			{
				Diagnostics.UserRootError( "WebView", Parent, this );
			}
		}

		void OnPageLoaded(object s, object a)
		{
			Pulse();
		}

		protected override void OnUnrooted()
		{
			if (_webView != null)
			{
				_webView.PageLoaded -= OnPageLoaded;
				_webView = null;
			}
			base.OnUnrooted();
		}
	}
}
