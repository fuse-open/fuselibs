package com.fuse.maps;
import android.content.Context;
import android.os.Bundle;
import android.view.MotionEvent;
import android.view.View;
import android.util.Log;
import android.widget.FrameLayout;
import android.graphics.Bitmap;

import com.google.android.gms.maps.MapsInitializer;
import com.google.android.gms.maps.CameraUpdate;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.GoogleMap.SnapshotReadyCallback;
import com.google.android.gms.maps.MapView;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.UiSettings;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.android.gms.maps.model.Polyline;
import com.google.android.gms.maps.model.PolylineOptions;
import com.google.android.gms.maps.model.Polygon;
import com.google.android.gms.maps.model.Circle;
import com.google.android.gms.maps.model.CircleOptions;
import com.google.android.gms.maps.model.PolygonOptions;
import com.google.android.gms.maps.model.Cap;
import com.google.android.gms.maps.model.ButtCap;
import com.google.android.gms.maps.model.RoundCap;
import com.google.android.gms.maps.model.SquareCap;
import com.google.android.gms.maps.model.JointType;
import com.google.android.gms.maps.model.Dash;
import com.google.android.gms.maps.model.Gap;
import com.google.android.gms.maps.model.Dot;
import com.google.android.gms.maps.model.PatternItem;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.LatLngBounds;
import java.util.Map;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.HashMap;
import java.io.FileOutputStream;
import com.foreign.Uno.Action_String;

public class FuseMap extends FrameLayout {

	static final String TAG = "FuseMap";

	public interface FuseMapCallback
	{
		void onReady();
		void onLongPress(double lat, double lng);
		void onPress(double lat, double lng);
		void onAnimationStart();
		void onAnimationStop();
		void onCameraChange(double latitude, double longitude, double zoom, double tilt, double bearing);
		boolean onMarkerPress(Marker m);
		void onPolygonPress(Polygon p);
		void onPolylinePress(Polyline p);
		void onCirclePress(Circle c);
		boolean onTouchEvent(int action, float x, float y);
	}

	private FuseMapCallback _callback;
	private GoogleMap _googleMap;
	private MapView _mapView;
	private boolean _isAnimating;
	private Map<Marker, Integer> _markerIDs;
	private Map<Polyline, Integer> _polylines;
	private Map<Polygon, Integer> _polygons;
	private Map<Circle, Integer> _circles;

	public FuseMap()
	{
		super(com.fuse.Activity.getRootActivity());
		MapsInitializer.initialize(com.fuse.Activity.getRootActivity());
		_mapView = new MapView(com.fuse.Activity.getRootActivity());
		addView(_mapView);
		_markerIDs = new HashMap<Marker,Integer>();
		_polylines = new HashMap<Polyline, Integer>();
		_polygons = new HashMap<Polygon, Integer>();
		_circles = new HashMap<Circle, Integer>();

		_mapView.getMapAsync(new OnMapReadyCallback()
		{
			@Override
			public void onMapReady(GoogleMap googleMap)
			{
				configure(googleMap);
			}
		});
	}

	public int getIdforMarker(Marker m)
	{
		return _markerIDs.get(m);
	}

	public int getIdforPolygon(Polygon p)
	{
		return _polygons.get(p);
	}

	public int getIdforPolyline(Polyline p)
	{
		return _polylines.get(p);
	}

	public int getIdforCircle(Circle c)
	{
		return _circles.get(c);
	}

	@Override
	public boolean dispatchTouchEvent(MotionEvent event) {
		onTouch(event);
		return super.dispatchTouchEvent(event);
	}

	public void SetCallback(FuseMapCallback callback)
	{
		_callback = callback;
	}

	public void dispose()
	{
		if (_googleMap!=null)
			_googleMap.setOnCameraChangeListener(null);
		if (_mapView!=null)
			removeView(_mapView);
		_callback = null;
		_googleMap = null;
		_mapView = null;
		_markerIDs = null;
		_isAnimating = false;
	}

	private boolean onTouch(MotionEvent event)
	{
		if (_callback != null)
			return _callback.onTouchEvent(event.getAction(), event.getX(), event.getY());

		return false;
	}

	public void setMyLocationEnabled(boolean b){
		_googleMap.setMyLocationEnabled(b);
	}

