using Fuse.Controls;
using Fuse.Diagnostics;
namespace Fuse.Triggers
{
	/**
		A trigger that is active while its parent @WebView is loading.
		
		## Example
		
		The following example displays a loading indicator while the @WebView is loading a page.
		
			<NativeViewHost>
				<Panel ux:Name="loadingIndicator" Opacity="0" Alignment="Bottom" Color="#0006">
					<Text Alignment="Center" Margin="10" Color="#fff">Loading...</Text>
				</Panel>

				<WebView Url="https://example.com/">
					<WhilePageLoading>
						<Change loadingIndicator.Opacity="1" Duration="0.2" />
					</WhilePageLoading>
				</WebView>
			</NativeViewHost>
	*/
	public class WhilePageLoading : WhileTrigger
	{
		WebView _webView;

		protected override void OnRooted()
		{
			base.OnRooted();
			if (Parent is IWebView)
			{
				_webView = Parent as WebView;
				_webView.ProgressChanged += OnProgressChanged;
				SetActive(_webView.Progress != 1.0);
			}
			else
			{
				Diagnostics.UserRootError( "WebView", Parent, this );
			}
		}

		protected override void OnUnrooted()
		{
			if (_webView != null)
			{
				_webView.ProgressChanged -= OnProgressChanged;
				_webView = null;
			}
			base.OnUnrooted();
		}

		void OnProgressChanged(object s, object a)
		{
			SetActive(_webView.Progress < 1.0);
		}
	}
}
