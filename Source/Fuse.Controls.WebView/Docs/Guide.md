The WebView can be used to pull and display content from the web or even just from HTML from a string.

It hooks into some useful triggers for building a customized browsing experience, such as `PageBeginLoading`, `WhilePageLoading` and `PageLoaded`. Navigation triggers like `GoBack` and `GoForward` are complemented with WebView-specific ones, like `Reload`, `LoadUrl` and `LoadHtml`. It can also be used to feed a `ProgressAnimation`.

The WebView is a native Android and iOS element, and as such needs to be contained in a `NativeViewHost`.

Whilst you will naturally want to do most of your JS coding in Fuse the usual way, there are times you may want to evaluate JS in the WebView's context and the resulting data be fed back into Fuse. This is where the `EvaluateJS` comes in:

	<App>
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


## HTML
`<HTML/>` is a semantic utility node used to feed a `WebView` component or a `LoadHtml` action with raw HTML:


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
	

WebViews can also be fed raw HTML to display by wrapping an `HTML` node or via the `LoadHtml` trigger action:

	<LoadHtml TargetNode="myWebView" BaseUrl="http://my.domain" Source="{html}"/>

