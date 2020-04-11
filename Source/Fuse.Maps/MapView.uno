using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Input;
using Fuse.Gestures;
using Fuse.Animations;
using Fuse.Elements;
using Fuse.Triggers;
using Fuse.Controls;
using Fuse.Maps;

namespace Fuse.Controls
{

	public enum MapStyle
	{
		Normal,
		Satellite,
		Hybrid
	}

	internal class MapCameraState
	{
		public double Latitude { get; set; }
		public double Longitude { get; set; }
		public double Bearing { get; set; }
		public double Tilt { get; set; }
		public double Zoom { get; set; }

		public void CopyFrom(IMapView mv)
		{
			Latitude = mv.Latitude;
			Longitude = mv.Longitude;
			Bearing = mv.Bearing;
			Tilt = mv.Tilt;
			Zoom = mv.Zoom;
		}

		public override string ToString()
		{
			return "[MapCameraState Latitude:"+Latitude+" Longitude:"+Longitude+" Bearing:"+Bearing+" Zoom:"+Zoom+" Tilt:"+Tilt+" ]";
		}
	}

	internal class MapConfig
	{
		public bool ShowMyLocation { get; set; }
		public bool ShowMyLocationButton { get; set; }
		public bool ShowCompass { get; set; }
		public bool AllowZoom { get; set; }
		public bool AllowTilt { get; set; }
		public bool AllowRotate { get; set; }
		public bool AllowScroll { get; set; }
		public MapStyle Style { get; set; }

		public MapConfig()
		{
			ShowMyLocation = false;
			ShowMyLocationButton = false;
			ShowCompass = false;
			AllowZoom = AllowTilt = AllowRotate = AllowScroll = true;
		}

		public void CopyFrom(IMapView mv)
		{
			ShowMyLocation = mv.ShowMyLocation;
			ShowMyLocationButton = mv.ShowMyLocationButton;
			ShowCompass = mv.ShowCompass;
			AllowZoom = mv.AllowZoom;
			AllowTilt = mv.AllowTilt;
			AllowRotate = mv.AllowRotate;
			AllowScroll = mv.AllowScroll;
			Style = mv.Style;
		}

		public void Apply(IMapView mv)
		{
			mv.ShowMyLocation = ShowMyLocation;
			mv.ShowMyLocationButton = ShowMyLocationButton;
			mv.ShowCompass = ShowCompass;
			mv.AllowZoom = AllowZoom;
			mv.AllowTilt = AllowTilt;
			mv.AllowRotate = AllowRotate;
			mv.AllowScroll = AllowScroll;
			mv.Style = Style;
		}
	}

	internal interface IMapView
	{
		ObservableList<MapMarker> Markers { get; }
		MapStyle Style { get; set; }
		double Latitude { get; }
		double Longitude { get; }
		double Bearing { get; }
		double Tilt { get; }
		double Zoom { get; }
		bool IsReady { get; }
		void SetLocation(double latitude, double longitude);
		void MoveTo(double latitude, double longitude, double zoomlevel, double tilt, double orientation);
		bool ShowMyLocation { get; set; }
		bool ShowMyLocationButton { get; set; }
		bool ShowCompass { get; set; }
		bool AllowZoom { get; set; }
		bool AllowTilt { get; set; }
		bool AllowRotate { get; set; }
		bool AllowScroll { get; set; }

		void UpdateMarkers();
		void UpdateOverlays();
		void HandleMarkerTapped(int id, string label);
		void HandleLocationTapped(double latitude, double longitude);
		void HandleLocationLongPress(double latitude, double longitude);
		Action OnReady { get; set; }
	}

	/** Displays a native map view.

	@include Docs/Brief.md
	@ux Docs/Example.ux
	@include Docs/ExampleDescription.md

	@seealso Fuse.Controls.MapMarker
	*/
	public partial class MapView : Panel
	{

		protected override Fuse.Controls.Native.IView CreateNativeView()
		{
			if defined(Android)
				return Fuse.Maps.Android.MapView.Create(this);
			else if defined(iOS)
				return Fuse.Maps.iOS.MapView.Create(this);
			else
				return base.CreateNativeView();
		}

