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
				new ScriptMethod<MapView>("setMarkers", setMarkers));
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
					if (args[0] is Fuse.Scripting.Array)
					{
						SetMarkersWithArray(view, args[0] as IArray);
					}
					else if(args[0] is Fuse.Scripting.Object)
					{
						view.AddMarker(MarkerFromObject(args[0] as IObject));
					}
					break;
				default:
					foreach(object ob in args)
					{
						if(ob is Fuse.Scripting.Object)
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
