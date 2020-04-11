using Uno;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Fuse;
using Fuse.Elements;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls;
using Fuse.Controls.Native.iOS;

namespace Fuse.Maps.iOS
{

	[Require("Source.Include", "MapKit/MapKit.h")]
	extern (iOS) internal class FuseMapView
	{
		public readonly ObjC.Object Handle;
		public readonly ObjC.Object Container;
		public FuseMapView()
		{
			Container = CreateContainer();
			Handle = CreateMap(Container);
		}

		[Foreign(Language.ObjC)]
		ObjC.Object CreateContainer()
		@{
			UIView* view = [[UIView alloc] init];
			return view;
		@}

		[Foreign(Language.ObjC)]
		ObjC.Object CreateMap(ObjC.Object container)
		@{
			MKMapView* mv = [[MKMapView alloc] init];
			UIView* mvc = container;
			mv.frame = mvc.bounds;
			mv.translatesAutoresizingMaskIntoConstraints = YES;
			mv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			[mvc addSubview:mv];
			return mv;
		@}

		[Foreign(Language.ObjC)]
		public bool GetBoolValue(string key)
		@{
			id result = [@{FuseMapView:Of(_this).Handle:Get()} valueForKey:key];
			return [result boolValue];
		@}

		[Foreign(Language.ObjC)]
		public string GetStringValue(string key)
		@{
			return [@{FuseMapView:Of(_this).Handle:Get()} valueForKey:key];
		@}

		[Foreign(Language.ObjC)]
		public void SetBoolValue(string key, bool val)
		@{
			[@{FuseMapView:Of(_this).Handle:Get()} setValue:[NSNumber numberWithBool:val] forKey:key];
		@}

		[Foreign(Language.ObjC)]
		public void SetIntValue(string key, int val)
		@{
			[@{FuseMapView:Of(_this).Handle:Get()} setValue:[NSNumber numberWithInt:val] forKey:key];
		@}

		[Foreign(Language.ObjC)]
		public double GetHeading()
		@{
			MKMapView* mv = @{FuseMapView:Of(_this).Handle:Get()};
			return mv.camera.heading;
		@}

		[Foreign(Language.ObjC)]
		public double GetPitch()
		@{
			MKMapView* mv = @{FuseMapView:Of(_this).Handle:Get()};
			return mv.camera.pitch;
		@}

		[Foreign(Language.ObjC)]
		public double GetLatitude()
		@{
			MKMapView* mv = @{FuseMapView:Of(_this).Handle:Get()};
			return mv.centerCoordinate.latitude;
		@}

		[Foreign(Language.ObjC)]
		public double GetLongitude()
		@{
			MKMapView* mv = @{FuseMapView:Of(_this).Handle:Get()};
			return mv.centerCoordinate.longitude;
		@}
	}

	[Require("Source.Include", "iOS/MapViewController.h")]
	extern (iOS) internal class MapViewContainer
	{

		public Action OnReady;
		public Action OnResize;
		public readonly FuseMapView Map;
		public readonly ObjC.Object Handle;
		public MapViewContainer(FuseMapView map)
		{
			Map = map;
			Handle = Create(Map.Container, viewDidAppear, viewDidResize);
		}

		[Foreign(Language.ObjC)]
		ObjC.Object Create(ObjC.Object view, Action onReady, Action onResize)
		@{
			return [[MapViewController alloc] initWithView:view onAppeared:onReady onResize:onResize];
		@}

		void viewDidAppear()
		{
			if(OnReady!=null)
				OnReady();
		}

		void viewDidResize()
		{
			if(OnResize!=null)
				OnResize();
		}

		[Foreign(Language.ObjC)]
		public ObjC.Object GetView()
		@{
			UIViewController* vc = @{MapViewContainer:Of(_this).Handle:Get()};
			return vc.view;
		@}
	}


