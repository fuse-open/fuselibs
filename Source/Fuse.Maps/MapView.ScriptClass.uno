using Uno;
using Uno.UX;
using Uno.Collections;

using Fuse.Scripting;

namespace Fuse.Controls
{
	public partial class MapView
	{
		static MapView()
		{
			ScriptClass.Register(typeof(MapView),
				new ScriptMethod<MapView>("setLocation", setLocation),
				new ScriptMethod<MapView>("setBearing", setBearing),
				new ScriptMethod<MapView>("setTilt", setTilt),
				new ScriptMethod<MapView>("setZoom", setZoom),
				new ScriptMethod<MapView>("setMarkers", setMarkers),
				new ScriptMethod<MapView>("setOverlays", setOverlays));
		}

		/** Sets the geographical location the MapView is focused on.

			@scriptMethod setLocation(latitude, longitude)
			@param latitude (number) The latitude coordinate to pan to.
			@param longitude (number) The longitude coordinate to pan to.
		*/
		static void setLocation(MapView view, object[] args)
		{
			switch(args.Length)
			{
				case 2:
					view.Latitude = Marshal.ToDouble(args[0]);
					view.Longitude = Marshal.ToDouble(args[1]);
					return;
				default:
					Fuse.Diagnostics.UserError( "MapView.setLocation requires 2 number arguments", view );
					return;
			}
		}

		/** Sets the [Bearing](api:fuse/controls/mapview/bearing) of a MapView.

			@scriptmethod setBearing(bearing)
			@param bearing (number) The desired [Bearing](api:fuse/controls/mapview/bearing).
		*/
		static void setBearing(MapView view, object[] args)
		{
			switch(args.Length)
			{
				case 1:
					view.Bearing = Marshal.ToDouble(args[0]);
					return;
				default:
					Fuse.Diagnostics.UserError( "MapView.setBearing requires 1 number argument", view );
					return;
			}
		}

		/** Sets the [Tilt](api:fuse/controls/mapview/tilt) angle of a MapView.

			@scriptmethod setTilt(tilt)
			@param tilt (number) The desired [Tilt](api:fuse/controls/mapview/tilt) angle.
		*/
		static void setTilt(MapView view, object[] args)
		{
			switch(args.Length)
			{
				case 1:
					view.Tilt = Marshal.ToDouble(args[0]);
					return;
				default:
					Fuse.Diagnostics.UserError( "MapView.setTilt requires 1 number argument", view );
					return;
			}
		}

		/** Sets the [Zoom](api:fuse/controls/mapview/zoom) level of a MapView.

			@scriptmethod setZoom(zoom)
			@param zoom (number) The desired [Zoom](api:fuse/controls/mapview/zoom) level.
		*/
		static void setZoom(MapView view, object[] args)
		{
			switch(args.Length)
			{
				case 1:
					view.Zoom = Marshal.ToDouble(args[0]);
					return;
				default:
					Fuse.Diagnostics.UserError( "MapView.setZoom requires 1 number argument", view );
					return;
			}
		}