	private void configure(GoogleMap map)
	{
		_googleMap = map;
		_googleMap.setOnCameraChangeListener(new GoogleMap.OnCameraChangeListener()
		{
			@Override
			public void onCameraChange(CameraPosition cameraPosition)
			{
				onCameraChanged(cameraPosition);
			}
		});

		_googleMap.setOnMapLongClickListener(new GoogleMap.OnMapLongClickListener()
		{
			@Override
			public void onMapLongClick(LatLng latLng)
			{
				onMapLongPress(latLng);
			}
		});

		_googleMap.setOnMapClickListener(new GoogleMap.OnMapClickListener()
		{
			@Override
			public void onMapClick(LatLng latLng)
			{
				onClick(latLng);
			}
		});

		_googleMap.setOnMarkerClickListener(new GoogleMap.OnMarkerClickListener()
		{
			@Override
			public boolean onMarkerClick(Marker marker)
			{
				return onMarkerPress(marker);
			}
		});

		_googleMap.setOnPolygonClickListener(new GoogleMap.OnPolygonClickListener() {

			@Override
			public void onPolygonClick(Polygon polygon) {
				onPolygonPress(polygon);
			}
		});

		_googleMap.setOnPolylineClickListener(new GoogleMap.OnPolylineClickListener() {

			@Override
			public void onPolylineClick(Polyline polyline) {
				onPolylinePress(polyline);
			}
		});

		_googleMap.setOnCircleClickListener(new GoogleMap.OnCircleClickListener() {

			@Override
			public void onCircleClick(Circle circle) {
				onCirclePress(circle);
			}
		});

		if (_callback!=null)
			_callback.onReady();
	}

	void onPolygonPress(Polygon polygon)
	{
		if (_callback != null)
			_callback.onPolygonPress(polygon);
	}

	void onPolylinePress(Polyline polyline)
	{
		if (_callback != null)
			_callback.onPolylinePress(polyline);
	}

	void onCirclePress(Circle circle)
	{
		if (_callback != null)
			_callback.onCirclePress(circle);
	}

	private boolean onMarkerPress(Marker marker)
	{
		if (_callback != null)
			return _callback.onMarkerPress(marker);
		return false;
	}

	void onMapLongPress(LatLng latLng)
	{
		if (_callback != null)
			_callback.onLongPress(latLng.latitude, latLng.longitude);
	}

	void onClick(LatLng latLng)
	{
		if (_callback != null)
			_callback.onPress(latLng.latitude, latLng.longitude);
	}

	private void onAnimationFinish()
	{
		stopAnimation();
	}
	private void onAnimationCancel()
	{
		stopAnimation();
	}

	public boolean isInitialized(){ return _googleMap != null; }

	/* Markers */

	public String addMarker(double lat, double lng, String label, String iconPath, float iconAnchorX, float iconAnchorY, int uid)
	{
		MarkerOptions opt = new MarkerOptions().position(new LatLng(lat, lng));
		if (iconPath!=null)
		{
			opt.icon(BitmapDescriptorFactory.fromPath(iconPath)).anchor(iconAnchorX, iconAnchorY);
		}
		if (label!=null) opt.title(label);
		Marker m =  _googleMap.addMarker(opt);
		_markerIDs.put(m, uid);
		return m.getId();
	}

	private Cap convertIntCap(int cap)
	{
		Cap capObj = null;
		switch (cap)
		{
			case 0: capObj = new RoundCap(); break;
			case 1: capObj = new ButtCap(); break;
			case 2: capObj = new SquareCap(); break;
			default:
				capObj = new RoundCap();
		}
		return capObj;
	}

	private int selectJointType(int joinType)
	{
		int jointType;
		switch (joinType) {
			case 0: jointType = JointType.ROUND; break;
			case 1: jointType = JointType.BEVEL; break;
			case 2: jointType = JointType.DEFAULT; break;
			default:
				jointType = JointType.ROUND;
		}
		return jointType;
	}

	private Polyline drawPolyline(List<LatLng> points, int strokeColor, int lineWidth, boolean geodesic, int startCap, int endCap, int jointType, List<PatternItem> pattern)
	{
		Cap sCap = convertIntCap(startCap);
		Cap eCap = convertIntCap(endCap);
		PolylineOptions options = new PolylineOptions()
			.color(strokeColor)
			.width(lineWidth)
			.startCap(sCap)
			.endCap(eCap)
			.jointType(jointType)
			.geodesic(geodesic)
			.zIndex(1)
			.addAll(points);
		if (pattern != null)
			options.pattern(pattern);
		return _googleMap.addPolyline(options);
	}

	private Polygon drawPolygon(List<LatLng> points, int strokeColor, int fillColor, int lineWidth, boolean geodesic, int jointType, List<PatternItem> pattern)
	{
		PolygonOptions options = new PolygonOptions()
			.strokeColor(strokeColor)
			.fillColor(fillColor)
			.strokeWidth(lineWidth)
			.strokeJointType(jointType)
			.geodesic(geodesic)
			.strokePattern(pattern)
			.zIndex(1)
			.addAll(points);
		if (pattern != null)
			options.strokePattern(pattern);
		return _googleMap.addPolygon(options);
	}

