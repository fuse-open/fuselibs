using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Uno.Permissions;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Maps.Android
{
	enum TouchAction
	{
		DOWN = 0,
		UP = 1,
		MOVE = 2
	}

	[Require("Gradle.Dependency.Implementation", "com.google.android.gms:play-services-maps:16.1.0")]
	extern (Android) public class MapView : Fuse.Controls.Native.Android.LeafView, IMapView
	{
		public bool IsReady { get; private set; }
		public Action OnReady { get; set; }
		MarkerIconCache _markerGraphicsCache;

		public static MapView Create(Fuse.Controls.MapView mapViewHost)
		{
			var m = ForeignHelpers.CreateMap();
			return new MapView(mapViewHost, m);
		}

		Java.Object _mapView;
		Fuse.Controls.MapView _mapViewHost;


		MapView(Fuse.Controls.MapView mapViewHost, Java.Object map) : base(map)
		{
			IsReady = false;
			_mapView = map;
			_mapViewHost = mapViewHost;
			_markerGraphicsCache = new MarkerIconCache(UpdateMarkers);
			ForeignHelpers.SetMapEventHandlers(
				_mapView,
				OnMapReady,
				HandleLocationLongPress,
				HandleLocationTapped,
				OnAnimationStart,
				OnAnimationEnd,
				SetLocationFromMap,
				HandleMarkerTapped,
				OnTouchEvent
				);
			ForeignHelpers.Configure(_mapView);
			SemanticControl.MapViewClient = this;
		}

		public override void Dispose()
		{
			SemanticControl.MapViewClient = null;
			IsReady = false;
			if(_mapView!=null)
				ForeignHelpers.Destroy(_mapView);
			_mapView = null;
			_mapViewHost = null;
			base.Dispose();
		}

		Fuse.Controls.MapView SemanticControl
		{
			get { return _mapViewHost; }
		}

		void SetLocationFromMap(double lat, double lng)
		{
			if(SemanticControl.UserInteractingWithMap)
				SemanticControl.UpdateRestState();
		}

		void OnAnimationStart()
		{
			//We count map animations as user interactions
			SemanticControl.OnMapInteractionStart();
		}

		void OnAnimationEnd()
		{
			SemanticControl.OnMapInteractionEnd();
		}

		void OnTouchEvent(int action, float x, float y)
		{
			switch(action)
			{
				case TouchAction.DOWN:
					SemanticControl.OnMapInteractionStart();
					break;
				case TouchAction.UP:
					SemanticControl.OnMapInteractionEnd();
					break;
			}
		}

		public void HandleLocationTapped(double latitude, double longitude)
		{
			SemanticControl.HandleLocationTapped(latitude,longitude);
		}

		public void HandleLocationLongPress(double latitude, double longitude)
		{
			SemanticControl.HandleLocationLongPress(latitude,longitude);
		}

		public void HandleMarkerTapped(int uid, string title)
		{
			SemanticControl.HandleMarkerTapped(uid, title);
		}

		internal void OnMapReady()
		{
			//Apply buffered props
			IsReady = true;
			Style = _mapStyleInternal;
			ShowMyLocation = _showLocation;
			ConfigUI();
			ConfigGestures();
			UpdateMarkers();
			UpdateOverlays();
			OnReady();
		}

		MapStyle _mapStyleInternal;
		public MapStyle Style
		{
			get { return _mapStyleInternal; }
			set
			{
				_mapStyleInternal = value;
				if(IsReady)
					switch(_mapStyleInternal)
					{
						case MapStyle.Satellite:
							ForeignHelpers.SetSatelliteStyle(_mapView);
						break;
						case MapStyle.Hybrid:
							ForeignHelpers.SetHybridStyle(_mapView);
						break;
						default:
							ForeignHelpers.SetNormalStyle(_mapView);
						break;
					}
			}
		}

		public double Zoom
		{
			get {
				if(!IsReady) return 0.0;
				return ForeignHelpers.GetZoom(_mapView);
			}
		}

		public ObservableList<MapMarker> Markers
		{
			get
			{
				return SemanticControl.Markers;
			}
		}

		public void UpdateMarkers(){
			if(!IsReady) return;
			ForeignHelpers.Clear(_mapView);
			foreach(MapMarker m in Markers)
			{
				ForeignHelpers.AddMarker(
					_mapView,
					m.Latitude,
					m.Longitude,
					m.Label,
					_markerGraphicsCache.Get(m.IconFile),
					m.IconAnchorX,
					m.IconAnchorY,
					m.uid
				);
			}
		}

		public ObservableList<MapOverlay> Overlays
		{
			get
			{
				return SemanticControl.Overlays;
			}
		}

		public void UpdateOverlays()
		{
			if(!IsReady) return;
			ForeignHelpers.ClearOverlays(_mapView);
			foreach(MapOverlay p in Overlays)
			{
				int[] pattern = new int[] { p.DashPattern.X, p.DashPattern.Y };
				ForeignHelpers.AddOverlay(
					_mapView, p.Type,
					p.GetCordinatesArray(),
					(int)Uno.Color.ToArgb(p.StrokeColor),
					(int)Uno.Color.ToArgb(p.FillColor),
					p.LineWidth,
					p.Geodesic,
					p.StartCap,
					p.EndCap,
					p.JoinType,
					pattern,
					p.CenterLatitude,
					p.CenterLongitude,
					p.Radius
					);
			}
		}

		public void SetLocation(double latitude, double longitude)
		{
			if(IsReady) ForeignHelpers.SetPosition(_mapView, latitude, longitude, 0.0);
		}

		public double Bearing {
			get {
				return ForeignHelpers.GetOrientation(_mapView);
			}
		}

		public double Tilt {
			get {
				return ForeignHelpers.GetTilt(_mapView);
			}
		}

		public double Latitude {
			get {
				return ForeignHelpers.GetPositionLat(_mapView);
			}
		}

		public double Longitude {
			get {
				return ForeignHelpers.GetPositionLong(_mapView);
			}
		}

		public void MoveTo(double latitude, double longitude, double zoomlevel, double tilt, double orientation)
		{
			ForeignHelpers.MoveCamera(_mapView, latitude, longitude, (float)zoomlevel, (float)tilt, (float)orientation, 0.0);
		}

		void ConfigUI(){
			if(IsReady) ForeignHelpers.ConfigureUI(_mapView, _showCompass, _showLocationButton);
		}

		void ConfigGestures(){
			if(IsReady) ForeignHelpers.ConfigureGestures(_mapView, _allowZoom, _allowRotate, _allowTilt, _allowScroll);
		}

		class ShowLocationCommand
		{
			readonly bool _value;
			readonly Java.Object _handle;
			public ShowLocationCommand(Java.Object handle, bool newValue)
			{
				_handle = handle;
				_value = newValue;
			}
			public void Execute(PlatformPermission[] grantedPermissions)
			{
				ForeignHelpers.SetMyLocationEnabled(_handle, _value);
			}
			public void Reject(Exception e)
			{
				debug_log("Could not acquire location permissions");
			}
		}

		bool _showLocation;
		public bool ShowMyLocation {
			get {
				return _showLocation;
			}
			set {
				_showLocation = value;
				if(IsReady)
				{
					if(_showLocation)
					{
						var permissions = new PlatformPermission[]
						{
							Permissions.Android.ACCESS_FINE_LOCATION,
							Permissions.Android.ACCESS_COARSE_LOCATION
						};
						var cmd = new ShowLocationCommand(_mapView, _showLocation);
						Permissions.Request(permissions).Then(cmd.Execute, cmd.Reject);
					}
					else
					{
						ForeignHelpers.SetMyLocationEnabled(_mapView, _showLocation);
					}
				}
			}
		}

		bool _showLocationButton;
		public bool ShowMyLocationButton {
			get {
				return _showLocationButton;
			}
			set {
				_showLocationButton = value;
				ConfigUI();
			}
		}

		bool _showCompass;
		public bool ShowCompass {
			get {
				return _showCompass;
			}
			set {
				_showCompass = value;
				ConfigUI();
			}
		}
		bool _allowZoom;
		public bool AllowZoom {
			get {
				return _allowZoom;
			}
			set {
				_allowZoom = value;
				ConfigGestures();
			}
		}

		bool _allowTilt;
		public bool AllowTilt {
			get {
				return _allowTilt;
			}
			set {
				_allowTilt = value;
				ConfigGestures();
			}
		}

		bool _allowRotate;
		public bool AllowRotate {
			get {
				return _allowRotate;
			}
			set {
				_allowRotate = value;
				ConfigGestures();
			}
		}

		bool _allowScroll;
		public bool AllowScroll {
			get {
				return _allowScroll;
			}
			set {
				_allowScroll = value;
				ConfigGestures();
			}
		}

	}

}
