using Uno.UX;
using Fuse.Scripting;
using Uno.Collections;

namespace Fuse.Reactive.FuseJS
{
	/**
		@scriptmodule FuseJS/Maps

		Lanches the map application using the provided `latitude`/`longitude` pair and/or `query`.

		You need to add a reference to `Fuse.Launcher` in your project file to use this feature.

		## Example

		This code will launch a map centered at the nearest pizza restaurant.

			var Maps = require("FuseJS/Maps");
			Maps.searchNear(59.9117715, 10.7400957, "pizza restaurant");
	*/
	[UXGlobalModule]
	public sealed class Maps : NativeModule
	{
		static readonly Maps _instance;

		public Maps()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Maps");
			AddMember(new NativeFunction("openAt", OpenAt));
			AddMember(new NativeFunction("searchNearby", SearchNearby));
			AddMember(new NativeFunction("searchNear", SearchNear));
		}

		/**
			@scriptmethod searchNearby
			@param query (String)

			Launches the map application, centered at the location found using `query` as search criteria.

			## Example

				var Maps = require("FuseJS/Maps");
				Maps.searchNearby("Fusetools");
		*/
		public static object SearchNearby(Scripting.Context context, object[] args)
		{
			var query = (string)args[0];
			Fuse.LauncherImpl.MapsLauncher.LaunchMaps(query);
			return null;
		}

		/**
			@scriptmethod searchNear
			@param latitude (double)
			@param longitude (double)
			@param query (String)

			Launches the map application, centered at the location found nearby the given `latitude` and `longitude`,
			using `query` as search criteria.

			## Example

				var Maps = require("FuseJS/Maps");
				Maps.searchNear(59.9117715, 10.7400957, "Fusetools");
		*/
		public static object SearchNear(Scripting.Context context, object[] args)
		{
			var latitude = Marshal.ToDouble(args[0]);
			var longitude = Marshal.ToDouble(args[1]);
			var query = (string)args[2];
			Fuse.LauncherImpl.MapsLauncher.LaunchMaps(latitude, longitude, query);
			return null;
		}

		/**
			@scriptmethod openAt
			@param latitude (double)
			@param longitude (double)

			Launches the map application, centered at the location given by `latitude` and `longitude`.

			## Example

				var Maps = require("FuseJS/Maps");
				Maps.openAt(59.9117715, 10.7400957);
		*/
		public static object OpenAt(Scripting.Context context, object[] args)
		{
			var latitude = Marshal.ToDouble(args[0]);
			var longitude = Marshal.ToDouble(args[1]);
			Fuse.LauncherImpl.MapsLauncher.LaunchMaps(latitude, longitude);
			return null;
		}
	}
}
