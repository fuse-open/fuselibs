namespace Fuse.Controls
{
	/** Adds a map polyline to a @MapView

	To create a polyline the map, you must decorate it with `MapPolyline` nodes. `MapPolyline` nodes are simple value objects that contain a `Data`, which is a list of <latitude>,<longitude> seperated with |, and a `Label`

	```HTML
	<NativeViewHost>
		<MapView>
			<MapPolyline Data="59.911636,10.740988|59.911289,10.740645|59.911074,10.741516|59.910837,10.742507|59.910176,10.741872|59.909751,10.741472|59.910174,10.739729|59.910249,10.73974|59.910305,10.739639|59.910308,10.739495|59.91026,10.739388|59.9104,10.738814|59.910439,10.738661|59.910389,10.73859|59.910361,10.738467|59.910394,10.738218|59.911062,10.735432|59.911103,10.735377|59.911178,10.735364|59.911205,10.735386|59.911621,10.735952|59.911678,10.736031|59.912095,10.734719|59.912139,10.734573|59.912242,10.734659|59.912265,10.734677|59.912341,10.734361|59.91275,10.734735|59.9128,10.734612|59.912879,10.73432|59.912903,10.734054|59.912495,10.733645|59.912537,10.733365|59.912576,10.733376|59.912718,10.732084|59.912702,10.731865|59.912689,10.731744|59.912752,10.731748|59.913941,10.730848|59.913985,10.730804|59.914508,10.731888|59.914577,10.73201|59.914785,10.732281|59.914836,10.732326|59.914839,10.732383|59.914886,10.732505|59.914953,10.732571|59.915019,10.732572|59.915066,10.732546|59.915162,10.732388|59.915189,10.732261|59.915271,10.729929|59.91536,10.726727|59.91536,10.726624|59.915399,10.726627|59.916174,10.727634|59.916354,10.727838" Color="#f00" LineWidth="1" Label="Fuse HQ to Castle" />
		</MapView>
	</NativeViewHost>
	```

	If you need to generate MapMarkers dynamically from JS, data binding and @(Each) are your friends. While we're scripting we might as well hook into the MapMarker's `Tapped` event to detect when the user has selected a marker.

	```HTML
	<JavaScript>
		var Observable = require("FuseJS/Observable");
		module.exports = {
			markers : Observable({data:"59.911636,10.740988|59.911289,10.740645|59.911074,10.741516", label:"Tracks"),
		}
	</JavaScript>

	<NativeViewHost>
		<MapView>
			<Each Items={markers}>
				<MapPolyline Data="{data}" Label="{label}" />
			</Each>
		</MapView>
	</NativeViewHost>
	```

	@seealso Fuse.Controls.MapView
	*/

	public class MapPolyline : Node
	{

		string _label;
		public string Label
		{
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

		double[] _coords;
		public double[] Coords
		{
			get { return _coords; }
		}

		string _data;
		static readonly char[] delimiterChars = new char[] { '|', ',' };
		public string Data
		{
			get
			{
				return _data;
			}
			set
			{
				_data = value;

				string[] words = _data.Split(delimiterChars);
				if (words.Length <= 1) return;
				_coords = new double[words.Length];
				for (var i = 0; i < words.Length; i++) {
					_coords[i] = double.Parse(words[i]);
				}

				MarkDirty();
			}
		}

		float4 _color = float4(1,0,0,1);
		public float4 Color
		{
			get
			{
				return _color;
			}
			set
			{
				_color = value;
				MarkDirty();
			}
		}

		float _lineWidth = 1;
		public float LineWidth
		{
			get
			{
				return _lineWidth;
			}
			set
			{
				_lineWidth = value;
				MarkDirty();
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			MapView m = Parent as MapView;
			if(m != null) m.AddPolyline(this);
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			MapView m = Parent as MapView;
			if(m != null) m.RemovePolyline(this);
		}

		void MarkDirty()
		{
			MapView m = Parent as MapView;
			if(m != null) m.UpdateMarkersNextFrame();
		}
	}
}
