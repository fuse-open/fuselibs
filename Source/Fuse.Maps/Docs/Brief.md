The `MapView` allows you to present annotated, interactive world-wide maps to the user using the mapping APIs native to the platform: Google Maps on Android and Apple Maps on iOS.

The `MapView` is a native control, and thus needs to be contained in a @NativeViewHost to be displayed. As with other native mobile controls, there currently isn't a `MapView` available for desktop targets.

*Note:* You need to add a reference to `Fuse.Maps` in the `Packages` section of your `.unoproj`:

```
"Packages": [
	"Fuse.Maps",
	"Fuse",
	"FuseJS"
]
```

Getting a `MapView` included in your app is straight forward: Simply include the node in your UX as you normally would with a native control:

```XML
<NativeViewHost>
	<MapView/>
</NativeViewHost>
```

To initialize and manipulate the map camera, use the [Latitude](api:fuse/controls/mapview/latitude), [Longitude](api:fuse/controls/mapview/longitude), [Zoom](api:fuse/controls/mapview/zoom), [Tilt](api:fuse/controls/mapview/tilt) and [Bearing](api:fuse/controls/mapview/bearing) properties, all of which are two-way bindable.
`Zoom` follows Google's "zoom levels", which can be read about in detail [here](https://developers.google.com/maps/documentation/static-maps/intro#Zoomlevels).

The map can be further customized by setting the rendering style using the [Style](api:fuse/controls/mapview/style) property.
Options are `Normal`, `Satellite` and `Hybrid`.

To annotate the map with labelled markers, see @MapMarker

## Maps on Android

Google Maps requires a valid Google Maps API key. Follow [Google's documentation](https://developers.google.com/maps/documentation/android-api/signup) to get one set up. Once you have your key it must be added to your project file, as shown below

```JSON
"Android": {
   "Geo": {
        "ApiKey": "your_key_here"
    }
}
```
