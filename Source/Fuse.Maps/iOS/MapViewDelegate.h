#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^TouchesEventBlock)(NSSet * touches, UIEvent * event);

@interface TouchRecognizer : UIGestureRecognizer
	{
	    TouchesEventBlock touchesBeganCallback;
	}
	@property(copy) TouchesEventBlock touchesBeganCallback;
	@property(copy) TouchesEventBlock touchesEndedCallback;
	@property(copy) TouchesEventBlock touchesCancelledCallback;

@end

@interface MapViewDelegate : NSObject<MKMapViewDelegate, CLLocationManagerDelegate>
	-(void)setAsDelegate:(MKMapView*)mv;
	-(double)getZoomLevel;
	-(void)setMapMoveAction:(void(^)(bool))action;
	-(void)setMapTouchAction:(void(^)(int, double, double))action;
	-(void)setMarkerSelectAction:(void(^)(int, NSString*))action;
	-(int)addMarker:(NSString*)label 
	latitude:(double)lat 
	longitude:(double)lng
	icon:(NSString*)iconPath
	iconX:(float)iconX
	iconY:(float)iconY
	markerID:(int)markerID;
	-(BOOL)authorized;
	-(void)removeMarker:(int)identifier;
	-(void)clearMarkers;
	-(void)requestLocationAuthentication:(void(^)(bool))onRequestResult;
	-(void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
	-(void)moveTo:(double)lat longitude:(double)l zoom:(double)z tilt:(double)t orientation:(double)o;
	@property (nonatomic, strong) void (^mapMoveBlock)(bool);
	@property (nonatomic, strong) void (^touchBlock)(int type, double x, double y);
	@property (nonatomic, strong) void (^markerSelectBlock)(int id, NSString* label);
	@property (nonatomic, strong) void (^authChangeBlock)(bool authorized);
@end
