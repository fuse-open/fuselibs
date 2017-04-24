#import "WVNavDelegate.h"
@implementation WVNavDelegate
-(id)initWithEventHandlers:(Action)beginLoading 
	loaded:(Action)pageLoaded 
	change:(Action)urlChanged
	uriHandler:(StringAction)uriHandler
	schemes:(NSArray*)schemes
{
	self = [super init];
	self.onBeginLoading = beginLoading;
	self.onPageLoaded = pageLoaded;
	self.onURLChanged = urlChanged;
	self.onCustomURI = uriHandler;
	self.uriSchemes = schemes;
	return self;
}

-(void) webView:(WKWebView*)webview 
	decidePolicyForNavigationAction:(WKNavigationAction*)navAction
	decisionHandler:(void(^)(WKNavigationActionPolicy))handler
{
	NSString* url = navAction.request.URL.absoluteString;
	for(NSString* str in self.uriSchemes)
	{
		if([url containsString:str])
		{
			handler(WKNavigationActionPolicyCancel);
			self.onCustomURI(url);
			return;
		}
	}
	handler(WKNavigationActionPolicyAllow);
}

-(void) webView:(WKWebView*)webview 
	didStartProvisionalNavigation:(WKNavigation*)navigation
{
	self.onBeginLoading();
}

-(void) webView:(WKWebView*)webview 
	didCommitNavigation:(WKNavigation*)navigation
{
	self.onBeginLoading();
}

-(void) webView:(WKWebView*)webview 
	didFinishNavigation:(WKNavigation*)navigation
{
	self.onURLChanged();
	self.onPageLoaded();
}
@end