	[Require("Source.Include", "iOS/MapViewDelegate.h")]
	extern (iOS) public class MapView : LeafView, Fuse.Controls.IMapView
	{

		public override void Dispose()
		{
			_mapViewHost.MapViewClient = null;
			_mapViewHost = null;
			base.Dispose();
		}

		MapViewContainer _container;
		FuseMapView _mapView;
		ObjC.Object _mapViewDelegate;

		Fuse.Controls.MapView _mapViewHost;
		MarkerIconCache _markerGraphicsCache;

		public static MapView Create(Fuse.Controls.MapView mapViewHost)
		{
			var v = new FuseMapView();
			var mvc = new MapViewContainer(v);
			return new MapView(mapViewHost, mvc);
		}
		MapView(Fuse.Controls.MapView mapViewHost, MapViewContainer mvc) : base(mvc.GetView())
		{
			_mapViewHost = mapViewHost;
			_container = mvc;
			//_container.OnReady = OnReadyInternal;
			_container.OnResize = OnReadyInternal;
			_mapView = _container.Map;
			_mapViewDelegate = Configure(_mapView.Handle, OnCameraMoved, OnMapTouch, HandleMarkerTapped);
			_mapViewHost.MapViewClient = this;
			_markerGraphicsCache = new MarkerIconCache(UpdateMarkers);
		}

		void Invalidate()
		{
			Invalidate(_mapView.Handle);
		}

		[Foreign(Language.ObjC)]
		void Invalidate(ObjC.Object handle)
		@{
			[handle setNeedsDisplay];
		@}

		bool _isReady;
		public bool IsReady {
			get
			{
				return _isReady;
			}
		}
		public Action OnReady { get; set; }

		void OnReadyInternal()
		{
			_isReady = true;
			if(OnReady!=null) OnReady();
		}

		[Require("Source.Include", "iOS/MapViewDelegate.h")]
		[Foreign(Language.ObjC)]
		ObjC.Object Configure(ObjC.Object mapView, Action<bool> onMapMove, Action<int, double, double> onMapTouch, Action<int, string> onMarkerTouch)
		@{
			MKMapView* mv = mapView;
			MapViewDelegate* dg = [[MapViewDelegate alloc] init];
			[dg setAsDelegate:mv];
			[dg setMapMoveAction:onMapMove];
			[dg setMapTouchAction:onMapTouch];
			[dg setMarkerSelectAction:onMarkerTouch];
			return dg;
		@}

		[Foreign(Language.ObjC)]
		void DisposeDelegate()
		@{
			MapViewDelegate* dg = (MapViewDelegate*)@{MapView:Of(_this)._mapViewDelegate:Get()};
			[dg clearMarkers];
			[dg clearOverlays];
			[dg setAsDelegate:nil];
			[dg setMapMoveAction:nil];
			[dg setMapTouchAction:nil];
		@}

		[Foreign(Language.ObjC)]
		double GetZoomLevel()
		@{
			MapViewDelegate* dg = (MapViewDelegate*)@{MapView:Of(_this)._mapViewDelegate:Get()};
			return [dg getZoomLevel];
		@}

		void OnMapTouch(int type, double lat, double lng)
		{
			switch(type)
			{
				case 0: //touch begin
					_mapViewHost.OnMapInteractionStart();
					break;
				case 1: //touch end
					break;
				case 2: //Tap
					HandleLocationTapped(lat,lng);
					break;
				case 3: //Long press
					HandleLocationLongPress(lat,lng);
					break;
				case 4: //Last touch ended
					_mapViewHost.OnMapInteractionEnd();
					break;
			}
		}

		public void HandleLocationTapped(double lat, double lng)
		{
			_mapViewHost.HandleLocationTapped(lat,lng);
		}

		public void HandleLocationLongPress(double lat, double lng)
		{
			_mapViewHost.HandleLocationLongPress(lat,lng);
		}

		void OnCameraMoved(bool animated)
		{
			if(animated) //not user interaction but we record it as such
				_mapViewHost.OnMapInteractionEnd();
		}

		[Foreign(Language.ObjC)]
		int AddMarker(int uid, string label, double lat, double lng, String iconPath, float iconAnchorX, float iconAnchorY)
		@{
			MapViewDelegate* dg = (MapViewDelegate*)@{MapView:Of(_this)._mapViewDelegate:Get()};
			return [dg addMarker:label latitude:lat longitude:lng icon:iconPath iconX:iconAnchorX iconY:iconAnchorY markerID:uid];
		@}

		[Foreign(Language.ObjC)]
		void RemoveMarker(int identifier)
		@{
			MapViewDelegate* dg = (MapViewDelegate*)@{MapView:Of(_this)._mapViewDelegate:Get()};
			[dg removeMarker:identifier];
		@}

		[Foreign(Language.ObjC)]
		void ClearMarkers()
		@{
			MapViewDelegate* dg = (MapViewDelegate*)@{MapView:Of(_this)._mapViewDelegate:Get()};
			[dg clearMarkers];
		@}

		public void HandleMarkerTapped(int id, string label)
		{
			_mapViewHost.HandleMarkerTapped(id, label);
		}

		public void UpdateMarkers()
		{
			ClearMarkers();
			foreach(MapMarker m in Markers)
			{
				AddMarker(
					m.uid,
					m.Label,
					m.Latitude,
					m.Longitude,
					_markerGraphicsCache.Get(m.IconFile),
					m.IconAnchorX,
					m.IconAnchorY
					);
			}
		}

		[Foreign(Language.ObjC)]
		void ClearOverlays()
		@{
			MapViewDelegate* dg = (MapViewDelegate*)@{MapView:Of(_this)._mapViewDelegate:Get()};
			[dg clearOverlays];
		@}

		[Foreign(Language.ObjC)]
		void AddOverlay(OverlayType type, double[] coordinates, float4 strokeColor, float4 fillColor, int lineWidth, bool geodesic, LineCap startCap, LineCap endCap, LineJoin joinType, int2 dashPattern, double centerLatitude, double centerLongitude, double radius)
		@{
			MapViewDelegate* dg = (MapViewDelegate*)@{MapView:Of(_this)._mapViewDelegate:Get()};
			NSArray<NSNumber *> *pattern = @[[NSNumber numberWithInt:dashPattern.X], [NSNumber numberWithInt:dashPattern.Y]];
			[dg addOverlay:coordinates
				type:type
				strokeColor:[UIColor colorWithRed:strokeColor.X green:strokeColor.Y blue:strokeColor.Z alpha:strokeColor.W]
				fillColor:[UIColor colorWithRed:fillColor.X green:fillColor.Y blue:fillColor.Z alpha:fillColor.W]
				lineWidth:lineWidth
				geodesic:geodesic
				startCap:startCap
				endCap:endCap
				joinType:joinType
				pattern:pattern
				centerLatitude:centerLatitude
				centerLongitude:centerLongitude
				radius:radius];
		@}

		public void UpdateOverlays()
		{
			ClearOverlays();
			foreach(MapOverlay p in Overlays)
			{
				AddOverlay(
					p.Type,
					p.GetCordinatesArray(),
					p.StrokeColor,
					p.FillColor,
					p.LineWidth,
					p.Geodesic,
					p.StartCap,
					p.EndCap,
					p.JoinType,
					p.DashPattern,
					p.CenterLatitude,
					p.CenterLongitude,
					p.Radius
					);
			}
		}

		public ObservableList<MapMarker> Markers {
			get
			{
				return _mapViewHost.Markers;
			}
		}

		public ObservableList<MapOverlay> Overlays {
			get
			{
				return _mapViewHost.Overlays;
			}
		}

		MapStyle _mapStyle = MapStyle.Normal;
		public MapStyle Style
		{
			get {
				return _mapStyle;
			}
			set {
				_mapStyle = value;
				switch(_mapStyle)
				{
					case MapStyle.Satellite:
						_mapView.SetIntValue("mapType", 1);
						break;
					case MapStyle.Hybrid:
						_mapView.SetIntValue("mapType", 2);
						break;
					default:
						_mapView.SetIntValue("mapType", 0);
						break;
				}
			}
		}

		double _latInternal;
		public double Latitude
		{
			get
			{
				return Double.IsNaN(_mapView.GetLatitude())
					? _latInternal : _mapView.GetLatitude();
			}
		}

		double _lngInternal;
		public double Longitude
		{
			get
			{
				return Double.IsNaN(_mapView.GetLongitude())
					? _lngInternal : _mapView.GetLongitude();
			}
		}

		public double Bearing
		{
			get
			{
				return _mapView.GetHeading();
			}
		}
		public double Tilt
		{
			get
			{
				return _mapView.GetPitch();
			}
		}
		public double Zoom
		{
			get
			{
				return GetZoomLevel();
			}
		}

		[Foreign(Language.ObjC)]
		public void MoveTo(double latitude, double longitude, double zoomlevel, double tilt, double orientation)
		@{
			MapViewDelegate* dg = (MapViewDelegate*)@{MapView:Of(_this)._mapViewDelegate:Get()};
			[dg moveTo:latitude longitude:longitude zoom:zoomlevel tilt:tilt orientation:orientation];
		@}

		void HandleLocationAuthChange(bool status)
		{
			_mapView.SetBoolValue("showsUserLocation", status);
		}

		public bool ShowMyLocation
		{
			get
			{
				return _mapView.GetBoolValue("showsUserLocation");
			}
			set
			{
				if(value)
					RequestLocationAuth(HandleLocationAuthChange);
				else
					_mapView.SetBoolValue("showsUserLocation", value);
			}
		}
		public bool ShowMyLocationButton { get; set; }

		[Foreign(Language.ObjC)]
		public void RequestLocationAuth(Action<bool> onAuthorizationResult)
		@{
			MapViewDelegate* dg = (MapViewDelegate*)@{MapView:Of(_this)._mapViewDelegate:Get()};
			[dg requestLocationAuthentication:onAuthorizationResult];
		@}

		//iOS 9 only :(
		public bool ShowCompass
		{
			get;
			set;
		}

		public bool AllowZoom
		{
			get { return _mapView.GetBoolValue("zoomEnabled"); }
			set { _mapView.SetBoolValue("zoomEnabled", value); }
		}

		public bool AllowTilt
		{
			get { return _mapView.GetBoolValue("pitchEnabled"); }
			set { _mapView.SetBoolValue("pitchEnabled", value); }
		}

		public bool AllowRotate
		{
			get { return _mapView.GetBoolValue("rotateEnabled"); }
			set { _mapView.SetBoolValue("rotateEnabled", value); }
		}

		public bool AllowScroll
		{
			get { return _mapView.GetBoolValue("scrollEnabled"); }
			set { _mapView.SetBoolValue("scrollEnabled", value); }
		}

		public void SetLocation(double latitude, double longitude)
		{
			MoveTo(latitude,longitude, Zoom, Tilt, Bearing);
		}
	}
}
