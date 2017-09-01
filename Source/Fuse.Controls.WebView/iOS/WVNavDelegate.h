#import <WebKit/WebKit.h>
typedef void (^Action)(void);
typedef void (^StringAction)(NSString*);
typedef bool (^BoolFunc)(void);
@interface WVNavDelegate : NSObject<WKNavigationDelegate>
@property(copy) Action onURLChanged;
@property(copy) Action onPageLoaded;
@property(copy) Action onBeginLoading;
@property(copy) StringAction onCustomURI;
@property(copy) BoolFunc hasURISchemeHandler;
@property (nonatomic, retain) NSArray* uriSchemes;
-(id)initWithEventHandlers:(Action)beginLoading 
  loaded:(Action)pageLoaded 
  change:(Action)urlChanged
  uriHandler:(StringAction)uriHandler
  schemes:(NSArray*)schemes
  hasURISchemeHandler:(BoolFunc)hasURISchemeHandler;
@end