	private Circle drawCircle(LatLng center, double radius, int strokeColor, int fillColor, int lineWidth, List<PatternItem> pattern)
	{
		CircleOptions options = new CircleOptions()
			.strokeColor(strokeColor)
			.fillColor(fillColor)
			.strokeWidth(lineWidth)
			.center(center)
			.radius(radius)
			.strokePattern(pattern)
			.zIndex(1);
		return _googleMap.addCircle(options);
	}

	private List<PatternItem> constructPattern(int[] dashPattern)
	{
		if (dashPattern.length == 2) {
			if (dashPattern[0] > 0 && dashPattern[1] > 0)
				return Arrays.asList(new Gap(dashPattern[1]), new Dash(dashPattern[0]));
		}
		return null;
	}

	public String AddOverlay(int type, double[] coordinates, int strokeColor, int fillColor, int lineWidth, boolean geodesic, int startCap, int endCap, int joinType, int[] dashPattern, double centerLatitude, double centerLongitude, double radius, int uid)
	{
		int jointType = selectJointType(joinType);
		List<PatternItem> pattern = constructPattern(dashPattern);
		List<LatLng> points = new ArrayList<>();
		for (int i=0; i<coordinates.length; i+=2)
			points.add(new LatLng(coordinates[i], coordinates[i+1]));
		switch (type)
		{
			case 1:
				Polygon polygon = drawPolygon(points, strokeColor, fillColor, lineWidth, geodesic, jointType, pattern);
				polygon.setClickable(true);
				_polygons.put(polygon, uid);
				return polygon.getId();
			case 2:
				Circle circle = drawCircle(new LatLng(centerLatitude, centerLongitude), radius, strokeColor, fillColor, lineWidth, pattern);
				circle.setClickable(true);
				_circles.put(circle, uid);
				return circle.getId();
			default:
				Polyline polyline = drawPolyline(points, strokeColor, lineWidth, geodesic, startCap, endCap, jointType, pattern);
				polyline.setClickable(true);
				_polylines.put(polyline, uid);
				return polyline.getId();
		}
	}

	public void clearOverlays()
	{
		for (Polyline polyline : _polylines.keySet()) {
			polyline.remove();
		}
		_polylines.clear();
		for (Polygon polygon : _polygons.keySet()) {
			polygon.remove();
		}
		_polygons.clear();
		for (Circle circle : _circles.keySet()) {
			circle.remove();
		}
		_circles.clear();
	}

	/* Camera */

	public boolean isAnimating() { return _isAnimating; }

	public void moveCamera(double lat, double lng, float zoom, float tilt, float bearing, double duration)
	{
		CameraUpdate cu = genCamUpdate(lat, lng, zoom, tilt, bearing);
		performCameraMove(cu, duration);
	}

	public void showAllMarkers()
	{
		LatLngBounds.Builder builder = new LatLngBounds.Builder();
		for (Marker marker : _markerIDs.keySet()) {
			builder.include(marker.getPosition());
		}
		LatLngBounds bounds = builder.build();
		int width = _mapView.getMeasuredWidth();
		int height = _mapView.getMeasuredHeight();
		int padding = (int) (height * 0.15); // offset from edges of the map in pixels
		CameraUpdate cu = CameraUpdateFactory.newLatLngBounds(bounds, width, height, padding);
		_googleMap.animateCamera(cu);
	}

	public void shapshot(final Action_String actionSucess, final Action_String actionError)
	{
		SnapshotReadyCallback callback = new SnapshotReadyCallback() {
			Bitmap bitmap;

			@Override
			public void onSnapshotReady(Bitmap snapshot) {
				bitmap = snapshot;
				try {
					android.content.Context context = com.fuse.Activity.getRootActivity();
					java.io.File dir = context.getFilesDir();
					String mPath = dir.getAbsolutePath() + "/map_snapshot.png";
					FileOutputStream out = new FileOutputStream(mPath);
					bitmap.compress(Bitmap.CompressFormat.PNG, 90, out);
					actionSucess.run(mPath);
				} catch (Exception e) {
					actionError.run(e.getMessage());
					e.printStackTrace();
				}
			}
		};
		_googleMap.snapshot(callback);
	}

	public void setPosition(double lat, double lng, double duration)
	{
		CameraUpdate cu = genCamUpdate(lat, lng, getZoom(), getTilt(), getOrientation());
		performCameraMove(cu, duration);
	}

	private LatLng getPosition(){
		return _googleMap.getCameraPosition().target;
	}

	public double getPositionLat()
	{
		return getPosition().latitude;
	}

