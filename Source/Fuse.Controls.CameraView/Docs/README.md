This package provides a cross-platform abstraction over the native camera APIs on Android and iOS. In order to use this package you must add a reference to `Fuse.Controls.CameraView` in your `unoproj`.

The `CameraView` API is mostly exposed as a [`Promise`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) based API in JavaScript. Lets have a look at how to get up and running:

```
<DockPanel>
    <NativeViewHost Dock="Fill">
        <!-- The size and aspect of the camera live preview
             does not always match they size your cameraview
             is given by layout. Set stretchmode to either Uniform
             or Fill to deal with this
         -->
        <CameraView ux:Name="_cameraView" StretchMode="Fill" />
        <JavaScript>
            var Observable = require("FuseJS/Observable");
            var Camera = _cameraView;

            // Observables for dealing with
            // the different states of the camera
            var captureMode = Observable();
            var cameraFacing = Observable();
            var flashMode = Observable();
            var cameraReady = Observable(false);

            // getCamereInfo will resolve when the camera is fully loaded
            Camera.getCameraInfo()
                .then(function(info) {
                    captureMode.value = info[Camera.INFO_CAPTURE_MOE];
                    cameraFacing.value = info[Camera.INFO_CAMERA_FACING];
                    flashMode.value = info[Camera.INFO_FLASH_MODE];
                    cameraReady.value = true;
                })
                .catch(function(error) {
                    console.log("Failed to get camera info: " + error);
                });
        </JavaScript>
    </NativeViewHost>
</DockPanel>
```
The `<CameraView />` tag is the UI element that will display a live preview from the camera. The camera is loading asynchronously and the `getCameraInfo` promise wont resolve until it is loaded. This can be used to reflect if the camera is ready and its initial state in your UI.

### Capturing a photo

To capture a photo, make sure the camera is loaded as discussed above and set its capture mode to photo. If a photo capture was successful you will get an object representing the native photo result, you can call `save()` to store the photo on disk and get a filepath. A photo may require a lot of memory on your device, make sure to call `release()` on it when you are done using it. It is considered bad practice to keep many photo objects around as this can lead to out-of-memory crashes.

```js
Camera.setCaptureMode(Camera.CAPTURE_MODE_PHOTO)
    .then(function(newCaptureMode) { /* ready to capture photo */ })
    .catch(function(error) { /* failed */ });

function capturePhoto() {
    Camera.capturePhoto()
        .then(function(photo) {
            photo.save()
                .then(function(filePath) {
                    console.log("Photo saved to: " + filePath);
                    photo.release();
                })
                .catch(function(error) {
                    console.log("Failed to save photo: " + error);
                    photo.release();
                });
        })
        .catch(function(error) {
            console.log("Failed to capture photo: " + error);
        });
}
```

### Recording video

Make sure the capture mode is set to video. When you start a recording you get a session object which you need to hold onto. When you call `stop()` on the recording session you will get a file path to the result.

```js
Camera.setCaptureMode(Camera.CAPTURE_MODE_VIDEO)
    .then(function(newCaptureMode) { /* ready to record video */ })
    .catch(function(error) { /* failed */ });

var recordingSession = null;

function startRecording() {
    Camera.startRecording()
        .then(function(session) {
            console.log("Video recording started!");
            recordingSession = session;
        })
        .catch(function(error) {
            console.log("Failed to start recording: " + error);
        });
}

function stopRecording() {
    if (session == null)
        return;

    session.stop()
        .then(function(recording) {
            console.log("Recording stopped, saved to: " + recording.filePath());
            session = null;
        })
        .catch(function(error) {
            console.log("Failed to stop recording: " + error);
            session = null;
        });
}
```

### Change camera facing

You can change the camera facing when the camera is not busy. For example, you cannot change camera facing while recording video or capturing a photo.

```js
var currentFacing = Camera.CAMERA_FACING_BACK;

function flipFacing() {
    var facing = currentFacing == Camera.CAMERA_FACING_BACK
        ? Camera.CAMERA_FACING_FRONT
        : Camera.CAMERA_FACING_BACK;

    Camera.setCameraFacing(facing)
        .then(function(newCameraFacing) {
            console.log("Camera facing set to: " + newCameraFacing);
        })
        .catch(function(error) {
            console.log("Failed to set camera facing: " + error);
        });
}
```


### Set photo resolution (Android only)

On iOS you cannot specify an output resoltuion for captured photos, however on Android you must specify what resolution you want your photos captured in. There is no sensible default value, so if not explicilty set this abstraction will chose a resolution based on the current aspect ratio of your `<CameraView />`. But you have the option to set this yourself, although that code will only work on Android.

```js
Camera.getCameraInfo()
    .then(function(info) {
        // If we are running on android, the info object should contain
        // an array of available resolutions for the current camera facing
        if (Camera.INFO_PHOTO_RESOLUTIONS in info) {

            var supportedResolutions = info[Camera.INFO_PHOTO_RESOLUTIONS];

            // Make a function that picks the resolution you want
            var resolution = pickResolution(supportedResolutions);

            // Put your resolution in an object with the photo resolution key
            var options = {};
            options[Camera.OPTION_PHOTO_RESOLUTION] = resolution;

            Camera.setPhotoOptions(options)
                .then(function() { /* success */ })
                .catch(function(error) {
                    console.log("Failed to set photo options: " + error);
                });
        }
    });
```