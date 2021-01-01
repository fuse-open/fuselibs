using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Maps.Android
{
	[ForeignInclude(Language.Java, "com.fuse.maps.FuseMap", "android.util.Log", "android.graphics.Color")]
	extern (Android) static class ForeignHelpers
	{
		[Foreign(Language.Java)]
		internal static Java.Object CreateMap()
		@{
			return new FuseMap();
		@}

		[Foreign(Language.Java)]
		internal static void MoveCamera(Java.Object handle, double lat, double lng, float zoom, float tilt, float bearing, double duration)
		@{
			FuseMap map = (FuseMap)handle;
			map.moveCamera(lat,lng,zoom,tilt,bearing,duration);
		@}

		[Foreign(Language.Java)]
		internal static void SetPosition(Java.Object handle, double lat, double lng, double duration)
		@{
			FuseMap map = (FuseMap)handle;
			map.setPosition(lat,lng,duration);
		@}

		[Foreign(Language.Java)]
		internal static double GetPositionLat(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			return map.getPositionLat();
		@}

		[Foreign(Language.Java)]
		internal static double GetPositionLong(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			return map.getPositionLong();
		@}

		[Foreign(Language.Java)]
		internal static void ConfigureUI(Java.Object handle, bool compass, bool myLocationButton)
		@{
			FuseMap map = (FuseMap)handle;
			map.configureUI(compass, myLocationButton);
		@}

		[Foreign(Language.Java)]
		internal static void ConfigureGestures(Java.Object handle, bool zoom, bool rotate, bool tilt, bool scroll)
		@{
			FuseMap map = (FuseMap)handle;
			map.configureGestures(zoom,rotate,tilt, scroll);
		@}

		[Foreign(Language.Java)]
		internal static float GetTilt(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			return map.getTilt();
		@}

		[Foreign(Language.Java)]
		internal static void SetTilt(Java.Object handle, float tilt, double duration)
		@{
			FuseMap map = (FuseMap)handle;
			map.setTilt(tilt, duration);
		@}

		[Foreign(Language.Java)]
		internal static float GetOrientation(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			return map.getOrientation();
		@}

		[Foreign(Language.Java)]
		internal static void SetOrientation(Java.Object handle, float degrees, double duration)
		@{
			FuseMap map = (FuseMap)handle;
			map.setOrientation(degrees, duration);
		@}

		[Foreign(Language.Java)]
		internal static void SetSatelliteStyle(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			map.setSatelliteStyle();
		@}

		[Foreign(Language.Java)]
		internal static void SetHybridStyle(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			map.setHybridStyle();
		@}

		[Foreign(Language.Java)]
		public static void SetNormalStyle(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			map.setNormalStyle();
		@}

		[Foreign(Language.Java)]
		internal static void Clear(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			map.clear();
		@}

		[Foreign(Language.Java)]
		internal static float GetZoom(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			return map.getZoom();
		@}

		[Foreign(Language.Java)]
		internal static void SetZoom(Java.Object handle, float zoom, double duration)
		@{
			FuseMap map = (FuseMap)handle;
			map.setZoom(zoom, duration);
		@}

		[Foreign(Language.Java)]
		internal static string AddMarker(Java.Object handle, double lat, double lng, String label, String iconPath, float iconAnchorX, float iconAnchorY, int uid)
		@{
			FuseMap map = (FuseMap)handle;
			return map.addMarker(lat, lng, label, iconPath, iconAnchorX, iconAnchorY, uid);
		@}

		[Foreign(Language.Java)]
		internal static void AddOverlay(Java.Object handle, OverlayType type, double[] coordinates, int strokeColor, int fillColor, int lineWidth, bool geodesic, LineCap startCap, LineCap endCap, LineJoin joinType, int[] dashPattern, double centerLatitude, double centerLongitude, double radius)
		@{
			FuseMap map = (FuseMap)handle;
			map.AddOverlay(type, coordinates.copyArray(), strokeColor, fillColor, lineWidth, geodesic, startCap, endCap, joinType, dashPattern.copyArray(), centerLatitude, centerLongitude, radius);
		@}

		[Foreign(Language.Java)]
		internal static void ClearOverlays(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			map.clearOverlays();
		@}

		[Foreign(Language.Java)]
		internal static void SetMyLocationEnabled(Java.Object handle, bool b)
		@{
			FuseMap map = (FuseMap)handle;
			map.setMyLocationEnabled(b);
		@}

		[Foreign(Language.Java)]
		internal static void Destroy(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			map.dispose();
		@}

		[Foreign(Language.Java)]
		internal static void Configure(Java.Object handle)
		@{
			FuseMap map = (FuseMap)handle;
			map.onCreate(null);
			map.onResume();
		@}

		[Foreign(Language.Java)]
		internal static void SetMapEventHandlers(
			Java.Object handle,
			Action onMapReady,
			Action<double, double> handleLocationLongPress,
			Action<double, double> handleLocationTapped,
			Action onAnimationBegin,
			Action onAnimationEnd,
			Action<double, double> handleCameraChange,
			Action<int, string> handleMarkerPressed,
			Action<int, float, float> handleTouchEvent
		)
		@{
			final FuseMap map = (FuseMap)handle;
			map.SetCallback(new FuseMap.FuseMapCallback() {
				@Override
				public void onReady() {
					onMapReady.run();
				}
				@Override
				public void onLongPress(double lat, double lng) {
					handleLocationLongPress.run(lat, lng);
				}
				@Override
				public void onPress(double lat, double lng) {
					handleLocationTapped.run(lat,lng);
				}
				@Override
				public void onAnimationStart() {
					onAnimationBegin.run();
				}
				@Override
				public void onAnimationStop() {
					onAnimationEnd.run();
				}
				@Override
				public void onCameraChange(double latitude, double longitude, double zoom, double tilt, double bearing) {
					handleCameraChange.run(latitude, longitude);
				}
				@Override
				public boolean onMarkerPress(com.google.android.gms.maps.model.Marker m) {
					handleMarkerPressed.run(map.getIdforMarker(m), m.getTitle());
					return false;
				}
				@Override
				public boolean onTouchEvent(int action, float x, float y) {
					handleTouchEvent.run(action, x, y);
					return false;
				}
			});
		@}
	}
}
