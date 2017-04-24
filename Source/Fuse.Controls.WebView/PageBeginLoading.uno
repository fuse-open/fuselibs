using Fuse.Controls;
namespace Fuse.Triggers
{
	/**
		Triggers when a @WebView begins loading a page

		## Example

		This example will blink the blue background red when the page begins
		loading:

			<Panel ux:Name="panel" Color="Blue">
				<NativeViewHost Height="50%">
					<WebView Url="http://interwebs.com">
						<PageBeginLoading>
							<Change DurationBack="0.5" panel.Color="Red" />
						</PageBeginLoading>
					</WebView>
				</NativeViewHost>
			</Panel>
	*/
	public class PageBeginLoading : Trigger
	{
		IWebView _webView;

		protected override void OnRooted()
		{
			base.OnRooted();
			if (Parent is IWebView)
			{
				_webView = Parent as IWebView;
				_webView.BeginLoading += OnPageBeginLoading;
			}
			else
			{
				Diagnostics.UserRootError( "WebView", Parent, this );
			}
		}

		void OnPageBeginLoading(object s, object a)
		{
			Pulse();
		}

		protected override void OnUnrooted()
		{
			if (_webView != null)
			{
				_webView.BeginLoading -= OnPageBeginLoading;
				_webView = null;
			}
			base.OnUnrooted();
		}
	}
}