		/**
			Dispatched when a map marker is tapped.

			*Handler example*
			```JS
			exports.onMarkerTapped = function(args) {
				console.log("Marker tapped: "+args.label);
			}
			```
		*/
		public event MarkerEventHandler MarkerTapped;

		/**
			Dispatched when a map location is tapped.

			*Handler example*
			```JS
			exports.onTapped = function(args) {
				console.log("Map tapped: "+args.latitude+", "+args.longitude);
			}
			```
		*/
		public event MapEventHandler LocationTapped;

		/**
			Dispatched when a map location is pressed and held.

			*Handler example*
			```JS
			exports.onLongPress = function(args) {
				console.log("Map longpresed: "+args.latitude+", "+args.longitude);
			}
			```
		*/
		public event MapEventHandler LocationLongPressed;

		MapConfig _mapConfig;
		MapCameraState _cameraState;
		public MapView()
		{
			if defined(!MOBILE)
			{
				Background = new Fuse.Drawing.SolidColor(float4(0.6f,0.6f,0.6f,1.0f));
				var t = new Fuse.Controls.Text();
				t.Alignment = Alignment.Center;
				t.SetValue("MapView requires a mobile target.", this);
				t.TextAlignment = TextAlignment.Center;
				Children.Add(t);
			}
			_cameraState = new MapCameraState();
			_mapConfig = new MapConfig();
		}

		internal ObservableList<MapOverlay> _overlays;
		public ObservableList<MapOverlay> Overlays
		{
			get
			{
				if(_overlays==null) _overlays = new ObservableList<MapOverlay>(OnOverlayAdded, OnOverlayRemoved);
				return _overlays;
			}
		}


		internal void AddOverlay(MapOverlay p)
		{
			if(Overlays.Contains(p)) return;
			Overlays.Add(p);
		}

		internal void RemoveOverlay(MapOverlay p)
		{
			Overlays.Remove(p);
		}

		public void ClearOverlays(){
			_overlays.Clear();
			UpdateOverlays();
		}

		void OnOverlayAdded(MapOverlay overlay)
		{
			UpdateOverlaysNextFrame();
		}

		void OnOverlayRemoved(MapOverlay overlay)
		{
			UpdateOverlaysNextFrame();
		}

		bool _willUpdateOverlaysNextFrame;
		internal void UpdateOverlaysNextFrame()
		{
			if(!MapIsReady || _willUpdateOverlaysNextFrame) return;
			UpdateManager.PerformNextFrame(DeferredOverlayUpdate, UpdateStage.Primary);
			_willUpdateOverlaysNextFrame = true;
		}

		void DeferredOverlayUpdate()
		{
			_willUpdateOverlaysNextFrame = false;
			UpdateOverlays();
		}

		void UpdateOverlays()
		{
			if(MapIsReady)
				MapViewClient.UpdateOverlays();
		}

		internal ObservableList<MapMarker> _markers;
		public ObservableList<MapMarker> Markers
		{
			get
			{
				if(_markers==null) _markers = new ObservableList<MapMarker>(OnMarkerAdded, OnMarkerRemoved);
				return _markers;
			}
		}


		internal void AddMarker(MapMarker m)
		{
			if(Markers.Contains(m)) return;
			Markers.Add(m);
		}

		internal void RemoveMarker(MapMarker m)
		{
			Markers.Remove(m);
		}

		void OnMarkerAdded(MapMarker marker)
		{
			UpdateMarkersNextFrame();
		}

		void OnMarkerRemoved(MapMarker marker)
		{
			UpdateMarkersNextFrame();
		}

		public void ClearMarkers(){
			_markers.Clear();
			UpdateMarkers();
		}

		bool _willUpdateMarkersNextFrame;
		internal void UpdateMarkersNextFrame()
		{
			if(!MapIsReady || _willUpdateMarkersNextFrame) return;
			UpdateManager.PerformNextFrame(DeferredMarkerUpdate, UpdateStage.Primary);
			_willUpdateMarkersNextFrame = true;
		}

		void DeferredMarkerUpdate()
		{
			_willUpdateMarkersNextFrame = false;
			UpdateMarkers();
		}

