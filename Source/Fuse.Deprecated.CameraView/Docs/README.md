# Creating a CameraView

This package is intended to allow you to create a camera preview view as part of your Fuse application.

In order to use this package, you must add `Fuse.Deprecated.CameraView` to your `unoproj` file.


The simplest way to use this library it to embed a `<CameraView>` inside your application. For example:

```
<Panel Height="400">
	<NativeViewHost >
		<CameraView ux:Name="cameraView" Facing="Front">
		</CameraView>
	</NativeViewHost>
</Panel>
```

You should give the view a name, as the majority of the interactions are done through Javascript. For example, if you wished to take a picture, then you must do the following:

```js
cameraView.takePicture({
	callback: function(err, image){
		console.log("Took an image and saved it to " + JSON.stringify(image));
	}
});
```

A @CameraView is intended to be used to display a live preview from a capture device in your Fuse application.

A `CameraView` can then take a picture or video from the current capture device. The resolution of the image taken will be the closest possible resolution to that of the preview. Note that camera devices do not support capturing images at arbitrary resolutions, therefore the capture of the image will not be exactly the same as your preview. A captured image can be resized through the use of `ImageTools`. 


## Image capture


In order to capture an image, you must have a visibile `CameraView`. 

```
<MemoryPolicy ux:Global="UnloadImmediately" UnloadInBackground="True" UnusedTimeout="1" UnpinInvisible="True" />

<JavaScript>
	var Observable = require("FuseJS/Observable");
	var image = Observable("");

	function takePicture() {
		cameraPanel.takePicture({callback: function(err, img) {
			if (img !== null) {
				// do things with the image
				image.value = img.path;
			}
		}});
	}

	function discardPicture() {
		image.value = "";
	}

	module.exports = {
		image: image,
		takePicture: takePicture,
		discardPicture: discardPicture
	};
</JavaScript>

<WhileString Value="{image}" Equals="">
	<NativeViewHost>
		<Button Text="Take picture" Clicked="{takePicture}" />
		<CameraView ux:Name="cameraPanel" />
	</NativeViewHost>
</WhileString>
<WhileString Value="{image}" Equals="" Invert="true">
	<Image File="{image}" MemoryPolicy="UnloadImmediately" Clicked="{discardPicture}">
		<Rotation Degrees="90" />
	</Image>
</WhileString>
```

Once you have captured an image, the best way to preview the captured image is to use an @Image tag. When using a short-lived preview image, it is important to use a memory policy that discards the image from memory after displaying it. In this example, we used a custom @MemoryPolicy with a timeout of a second to achieve this.


## Video capture

Video capture works similiarly to taking a picture. You must tell the camera to start recording and when to finish recording. If you change the direction of the camera during recording, then the old recording will be stopped, and a new recording will start. If you try to start recording during already recording, the old recording will be stopped.



## Changing direction of the camera

It's possible to set the direction of the camera through using the `Facing` property. The example below faces the front. If the direction is not supported by the device, then the camera panel will not display a preview.

```
<CameraView Facing="Front"/>
```


## Notes
- The image return will currently be rotated 90 degrees to the left, or 270 degrees to the right. This is due to the way that the native camera APIs function.
- If a picture is taken while waiting for the `takePicture` callback to complete, the first picture will be cancelled. 
- Only a single CameraView should be created at one time. This is due to the fact that not all platforms correctly support streaming from multiple cameras at once. 
- It is recommended you use `ImageTools` and `CameraRoll` in order to copy the output image files.