		/** Replaces the MapView's overlays.

			@scriptmethod setOverlays(overlays)
			@param overlays (Object|Array) Either a single object describing a map overlay, or an array of them.

			The following format is used for describing map markers:

				{
					lineWidth: 2,
					strokeColor: '#348',
					fillColor: '#348',
					overlayType: 'polygon', // or polyline
					startCap: 'round', // available round, butt, square
					endCap: 'round,' // available round, butt, square
					lineJoin: 'miter', // available round, bevel, miter
					coordinates: [
						{ latitude: 59.911567, longitude: 10.741030 },
						{ latitude: 60.011567, longitude: 10.941030 },
						{ latitude: 60.111567, longitude: 11.001030 },
					]
				}

			## Example

			The following example places a map overlay

				<NativeViewHost>
					<MapView ux:Name="myMapView" />
				</NativeViewHost>

				<JavaScript>
					myMapView.setOverlays([
						{
							lineWidth: 2,
							strokeColor: '#348',
							fillColor: '#348',
							overlayType: 'polygon',
							coordinates: [
								{ latitude: 59.911567, longitude: 10.741030 },
								{ latitude: 60.011567, longitude: 10.941030 },
								{ latitude: 60.111567, longitude: 11.001030 },
							]
						}
					]);
				</JavaScript>

		*/
		static void setOverlays(MapView view, object[] args)
		{
			view._overlays.Clear();
			switch(args.Length)
			{
				case 1:
					if (args[0] is IArray)
					{
						SetOverlaysWithArray(view, args[0] as IArray);
					}
					else if(args[0] is IObject)
					{
						view.AddOverlay(OverlayFromObject(view, args[0] as IObject));
					}
					break;
				default:
					foreach(object ob in args)
					{
						if(ob is IObject)
							view.AddOverlay(OverlayFromObject(view, ob as IObject));
						else{
							Fuse.Diagnostics.UserError( "MapView overlays should follow the format { lineWidth:3, strokeColor:\"blue\", fillColor:\"blue\", type:\"polyline\", coordinates:[{latitude: -6.90343, longitude: 107.346424}, {latitude: -6.94343, longitude: 107.396424}] }", view );
							break;
						}
					}
					break;
			}
			view.UpdateOverlays();
		}

		static void SetOverlaysWithArray(MapView view, IArray a)
		{
			for(int i = 0; i < a.Length; i++)
			{
				var item = a[i] as IObject;
				if(item!=null)
					view.AddOverlay(OverlayFromObject(view, item));
			}
		}

		static MapOverlay OverlayFromObject(MapView view, IObject o)
		{
			var m = new MapOverlay();
			foreach(string key in o.Keys)
			{
				var lowerkey = key.ToLower();
				if (lowerkey=="linewidth")
				{
					m.LineWidth = Marshal.ToInt(o[key]);
				}
				else if (lowerkey=="strokecolor")
				{
					var strokeColor = float4(1, 0, 0, 1);
					Marshal.TryToColorFloat4(o[key], out strokeColor);
					m.StrokeColor = strokeColor;
				}
				else if (lowerkey=="fillcolor")
				{
					var fillColor = float4(1, 0, 0, 1);
					Marshal.TryToColorFloat4(o[key], out fillColor);
					m.FillColor = fillColor;
				}
				else if (lowerkey=="overlaytype")
				{
					var type = o[key] as string;
					var lowertype = type.ToLower();
					if (lowertype == "polyline")
						m.Type = OverlayType.Polyline;
					else if (lowertype == "polygon")
						m.Type = OverlayType.Polygon;
					else if (lowertype == "circle")
						m.Type = OverlayType.Circle;
					else
						Fuse.Diagnostics.UserError("Invalid OverlayType. Expected value are : Polyline, Polygon, Circle", view );
				}
				else if (lowerkey=="startcap")
				{
					var type = o[key] as string;
					var lowertype = type.ToLower();
					if (lowertype == "square")
						m.StartCap = LineCap.Square;
					else if (lowertype == "butt")
						m.StartCap = LineCap.Butt;
					else
						m.StartCap = LineCap.Round;
				}
				else if (lowerkey=="endcap")
				{
					var type = o[key] as string;
					var lowertype = type.ToLower();
					if (lowertype == "square")
						m.EndCap = LineCap.Square;
					else if (lowertype == "butt")
						m.EndCap = LineCap.Butt;
					else
						m.EndCap = LineCap.Round;
				}
				else if (lowerkey=="jointype")
				{
					var type = o[key] as string;
					var lowertype = type.ToLower();
					if (lowertype == "bevel")
						m.JoinType = LineJoin.Bevel;
					else if (lowertype == "miter")
						m.JoinType = LineJoin.Miter;
					else
						m.JoinType = LineJoin.Round;
				}
				else if (lowerkey=="dashpattern")
				{
					var dashPattern = o[key] as IArray;
					if (dashPattern != null)
					{
						if (dashPattern.Length > 1)
							m.DashPattern = int2(Marshal.ToInt(dashPattern[0]), Marshal.ToInt(dashPattern[1]));
					}
				}
				else if(lowerkey=="centerlatitude")
				{
					m.CenterLatitude = Marshal.ToDouble(o[key]);
				}
				else if(lowerkey=="centerlongitude")
				{
					m.CenterLongitude = Marshal.ToDouble(o[key]);
				}
				else if(lowerkey=="radius")
				{
					m.Radius = Marshal.ToDouble(o[key]);
				}
				else if (lowerkey=="coordinates")
				{
					var coordinates = o[key] as IArray;
					if (coordinates != null)
					{
						for(int i = 0; i < coordinates.Length; i++)
						{
							var coordinate = coordinates[i] as IObject;
							if (coordinate != null)
							{
								var coord = new Coordinate();
								foreach(string coordKey in coordinate.Keys)
								{
									var lowerCoordKey = coordKey.ToLower();
									if (lowerCoordKey=="latitude")
									{
										coord.Latitude = Marshal.ToDouble(coordinate[coordKey]);
									}
									else if (lowerCoordKey=="longitude")
									{
										coord.Longitude = Marshal.ToDouble(coordinate[coordKey]);
									}
								}
								m.Coordinates.Add(coord);
							}
						}
					}
				}

			}
			return m;
		}

