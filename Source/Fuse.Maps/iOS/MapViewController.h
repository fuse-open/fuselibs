#import <MapKit/MapKit.h>
typedef void (^Action)(void);
@interface MapViewController : UIViewController
@property(copy) Action onAppearedCallback;
@property(copy) Action onResizeCallback;
-(id)initWithView:(id)view onAppeared:(Action)appearedHandler onResize:(Action)resizeHandler;
@end
