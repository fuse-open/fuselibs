using Fuse.Elements;
using Uno.UX;
using Uno;
using Uno.Collections;

namespace Fuse.Controls
{

	public enum OverlayType
	{
		Polyline,
		Polygon,
		Circle
	}

	public enum LineCap
	{
		Round,
		Butt,
		Square
	}

	public enum LineJoin
	{
		Round,
		Bevel,
		Miter
	}

	public class Coordinate : PropertyObject
	{
		static Selector _latitudeName = "Latitude";
		double _latitude = 0;
		/**
			The latitude coordinate
		*/
		public double Latitude {
			get
			{
				return _latitude;
			}
			set
			{
				if (_latitude != value)
				{
					_latitude = value;
					OnPropertyChanged(_latitudeName);
				}
			}
		}

		static Selector _longitudeName = "Longitude";
		double _longitude = 0;
		/**
			The longitude coordinate
		*/
		public double Longitude {
			get
			{
				return _longitude;
			}
			set
			{
				if (_longitude != value)
				{
					_longitude = value;
					OnPropertyChanged(_longitudeName);
				}
			}
		}

		public Coordinate() {}

		public Coordinate(double latitude, double longitude)
		{
			_latitude = latitude;
			_longitude = longitude;
		}
	}

	/** Adds a map overlay to a @MapView

	To overlay the map, you must decorate it with `MapOverlay` nodes. There are three type of overlay that supported Polyline, Polygon and Circle.
	In order to draw Overlay, it needs to define position where overlay should be drawn on the map using `Coordinate` property. See the example below on how you can create map overlay

	```HTML
	<NativeViewHost>
		<MapView Zoom="14" Latitude="-6.914742" Longitude="107.609820">
			<MapOverlay Type="Polyline" StrokeColor="Blue" LineWidth="5">
				<Coordinate Latitude="-6.914742" Longitude="107.609820" />
				<Coordinate Latitude="-6.915850" Longitude="107.609929" />
				<Coordinate Latitude="-6.916959" Longitude="107.611009" />
			</MapOverlay>
		</MapView>
	</NativeViewHost>
	```

	@seealso Fuse.Controls.MapView
	*/
	public class MapOverlay : Node, IPropertyListener
	{

		static Selector _latitudeName = "Latitude";
		static Selector _longitudeName = "Longitude";
		static Selector _coordinatesName = "Coordinates";
		static Selector _overlayTypeName = "OverlayType";
		static Selector _startCapName = "StartCap";
		static Selector _endCapName = "EndCap";
		static Selector _joinTypeName = "JoinType";
		static Selector _strokeColorName = "StrokeColor";
		static Selector _fillColorName = "FillColor";
		static Selector _lineWidthName = "LineWidth";
		static Selector _geodesicName = "Geodesic";
		static Selector _dashPatternName = "DashPattern";
		static Selector _centerLatitudeName = "CenterLatitude";
		static Selector _centerLongitudeName = "CenterLongitude";
		static Selector _radiusName = "Radius";

		void IPropertyListener.OnPropertyChanged(PropertyObject sender, Selector property)
		{
			MarkDirty();
		}

		OverlayType _overlayType = OverlayType.Polyline;
		/**
			The overlay type
		*/
		public OverlayType Type
		{
			get
			{
				return _overlayType;
			}

			set
			{
				if (_overlayType != value)
				{
					_overlayType = value;
					OnPropertyChanged(_overlayTypeName);
				}
			}
		}

		LineCap _startCap = LineCap.Round;
		/**
			The Start Cap of line
		*/
		public LineCap StartCap
		{
			get
			{
				return _startCap;
			}

			set
			{
				if (_startCap != value)
				{
					_startCap = value;
					OnPropertyChanged(_startCapName);
				}
			}
		}

		LineCap _endCap = LineCap.Round;
		/**
			The End Cap of line
		*/
		public LineCap EndCap
		{
			get
			{
				return _endCap;
			}

			set
			{
				if (_endCap != value)
				{
					_endCap = value;
					OnPropertyChanged(_endCapName);
				}
			}
		}

		LineJoin _joinType = LineJoin.Round;
		/**
			The Joint Type of line
		*/
		public LineJoin JoinType
		{
			get
			{
				return _joinType;
			}

			set
			{
				if (_joinType != value)
				{
					_joinType = value;
					OnPropertyChanged(_joinTypeName);
				}
			}
		}