		bool _willUpdateCameraNextFrame;
		internal void UpdateCameraNextFrame()
		{
			if(!MapIsReady || _willUpdateCameraNextFrame) return;
			UpdateManager.PerformNextFrame(ApplyCameraState, UpdateStage.Primary);
			_willUpdateCameraNextFrame = true;
		}

		void ApplyCameraState()
		{
			_willUpdateCameraNextFrame = false;
			if(MapIsReady)
				MapViewClient.MoveTo(Latitude, Longitude, Zoom, Tilt, Bearing);
		}

		public void UpdateMarkers()
		{
			if(MapIsReady)
				MapViewClient.UpdateMarkers();
		}

		IMapView _mapViewClient;
		internal IMapView MapViewClient
		{
			get { return _mapViewClient; }
			set
			{
				_mapViewClient = value;
				if(_mapViewClient == null)
				{
					_mapReady = false;
					return;
				}

				MapViewClient.OnReady = OnMapReady;

				_mapConfig.Apply(MapViewClient);

			}
		}

		bool _mapReady = false;
		void OnMapReady()
		{
			if(MapViewClient == null) return;
			_mapReady = true;
			MapViewClient.OnReady = null;
			ApplyCameraState();
			UpdateRestState();
			UpdateMarkers();
			UpdateOverlays();
		}

		/* Begin methods that should be internal :( */
		public void HandleMarkerTapped(int id, string label)
		{
			if (MarkerTapped != null)
				MarkerTapped(this, new MarkerEventArgs(label));

			foreach(MapMarker m in Markers)
			{
				if(m.uid == id)
				{
					m.HandleTapped();
					return;
				}
			}
		}
		public void HandleLocationTapped(double latitude, double longitude)
		{
			if (LocationTapped != null)
				LocationTapped(this, new MapEventArgs(latitude, longitude));
		}
		public void HandleLocationLongPress(double latitude, double longitude)
		{
			if (LocationLongPressed != null)
				LocationLongPressed(this, new MapEventArgs(latitude, longitude));
		}
		/* End */

		internal bool UserInteractingWithMap { get; private set; }
		internal void OnMapInteractionStart()
		{
			UserInteractingWithMap = true;
		}

		internal void OnMapInteractionEnd()
		{
			UserInteractingWithMap = false;
			if(MapIsReady)
				_cameraState.CopyFrom(MapViewClient);
			UpdateRestState();
		}

		internal void UpdateRestState()
		{
			OnPropertyChanged(_latitudeName, this);
			OnPropertyChanged(_longitudeName, this);
			OnPropertyChanged(_zoomName, this);
			OnPropertyChanged(_bearingName, this);
			OnPropertyChanged(_tiltName, this);
		}

		public void SetLocation(double latitude, double longitude)
		{
			Latitude = latitude;
			Longitude = longitude;
		}

		bool MapIsReady
		{
			get {
				return _mapReady;
			}
		}

		/** `True` if the user's geographical location should be visible on the map. */
		public bool ShowMyLocation {
			get { return _mapConfig.ShowMyLocation; }
			set {
				_mapConfig.ShowMyLocation = value;
				if(MapIsReady)
					MapViewClient.ShowMyLocation = _mapConfig.ShowMyLocation;
			}
		}
		/** When `true`, MapView will display a button that focuses the camera on the user's geographical location.

			> *Note:* The [ShowMyLocation](api:fuse/controls/mapview/showmylocation) property must be `True` for this to have an effect.
		*/
		public bool ShowMyLocationButton {
			get { return _mapConfig.ShowMyLocationButton; }
			set {
				_mapConfig.ShowMyLocationButton = value;
				if(MapIsReady)
					MapViewClient.ShowMyLocationButton = _mapConfig.ShowMyLocationButton;
			}
		}
		/** When `True`, a compass will be shown on the map. */
		public bool ShowCompass {
			get { return _mapConfig.ShowCompass; }
			set {
				_mapConfig.ShowCompass = value;
				if(MapIsReady)
					MapViewClient.ShowCompass = _mapConfig.ShowCompass;
			}
		}
		/** Specifies whether the user is allowed to zoom the map.
			The zoom level can still be changed using the [Zoom](api:fuse/controls/mapview/zoom) property.
		*/
		public bool AllowZoom {
			get { return _mapConfig.AllowZoom; }
			set {
				_mapConfig.AllowZoom = value;
				if(MapIsReady)
					MapViewClient.AllowZoom = _mapConfig.AllowZoom;
			}
		}
		/** Specifies whether the user is allowed to tilt the map.
			The tilt angle can still be changed using the [Tilt](api:fuse/controls/mapview/tilt) property.
		*/
		public bool AllowTilt {
			get { return _mapConfig.AllowTilt; }
			set {
				_mapConfig.AllowTilt = value;
				if(MapIsReady)
					MapViewClient.AllowTilt = _mapConfig.AllowTilt;
			}
		}
		/** Specifies whether the user is allowed to rotate the map.
			The bearing can still be changed using the [Bearing](api:fuse/controls/mapview/bearing) property.
		*/
		public bool AllowRotate {
			get { return _mapConfig.AllowRotate; }
			set {
				_mapConfig.AllowRotate = value;
				if(MapIsReady)
					MapViewClient.AllowRotate = _mapConfig.AllowRotate;
			}
		}

