using Fuse.Elements;
using Uno.UX;
using Uno;
namespace Fuse.Controls
{
	/** Adds a map marker to a @MapView

	To annotate the map, you must decorate it with `MapMarker` nodes. `MapMarker` nodes are simple value objects that contain a `Latitude`, a `Longitude` and a `Label`

	```HTML
	<NativeViewHost>
		<MapView>
			<MapMarker Label="Fuse HQ" Latitude="59.9115573" Longitude="10.73888" />
		</MapView>
	</NativeViewHost>
	```

	If you need to generate MapMarkers dynamically from JS, data binding and @(Each) are your friends. While we're scripting we might as well hook into the MapMarker's `Tapped` event to detect when the user has selected a marker.

	```HTML
	<JavaScript>
		var Observable = require("FuseJS/Observable");
		module.exports = {
			markers : Observable({latitude:30.282786, longitude:-97.741736, label:"Austin, Texas", hometown:true}),
			onMarkerTapped : function(args) {
				console.log("Marker tapped: "+args.data.hometown);
			}
		}
	</JavaScript>

	<NativeViewHost>
		<MapView>
			<Each Items={markers}>
				<MapMarker Latitude="{latitude}" Longitude="{longitude}" Label="{label}" Tapped={onMarkerTapped} />
			</Each>
		</MapView>
	</NativeViewHost>
	```

	@seealso Fuse.Controls.MapView
	*/
	public class MapMarker : Node
	{
		static int UID_POOL = 0;
		internal int uid = UID_POOL++;
		public delegate void MarkerTappedHandler(object sender, EventArgs args);
		public event MarkerTappedHandler Tapped;
		
		internal void HandleTapped()
		{
			if (Tapped != null)
				Tapped(this, new EventArgs());
		}
		
		string _label;
		public string Label {
			get
			{
				return _label;
			}
			set
			{
				_label = value;
				MarkDirty();
			}
		}

		double _latitude;
		/**
			The latitude coordinate of this marker
		*/
		public double Latitude {
			get
			{
				return _latitude;
			}
			set
			{
				_latitude = value;
				MarkDirty();
			}
		}

		double _longitude;
		/**
			The longitude coordinate of this marker
		*/
		public double Longitude {
			get
			{
				return _longitude;
			}
			set
			{
				_longitude = value;
				MarkDirty();
			}
		}
		
		FileSource _icon;
		/**
			The asset image file to use as the marker icon override
		*/
		public FileSource IconFile 
		{
			get {
				return _icon;
			}
			set {
				_icon = value;
				MarkDirty();
			}
		}
		
		//TODO: Combine these into single float2 field once Latitude and Longitude can be combined into single double2 field
		float2 _iconAnchor = float2(0.5f, 0.5f);
		/**
			The normalized X-position of the Icon image to use as the icon/map contact point
		*/
		public float IconAnchorX
		{
			get { return _iconAnchor.X; }
			set { _iconAnchor.X = value; MarkDirty(); }
		}
		
		/**
			The normalized Y-position of the Icon image to use as the icon/map contact point
		*/
		public float IconAnchorY
		{
			get { return _iconAnchor.Y; }
			set { _iconAnchor.Y = value; MarkDirty(); }
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			MapView m = Parent as MapView;
			if(m != null) m.AddMarker(this);
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			MapView m = Parent as MapView;
			if(m != null) m.RemoveMarker(this);
		}

		void MarkDirty()
		{
			MapView m = Parent as MapView;
			if(m != null) m.UpdateMarkersNextFrame();
		}
	}
}