		float4 _strokeColor = float4(1,0,0,1);
		/**
			The Stroke Color of overlay
		*/
		public float4 StrokeColor
		{
			get
			{
				return _strokeColor;
			}
			set
			{
				if (_strokeColor != value)
				{
					_strokeColor = value;
					OnPropertyChanged(_strokeColorName);
				}
			}
		}

		float4 _fillColor = float4(1,0,0,1);
		/**
			The Fill Color of overlay, only applicable on Polygon and Circle
		*/
		public float4 FillColor
		{
			get
			{
				return _fillColor;
			}
			set
			{
				if (_fillColor != value)
				{
					_fillColor = value;
					OnPropertyChanged(_fillColorName);
				}
			}
		}

		int _lineWidth = 2;
		/**
			The Line Width of overlay
		*/
		public int LineWidth
		{
			get
			{
				return _lineWidth;
			}
			set
			{
				if (_lineWidth != value)
				{
					_lineWidth = value;
					OnPropertyChanged(_lineWidthName);
				}
			}
		}

		bool _geodesic = false;
		/**
			Set whether to do geodesic draw on polyline
		*/
		public bool Geodesic
		{
			get
			{
				return _geodesic;
			}
			set
			{
				if (_geodesic != value)
				{
					_geodesic = value;
					OnPropertyChanged(_geodesicName);
				}
			}
		}

		int2 _dashPattern = int2(0,0);
		/**
			The dash pattern when drawing stroke, int2 type with first value define length of dash, and second value define length of gap
		*/
		public int2 DashPattern
		{
			get
			{
				return _dashPattern;
			}
			set
			{
				if (_dashPattern != value)
				{
					_dashPattern = value;
					OnPropertyChanged(_dashPatternName);
				}
			}
		}

		double _centerLatitude = 0;
		/**
			The center latitude coordinate, applicable when using Circle overlay type
		*/
		public double CenterLatitude {
			get
			{
				return _centerLatitude;
			}
			set
			{
				if (_centerLatitude != value)
				{
					_centerLatitude = value;
					OnPropertyChanged(_centerLatitudeName);
				}
			}
		}

		double _centerLongitude = 0;
		/**
			The center longitude coordinate, applicable when using Circle overlay type
		*/
		public double CenterLongitude {
			get
			{
				return _centerLongitude;
			}
			set
			{
				if (_centerLongitude != value)
				{
					_centerLongitude = value;
					OnPropertyChanged(_centerLongitudeName);
				}
			}
		}

		double _radius = 10;
		/**
			Radius of the circle overlay, pplicable when using Circle overlay type
		*/
		public double Radius
		{
			get
			{
				return _radius;
			}
			set
			{
				if (_radius != value)
				{
					_radius = value;
					OnPropertyChanged(_radiusName);
				}
			}
		}

		public MapOverlay()
		{
		}

		public MapOverlay(params Coordinate[] coordinates)
		{
			foreach (var s in coordinates)
				_coordinates.Add(s);
		}

		RootableList<Coordinate> _coordinates = new RootableList<Coordinate>();
		[UXContent]
		public IList<Coordinate> Coordinates
		{
			get
			{
				return _coordinates;
			}
		}

		void OnCoordinateAdded(Coordinate coord)
		{
			coord.AddPropertyListener(this);
			OnCoordinateChange();
		}

		void OnCoordinateRemoved(Coordinate coord)
		{
			coord.RemovePropertyListener(this);
			OnCoordinateChange();
		}

		void OnCoordinateChange()
		{
			if (_coordinates.Count > 0)
			{
				MarkDirty();
				OnPropertyChanged(_coordinatesName);
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (_coordinates != null)
				_coordinates.RootSubscribe(OnCoordinateAdded, OnCoordinateRemoved);
			MapView m = Parent as MapView;
			if(m != null)
				m.AddOverlay(this);
		}

		protected override void OnUnrooted()
		{
			MapView m = Parent as MapView;
			if(m != null)
				m.RemoveOverlay(this);
			if (_coordinates != null)
				_coordinates.Unsubscribe();
			base.OnUnrooted();
		}

		void MarkDirty()
		{
			MapView m = Parent as MapView;
			if(m != null)
				m.UpdateOverlaysNextFrame();
		}

		public double[] GetCordinatesArray()
		{
			var items = new double[Coordinates.Count * 2];
			var idx = 0;
			foreach(Coordinate p in Coordinates)
			{
				items[idx] = p.Latitude;
				items[idx + 1] = p.Longitude;
				idx+=2;
			}
			return items;
		}
	}
}