		/** Specifies whether the user is allowed to scroll the map.
			The position can still be modified by the API.
		*/
		public bool AllowScroll {
			get { return _mapConfig.AllowScroll; }
			set {
				_mapConfig.AllowScroll = value;
				if(MapIsReady)
					MapViewClient.AllowScroll = _mapConfig.AllowScroll;
			}
		}

		/** The rendering style of the map (`Normal`, `Satellite` or `Hybrid`). */
		public MapStyle Style
		{
			get { return _mapConfig.Style; }
			set {
				_mapConfig.Style = value;
				if(MapIsReady)
					MapViewClient.Style = _mapConfig.Style;
			}
		}

		Selector _tiltName = "Tilt";

		[UXOriginSetter("SetTilt")]
		/** The angle of rotation around the X axis, measured in degrees. */
		public double Tilt
		{
			get { return _cameraState.Tilt; }
			set { SetTilt(value, this);	}
		}

		public void SetTilt(double value, IPropertyListener origin)
		{
			_cameraState.Tilt = value;
			UpdateCameraNextFrame();
			OnPropertyChanged(_tiltName, origin);
		}

		Selector _bearingName = "Bearing";

		[UXOriginSetter("SetBearing")]
		/** The bearing of the map relative to true north, in degrees. */
		public double Bearing
		{
			get { return _cameraState.Bearing; }
			set { SetBearing(value, this);	}
		}

		public void SetBearing(double value, IPropertyListener origin)
		{
			_cameraState.Bearing = value;
			UpdateCameraNextFrame();
			OnPropertyChanged(_bearingName, origin);
		}

		Selector _zoomName = "Zoom";

		[UXOriginSetter("SetZoom")]
		/** The zoom level of the camera. Corresponds to [Google Maps' Zoom Levels](https://developers.google.com/maps/documentation/static-maps/intro#Zoomlevels). */
		public double Zoom
		{
			get { return _cameraState.Zoom; }
			set { SetZoom(value, this);	}
		}

		public void SetZoom(double value, IPropertyListener origin)
		{
			_cameraState.Zoom = value;
			UpdateCameraNextFrame();
			OnPropertyChanged(_zoomName, origin);
		}

		/**
			Latitude
		**/
		Selector _latitudeName = "Latitude";

		[UXOriginSetter("SetLatitude")]
		/** The latitude coordinate. */
		public double Latitude
		{
			get { return _cameraState.Latitude; }
			set { SetLatitude(value, this);	}
		}

		public void SetLatitude(double value, IPropertyListener origin)
		{
			_cameraState.Latitude = value;
			UpdateCameraNextFrame();
			OnPropertyChanged(_latitudeName, origin);
		}

		Selector _longitudeName = "Longitude";

		[UXOriginSetter("SetLongitude")]
		/** The longitude coordinate. */
		public double Longitude
		{
			get { return _cameraState.Longitude; }
			set { SetLongitude(value, this);	}
		}

		public void SetLongitude(double value, IPropertyListener origin)
		{
			_cameraState.Longitude = value;
			UpdateCameraNextFrame();
			OnPropertyChanged(_longitudeName, origin);
		}
	}
}
