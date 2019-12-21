#import "MapViewDelegate.h"
#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395
@implementation TouchRecognizer
	@synthesize touchesBeganCallback;
	@synthesize touchesEndedCallback;
	@synthesize touchesCancelledCallback;

	-(id) init
	{
		if (self = [super init])
			self.cancelsTouchesInView = NO;

		return self;
	}

	-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
	{
		if (touchesBeganCallback)
			touchesBeganCallback(touches, event);
	}

	-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
	{
		if (touchesEndedCallback)
			touchesEndedCallback(touches, event);
	}

	-(BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
	{
		return NO;
	}

	-(BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
	{
		return NO;
	}

	- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event { }
	- (void)reset { }
	- (void)ignoreTouch:(UITouch *)touch forEvent:(UIEvent *)event { }
	- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
	{
		if (touchesCancelledCallback)
			touchesCancelledCallback(touches, event);
	}

@end

@interface FusePinAnnotation : MKPointAnnotation
	@property(copy) NSString* icon;
	@property float iconX;
	@property float iconY;
	@property int markerID;
@end

@implementation FusePinAnnotation
@end

@implementation MapViewDelegate
{
	MKMapView* _mapView;
	NSMutableDictionary* _annotations;
	CLLocationManager* _locationMgr;
	int _touchCount;
}

	@synthesize mapMoveBlock;
	@synthesize markerSelectBlock;
	@synthesize touchBlock;
	@synthesize authChangeBlock;

	static int _idPool = 0;

	-(id)init
	{
		self = [super init];
		_touchCount = 0;
		_locationMgr = [[CLLocationManager alloc] init];
		[_locationMgr setDelegate:self];
		_annotations = [[NSMutableDictionary alloc] init];
		return self;
	}

	-(BOOL)authorized
	{
		CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
		switch(status){
			case kCLAuthorizationStatusAuthorizedWhenInUse:
			case kCLAuthorizationStatusAuthorizedAlways:
				return true;
			default:
				return false;
		}
	}
	
	-(void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status 
	{
			if(authChangeBlock!=nil)
				authChangeBlock([self authorized]);
		}

	-(void)requestLocationAuthentication:(void(^)(bool))onRequestResult
	{
		if([self authorized]){
			if(onRequestResult!=nil)
				onRequestResult(true);
		}else{
			authChangeBlock = onRequestResult;
			[_locationMgr requestAlwaysAuthorization];
		}
	}

	-(void)setAsDelegate:(MKMapView*)mv
	{
		_mapView = mv;
		[_mapView setDelegate:self];

		TouchRecognizer* _touchRecognizer = [[TouchRecognizer alloc] init];

		_touchRecognizer.touchesBeganCallback = ^(NSSet * touches, UIEvent * event)
		{
			self->_touchCount += [touches count];
			if(self.touchBlock == nil) return;

			UITouch* t = [touches anyObject];
			CGPoint l = [t locationInView:self->_mapView];

			CLLocationCoordinate2D coord = [self->_mapView convertPoint:l toCoordinateFromView:self->_mapView];

			self->touchBlock(0, coord.latitude, coord.longitude);
		};

		_touchRecognizer.touchesEndedCallback = ^(NSSet * touches, UIEvent * event)
		{
			self->_touchCount -= [touches count];
			if(self->touchBlock == nil) return;

			UITouch* t = [touches anyObject];
			CGPoint l = [t locationInView:self->_mapView];

			CLLocationCoordinate2D coord = [self->_mapView convertPoint:l toCoordinateFromView:self->_mapView];

			self->touchBlock(1, coord.latitude, coord.longitude);

			if(self->_touchCount==0)
				self->touchBlock(4, coord.latitude, coord.longitude);
		};

		_touchRecognizer.touchesCancelledCallback = ^(NSSet * touches, UIEvent * event)
		{
			self->_touchCount -= [touches count];
			if(self->touchBlock == nil) return;
			if(self->_touchCount==0)
				self->touchBlock(4, 0, 0);
		};

		UITapGestureRecognizer* _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
		UILongPressGestureRecognizer* _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];

		[mv addGestureRecognizer:_touchRecognizer];
		[mv addGestureRecognizer:_tapRecognizer];
		[mv addGestureRecognizer:_longPressRecognizer];
	}

	-(int)nextId
	{
		return _idPool++;
	}

	-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
	{
		id annotation = view.annotation;
        	if (![annotation isKindOfClass:[MKUserLocation class]]) {
			if(markerSelectBlock){
				FusePinAnnotation* a = (FusePinAnnotation*)[view annotation];
				markerSelectBlock(a.markerID, a.title);
			}
		}
	}

	-(int)addMarker:(NSString*)label 
		latitude:(double)lat 
		longitude:(double)lng
		icon:(NSString*)iconPath
		iconX:(float)iconX
		iconY:(float)iconY
		markerID:(int)markerID
	{
		FusePinAnnotation* a = [[FusePinAnnotation alloc] init];
		a.coordinate = CLLocationCoordinate2DMake(lat,lng);
		a.title = label;
		a.icon = iconPath;
		a.iconX = iconX;
		a.iconY = iconY;
		a.markerID = markerID;
		[_mapView addAnnotation:a];
		[self nextId];
		[_annotations setObject:a forKey:\@(_idPool)];
		return _idPool;
	}

	-(void)removeMarker:(int)identifier
	{
		FusePinAnnotation* a = [_annotations objectForKey:\@(identifier)];
		if(a==nil) return;
		[_mapView removeAnnotation:a];
		[_annotations removeObjectForKey:\@(identifier)];
	}

	-(void) clearMarkers
	{
		for(id key in _annotations)
		{
			FusePinAnnotation* a = [_annotations objectForKey:key];
			if(a==nil) continue;
			[_mapView removeAnnotation:a];
		}
		[_annotations removeAllObjects];
	}

	-(void)onTap:(UITapGestureRecognizer*)sender
	{
		if(sender.state == UIGestureRecognizerStateEnded && touchBlock != nil)
		{
			CGPoint l = [sender locationInView:_mapView];
			CLLocationCoordinate2D coord = [_mapView convertPoint:l toCoordinateFromView:_mapView];

			touchBlock(2, coord.latitude, coord.longitude);
		}
	}

	-(void)onLongPress:(UILongPressGestureRecognizer *)sender
	{
		if(touchBlock == nil) return;
		if (sender.state == UIGestureRecognizerStateBegan)
		{
			CGPoint l = [sender locationInView:_mapView];
			CLLocationCoordinate2D coord = [_mapView convertPoint:l toCoordinateFromView:_mapView];
			touchBlock(3, coord.latitude, coord.longitude);
		}
	}

	-(void)setMarkerSelectAction:(void(^)(int, NSString*))action
	{
		id previous = markerSelectBlock;
		markerSelectBlock = action;
	}

	-(void)setMapTouchAction:(void(^)(int type, double x, double y))action
	{
		id previous = touchBlock;
		touchBlock = action;
	}

	-(void)setMapMoveAction:(void(^)(bool))action
	{
		id previous = mapMoveBlock;
		mapMoveBlock = action;
	}

	- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
	{
		if(mapMoveBlock)
			mapMoveBlock(animated);
	}

	//Zoom nightmare begins here

	-(double)longitudeToPixelSpaceX:(double)longitude
	{
		return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
	}

	-(double)latitudeToPixelSpaceY:(double)latitude
	{
		return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
	}

	-(double)pixelSpaceXToLongitude:(double)pixelX
	{
		return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
	}

	-(double)pixelSpaceYToLatitude:(double)pixelY
	{
		return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
	}
	-(MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
	{
		if ([annotation isKindOfClass:[MKUserLocation class]])
            		return nil;  //return nil to use default blue dot view
        
		static NSString *SFAnnotationIdentifier = @"SFAnnotationIdentifier";
		NSString* identifier = SFAnnotationIdentifier;
		
		FusePinAnnotation* fuseAnnotation = (FusePinAnnotation*)annotation;
		
		// make sure the annotation passed in is a fuse pin
		// if it's not, then we want to use the default identifier
		if ([annotation isKindOfClass:[FusePinAnnotation class]])
			fuseAnnotation = nil;
		
		// ensure that the annotation actually has an icon selector
		if(fuseAnnotation!=nil && [fuseAnnotation respondsToSelector:@selector(icon)])
			identifier = fuseAnnotation.icon;
			
		MKPinAnnotationView *pinView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:identifier];
		if (!pinView)
		{
			// HACK:
			//
			// When using this MapView at the same time as FuseJS/GeoLocation we sporadically receive an
			// annotation of type MKUserLocation. Therefore we can't assume that annotation is of type
			// FusePinAnnotation.
			//
			// It seems likely there's some other bug that makes this happen, so consider this a workaround,
			// although checking the type here is probably a good idea anyway.
			if (![annotation isKindOfClass:[FusePinAnnotation class]])
				return nil;

			FusePinAnnotation* a = (FusePinAnnotation*)annotation;
			if(a.icon == nil) return nil;
			MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
				reuseIdentifier:a.icon];
			UIImage* image = [UIImage imageWithContentsOfFile:a.icon];
			
			double ratio = image.size.width / 32.0; //32 is the width of the standard pin view
			
			UIImage *scaledImage = 
				[UIImage imageWithCGImage:[image CGImage] scale:ratio orientation:image.imageOrientation];
			
			annotationView.canShowCallout = YES;
			annotationView.image = scaledImage;
			annotationView.centerOffset = CGPointMake(annotationView.frame.size.width*(a.iconX-0.5), -annotationView.frame.size.height*(a.iconY-0.5));
			return annotationView;
		}
		else
		{
			pinView.annotation = annotation;
		}
		return pinView;
	}

	-(MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)mapView centerCoordinate:(CLLocationCoordinate2D)centerCoordinate andZoomLevel:(NSUInteger)zoomLevel
	{
		// convert center coordiate to pixel space
		double centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
		double centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];

		// determine the scale value from the zoom level
		NSInteger zoomExponent = log2(MKMapSizeWorld.width / 256) - zoomLevel;
		double zoomScale = pow(2, zoomExponent);

		// scale the map’s size in pixel space
		CGSize mapSizeInPixels = mapView.bounds.size;
		double scaledMapWidth = mapSizeInPixels.width * zoomScale;
		double scaledMapHeight = mapSizeInPixels.height * zoomScale;

		// figure out the position of the top-left pixel
		double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
		double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);

		// find delta between left and right longitudes
		CLLocationDegrees minLng = [self pixelSpaceXToLongitude:topLeftPixelX];
		CLLocationDegrees maxLng = [self pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
		CLLocationDegrees longitudeDelta = maxLng - minLng;

		// find delta between top and bottom latitudes
		CLLocationDegrees minLat = [self pixelSpaceYToLatitude:topLeftPixelY];
		CLLocationDegrees maxLat = [self pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
		CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);

		// create and return the lat/lng span
		MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
		return span;
	}

-(void)moveTo:(double)lat longitude:(double)lng zoom:(double)z tilt:(double)t orientation:(double)o
	{
		z = MAX(2.0, MIN(z, 21));
		CLLocationCoordinate2D newCenter = CLLocationCoordinate2DMake(lat, lng);
		MKCoordinateSpan span = [self coordinateSpanWithMapView:_mapView centerCoordinate:newCenter andZoomLevel:z];
	[_mapView setRegion:MKCoordinateRegionMake(newCenter, span)];
	}

	-(double)getZoomLevel
	{
		CLLocationDegrees longitudeDelta = _mapView.region.span.longitudeDelta;
		double density = [[UIScreen mainScreen] scale];
		CGFloat mapWidthInPixels = _mapView.bounds.size.width * density;
		double zoomScale = longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * mapWidthInPixels);
		double zoomer = log2(MKMapSizeWorld.width / 256) - log2(zoomScale);
		if ( zoomer < 0.0 ) zoomer = 0.0;

		return zoomer-(0.5/750)*mapWidthInPixels;
	}

@end
