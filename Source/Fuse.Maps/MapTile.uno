using Fuse.Elements;
using Uno.UX;
using Uno;
using Fuse.Maps;
using Uno.Collections;

namespace Fuse.Controls
{
	/** A polyfill for Native @MapView

	This is not meant to be a full implementation, but just something that will help you when developing on local preview.

	This should also work as a standalone component, so it can be used on native.block

	This uses the OSM tile server, and that has both a usage policy https://operations.osmfoundation.org/policies/tiles/ and a license https://www.openstreetmap.org/copyright .

	The mappin is from wikipedia https://commons.wikimedia.org/wiki/File:Map_pin_icon.svg and is Creative Commons Attribution-Share Alike 3.0 Unported. 

	@seealso Fuse.Controls.MapView
	*/

	public class MapTile : Panel
	{
		Fuse.Translation trans;
		Fuse.Controls.Image[] maps = new Fuse.Controls.Image[9];
		Fuse.Controls.Grid grid;
		MarkerIconCache _markerGraphicsCache;

		public MapTile()
		{
			grid = new Fuse.Controls.Grid()
			{
				ColumnCount = 3
			};
			var i = 0;
			for (var y = 1; y < 4; y++) {
				for (var x = 1; x < 4; x++) {
					maps[i] = new Fuse.Controls.Image()
					{
						Url = MakeUrl(2, x, y)
					};
					grid.Add(maps[i]);
					i++;
				}
			}
			trans = new Fuse.Translation();
			var scaling = new Fuse.Scaling()
			{
				Factor=1.5f
			};
			Children.Add(grid);
			Children.Add(trans);
			Children.Add(scaling);
			Placed += OnPlaced;
			_markerGraphicsCache = new MarkerIconCache(UpdateMarkers);
		}

		// http://wiki.openstreetmap.org/wiki/Zoom_levels
		// http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
		String _tileserver = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
		public String TileServer
		{
			get { return _tileserver; }
			set { _tileserver = value; }
		}

		public String MakeUrl (int zoom, int x, int y)
		{
			var s = TileServer
						.Replace("{s}", "{0}")
						.Replace("{z}", "{1}")
						.Replace("{x}", "{2}")
						.Replace("{y}", "{3}");
			if (x < 0) return null;
			if (y < 0) return null;
			if (zoom < 0) return null;
			debug_log(String.Format(s, "a", zoom, x, y));
			return String.Format(s, "a", zoom, x, y);
		}

		public ObservableList<MapMarker> Markers
		{
			get
			{
				MapView m = Parent as MapView;
				if (m != null)
				{
					return m.Markers;
				}
				return null;
			}
		}

		public void ClearMarkers ()
		{
			foreach(var i in _markers)
			{
				Children.Remove(i);
			}
			_markers.Clear();
		}

		List<Fuse.Controls.Image> _markers = new List<Fuse.Controls.Image>();
		public void UpdateMarkers()
		{
			ClearMarkers();
			foreach(MapMarker m in Markers)
			{
				FileSource fs = m.IconFile;
				if (fs == null) {
					fs = new global::Uno.UX.BundleFileSource(import global::Uno.IO.BundleFile("./mappin.png"));
					m.IconAnchorY = 1;
					m.IconAnchorX = 0;
				}
				// The diff between the panel and the grid. Offset this to center the marker
				var diff = (ActualSize - _grid_size) / 2;
				var p = WorldToTilePos(m.Longitude, m.Latitude, (int)Zoom);

				// P is now relative to the top corner of the grid
				p -= _cornertile;
				// P is now in pixels
				p = p * (_grid_size / 3);
				p += diff;

				var i = new Fuse.Controls.Image()
				{
					File = fs,
					Width = 10,
					X = p.X,
					Y = p.Y
				};
				var _trans = new Fuse.Translation()
				{
					RelativeNode = i,
					RelativeTo   = Fuse.TranslationModes.Size,
					X = m.IconAnchorX - 0.5f,
					Y = m.IconAnchorY * -1
				};

				Children.Add(i);
				BringToFront(i);
				i.Children.Add(_trans);
				_markers.Add(i);
			}
		}

		bool ready = false;
		protected override void OnRooted()
		{
			base.OnRooted();
			MapView m = Parent as MapView;
			m.ClipToBounds = true;
			ready = true;
		}

		float _grid_size = 0;
		public void OnPlaced(object sender, PlacedArgs args)
		{
			var s = Math.Min(ActualSize.X, ActualSize.Y);
			grid.Width = s;
			grid.Height = s;
			_grid_size = s;
			UpdateMap();
		}

		double _lng = 0;
		public double Longitude
		{
			get
			{
				MapView m = Parent as MapView;
				if (m != null) {
					_lng = m.Longitude; 
				}
				return _lng;
			}
			set
			{
				_lng = value;
				MapView m = Parent as MapView;
				if (m != null)
				{
					m.Longitude = value; 
				}
				else {
					UpdateMap();
				}
			}
		}

		double _lat = 0;
		public double Latitude
		{
			get
			{
				MapView m = Parent as MapView;
				if (m != null)
				{
					_lat = m.Latitude; 
				}
				return _lat;
			}
			set
			{
				_lat = value;
				MapView m = Parent as MapView;
				if (m != null)
				{
					m.Latitude = value; 
				}
				else
				{
					UpdateMap();
				}
			}
		}

		double _zoom = 2;
		public double Zoom
		{
			get
			{
				MapView m = Parent as MapView;
				if (m != null)
				{
					_zoom = m.Zoom; 
				}
				return _zoom;
			}
			set
			{
				_zoom = value;
				MapView m = Parent as MapView;
				if (m != null)
				{
					m.Zoom = value; 
				}
				else
				{
					UpdateMap();
				}
			}
		}

		float2 _tilepos = float2(0);
		float2 _cornertile = float2(0);
		public void UpdateMap()
		{
			MapView m = Parent as MapView;
			if (m == null) return;
			var p = WorldToTilePos(Longitude, Latitude, (int)Zoom);
			_tilepos = p;
			var i = 0;
			_cornertile.X = Math.Floor(p.X - 1);
			_cornertile.Y = Math.Floor(p.Y - 1);
			for (var y = (int)p.Y - 1; y < (int)p.Y + 2; y++)
			{
				for (var x = (int)p.X - 1; x < (int)p.X + 2; x++)
				{
					maps[i].Url = MakeUrl((int)Zoom, x, y);
					i++;
				}
			}
			var adj = float2(0.5f);
			adj.X -= p.X - Math.Floor(p.X);
			adj.Y -= p.Y - Math.Floor(p.Y);
			adj = adj * maps[4].ActualSize; 
			trans.XY = adj;
			UpdateMarkers();
		}

		public float2 WorldToTilePos(double lon, double lat, int zoom)
		{
			float2 p = float2(0);
			p.X = (float)((lon + 180.0) / 360.0 * (1 << zoom));
			p.Y = (float)((1.0 - Math.Log(Math.Tan(lat * Math.PI / 180.0) + 
				1.0 / Math.Cos(lat * Math.PI / 180.0)) / Math.PI) / 2.0 * (1 << zoom));
				
			return p;
		}

		public float2 TileToWorldPos(double tile_x, double tile_y, int zoom) 
		{
			float2 p = float2(0);
			double n = Math.PI - ((2.0 * Math.PI * tile_y) / Math.Pow(2.0, zoom));

			p.X = (float)((tile_x / Math.Pow(2.0, zoom) * 360.0) - 180.0);
			p.Y = (float)(180.0 / Math.PI * Math.Atan(Math.Sin(n)));

			return p;
		}
	}
}