	public double getPositionLong()
	{
		return getPosition().longitude;
	}

	public void configureUI(boolean compass, boolean myLocationButton)
	{
		UiSettings settings = _googleMap.getUiSettings();
		settings.setCompassEnabled(compass);
		settings.setMyLocationButtonEnabled(myLocationButton);
	}

	public void configureGestures(boolean zoom, boolean rotate, boolean tilt, boolean scroll){
		UiSettings settings = _googleMap.getUiSettings();
		settings.setZoomGesturesEnabled(zoom);
		settings.setRotateGesturesEnabled(rotate);
		settings.setTiltGesturesEnabled(tilt);
		settings.setScrollGesturesEnabled(scroll);
	}

	public void zoomIn(double duration){
		zoomBy(1.0f, duration);
	}

	public void zoomOut(double duration){ zoomBy(-1.0f, duration); }

	public float getZoom()
	{
		return _googleMap.getCameraPosition().zoom;
	}

	public void clear(){
		for (Marker marker : _markerIDs.keySet())
			marker.remove();
		_markerIDs.clear();
	}

	private void zoomBy(float increment, double duration)
	{
		LatLng p = getPosition();
		CameraUpdate cu = genCamUpdate(p.latitude,p.longitude, getZoom()+increment, getTilt(), getOrientation());
		performCameraMove(cu, duration);
	}

	public void setZoom(float value, double duration)
	{
		LatLng p = getPosition();
		CameraUpdate cu = genCamUpdate(p.latitude,p.longitude, value, getTilt(), getOrientation());
		performCameraMove(cu, duration);
	}

	public float getTilt()
	{
		return _googleMap.getCameraPosition().tilt;
	}

	public void setTilt(float tilt, double duration)
	{
		LatLng p = getPosition();
		CameraUpdate cu = genCamUpdate(p.latitude,p.longitude, getZoom(), tilt, getOrientation());
		performCameraMove(cu, duration);
	}

	public float getOrientation()
	{
		return _googleMap.getCameraPosition().bearing;
	}

	public void setOrientation(float degrees, double duration)
	{
		LatLng p = getPosition();
		CameraUpdate cu = genCamUpdate(p.latitude,p.longitude, getZoom(), getTilt(), degrees);
		performCameraMove(cu, duration);
	}

	private CameraUpdate genCamUpdate(double lat, double lng, float zoom, float tilt, float bearing)
	{
		return CameraUpdateFactory.newCameraPosition(
			CameraPosition.builder()
				.bearing(bearing)
				.tilt(tilt)
				.zoom(zoom)
				.target(new LatLng(lat, lng))
				.build()
		);
	}

	private void performCameraMove(CameraUpdate cu, double duration)
	{
		if (duration == 0.0){
			_googleMap.moveCamera(cu);
			return;
		}

		_googleMap.animateCamera(cu, (int) Math.floor(duration * 1000.0), _animationCallback);
		startAnimation();
	}

	private void startAnimation(){
		_isAnimating = true;
		if (_callback != null)
			_callback.onAnimationStart();
	}

	private void stopAnimation(){
		_isAnimating = false;
		if (_callback != null)
			_callback.onAnimationStop();
	}

	private GoogleMap.CancelableCallback _animationCallback = new GoogleMap.CancelableCallback() {
		@Override
		public void onFinish() {
			onAnimationFinish();
		}

		@Override
		public void onCancel() {
			onAnimationCancel();
		}
	};

	private void onCameraChanged(CameraPosition pos)
	{
		if (_callback != null)
			_callback.onCameraChange(pos.target.latitude, pos.target.longitude, pos.zoom, pos.tilt, pos.bearing);
	}

	/* Visuals */

	public void setNormalStyle()
	{
		_googleMap.setMapType(GoogleMap.MAP_TYPE_NORMAL);
	}

	public void setSatelliteStyle()
	{
		_googleMap.setMapType(GoogleMap.MAP_TYPE_SATELLITE);
	}

	public void setHybridStyle()
	{
		_googleMap.setMapType(GoogleMap.MAP_TYPE_HYBRID);
	}

	public void setTerrainStyle()
	{
		_googleMap.setMapType(GoogleMap.MAP_TYPE_TERRAIN);
	}

	/* LIFECYCLE */

	public void onCreate(Bundle bundle){
		_mapView.onCreate(bundle);
	}
	public void onResume(){
		_mapView.onResume();
	}
	public void onPause(){
		_mapView.onPause();
	}
	public void onDestroy(){
		_mapView.onDestroy();
	}
	public void onSaveInstanceState(Bundle outState){
		_mapView.onSaveInstanceState(outState);
	}
	public void onLowMemory(){
		_mapView.onLowMemory();
	}
}
