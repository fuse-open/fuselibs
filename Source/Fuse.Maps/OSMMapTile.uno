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

	internal class OSMMapTile : Panel
	{
		Fuse.Translation _trans;
		Fuse.Controls.Image[] _maps = new Fuse.Controls.Image[9];
		Fuse.Controls.Grid _grid;
		MarkerIconCache _markerGraphicsCache;

		const int GridSize = 3;
		public OSMMapTile()
		{
			_grid = new Fuse.Controls.Grid()
			{
				ColumnCount = GridSize
			};
			var i = 0;
			for (var y = 1; y < GridSize + 1; y++)
			{
				for (var x = 1; x < GridSize + 1; x++)
				{
					_maps[i] = new Fuse.Controls.Image()
					{
						Url = MakeUrl(2, x, y)
					};
					_grid.Add(_maps[i]);
					i++;
				}
			}
			_trans = new Fuse.Translation();
			var scaling = new Fuse.Scaling()
			{
				Factor=1.5f
			};
			Children.Add(_grid);
			Children.Add(_trans);
			Children.Add(scaling);
			_markerGraphicsCache = new MarkerIconCache(UpdateMarkers);
		}

		// http://wiki.openstreetmap.org/wiki/Zoom_levels
		// http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
		const String _tileserver = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
		public String MakeUrl (int zoom, int x, int y)
		{
			var s = _tileserver
					 .Replace("{s}", "{0}")
					 .Replace("{z}", "{1}")
					 .Replace("{x}", "{2}")
					 .Replace("{y}", "{3}");
			if (x < 0) return null;
			if (y < 0) return null;
			if (zoom < 0) return null;
			return String.Format(s, "a", zoom, x, y);
		}

		public ObservableList<MapMarker> Markers
		{
			get
			{
				return _mapview_parent.Markers;
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
				if (fs == null)
				{
					fs = new global::Uno.UX.BundleFileSource(import global::Uno.IO.BundleFile("./mappin.png"));
					m.IconAnchorY = 1;
					m.IconAnchorX = 0;
				}
				// The diff between the panel and the grid. Offset this to center the marker
				var diff = (ActualSize - _grid_size) / 2;
				var p = WorldToTilePos(m.Longitude, m.Latitude, (int)Zoom);

				// P is now relative to the top corner of the grid
				p -= _cornertile;
				// P is now in points, and not in ratios
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

		MapView _mapview_parent = null;
		protected override void OnRooted()
		{
			base.OnRooted();
			Placed += OnPlaced;
			_mapview_parent = Parent as MapView;
			if (_mapview_parent == null) {
				_mapview_parent.ClipToBounds = true;
				Fuse.Diagnostics.UserError( "OSMapTile needs a MapView as it's parent", Parent );
			}
		}

		protected override void OnUnrooted()
		{
			_mapview_parent = null;
			Placed -= OnPlaced;
			base.OnUnrooted();
		}

		float _grid_size = 0;
		public void OnPlaced(object sender, PlacedArgs args)
		{
			var s = Math.Min(ActualSize.X, ActualSize.Y);
			_grid.Width = new Size(s, Unit.Points);
			_grid.Height = new Size(s, Unit.Points);
			_grid_size = s;
			UpdateMap();
		}

		public double Longitude
		{
			get
			{
				if (_mapview_parent != null)
				{
					return _mapview_parent.Longitude;
				}
				return 0;
			}
			set
			{
				if (_mapview_parent != null)
				{
					_mapview_parent.Longitude = value;
				}
			}
		}

		public double Latitude
		{
			get
			{
				if (_mapview_parent != null)
				{
					return _mapview_parent.Latitude;
				}
				return 0;
			}
			set
			{
				if (_mapview_parent != null)
				{
					_mapview_parent.Latitude = value;
				}
			}
		}

		public double Zoom
		{
			get
			{
				if (_mapview_parent != null)
				{
					return _mapview_parent.Zoom;
				}
				return 2;
			}
			set
			{
				if (_mapview_parent != null)
				{
					_mapview_parent.Zoom = value;
				}
			}
		}

		float2 _tilepos = float2(0);
		float2 _cornertile = int2(0);
		public void UpdateMap()
		{
			if (_mapview_parent == null) return;
			var p = WorldToTilePos(Longitude, Latitude, (int)Zoom);
			_tilepos = p;
			var i = 0;
			var tmp = Math.Floor(p);
			_cornertile = (int2)tmp - 1; // Have the corner one to the left and above the center of the map

			// Calculate offset (adjustment) of tile, compared to center of map:
			var adj = float2(0.5f) - (p - tmp);
			adj = adj * _maps[4].ActualSize;
			_trans.XY = adj;

			for (var y = (int)p.Y - 1; y < (int)p.Y + 2; y++)
			{
				for (var x = (int)p.X - 1; x < (int)p.X + 2; x++)
				{
					_maps[i].Url = MakeUrl((int)Zoom, x, y);
					i++;
				}
			}
			UpdateMarkers();
		}

		// C# convert world position to tile position
		// http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#C.23
		public float2 WorldToTilePos(double lon, double lat, int zoom)
		{
			float2 p = float2(0);
			p.X = (float)((lon + 180.0) / 360.0 * Math.Pow(2,zoom));
			p.Y = (float)((1.0 - Math.Log(Math.Tan(lat * Math.PI / 180.0) + 
				1.0 / Math.Cos(lat * Math.PI / 180.0)) / Math.PI) / 2.0 * Math.Pow(2,zoom));
				
			return p;
		}

		// C# convert tile position to world position
		// http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#C.23
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