		/** Replaces the MapView's markers.

			@scriptmethod setMarkers(markers)
			@param markers (Object|Array) Either a single object describing a map marker, or an array of them.

			The following format is used for describing map markers:

				{
					latitude: 0,
					longitude: 0,
					label: "Hello, world!"
				}

			## Example

			The following example places a map marker at Fuse's home in Oslo, Norway.

				<NativeViewHost>
					<MapView ux:Name="myMapView" />
				</NativeViewHost>

				<JavaScript>
					myMapView.setMarkers([
						{ latitude: 59.911567, longitude: 10.741030, label: "Fuse HQ" }
					]);
				</JavaScript>

		*/
		static void setMarkers(MapView view, object[] args)
		{
			view._markers.Clear();
			switch(args.Length)
			{
				case 1:
					if (args[0] is IArray)
					{
						SetMarkersWithArray(view, args[0] as IArray);
					}
					else if(args[0] is IObject)
					{
						view.AddMarker(MarkerFromObject(args[0] as IObject));
					}
					break;
				default:
					foreach(object ob in args)
					{
						if(ob is IObject)
							view.AddMarker(MarkerFromObject(ob as IObject));
						else{
							Fuse.Diagnostics.UserError( "MapView markers should follow the format { latitude:0.0, longitude:0.0, label:\"MyLabel\" }", view );
							break;
						}
					}
					break;
			}
			view.UpdateMarkers();

		}

		static void SetMarkersWithArray(MapView view, IArray a)
		{
			for(int i = 0; i < a.Length; i++)
			{
				var item = a[i] as IObject;
				if(item!=null)
					view.AddMarker(MarkerFromObject(item));
			}
		}

		static MapMarker MarkerFromObject(IObject o)
		{
			var m = new MapMarker();
			foreach(string key in o.Keys)
			{
				var lowerkey = key.ToLower();
				if(lowerkey=="latitude")
				{
					m.Latitude = Marshal.ToDouble(o[key]);
				}
				else if(lowerkey=="longitude")
				{
					m.Longitude = Marshal.ToDouble(o[key]);
				}
				else if(lowerkey=="label")
				{
					m.Label = o[key] as string;
				}
				else if(lowerkey=="iconfile")
				{
					m.IconFile = Marshal.ToType<FileSource>(o[key] as string);
				}
				else if(lowerkey=="iconanchorx")
				{
					m.IconAnchorX = Marshal.ToFloat(o[key]);
				}
				else if(lowerkey=="iconanchory")
				{
					m.IconAnchorY = Marshal.ToFloat(o[key]);
				}
			}
			return m;
		}

	}
}
