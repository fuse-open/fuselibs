# Unreleased

# 1.1

## 1.1.0

### Fuse.Launchers
- Fixed bug on iOS where URIs were incorrectly encoded, leading to some input with reserved URI-characters misbehaving.

### ImageTools
- Fixed bug in Android implementation that could result in errors due to prematurely recycled bitmaps

### FuseJS/Bundle
- Added `.list()` to fetch a list of all bundled files
- Added `.readBuffer()` to read a bundle as an ArrayBuffer
- Added `.extract()` to write a bundled file into a destination path

### Image
- A failed to load Image with a Url will now try again when the Url is used again in a new Image
- Added `reload` and `retry` JavaScript functions on `Image` to allow reloading failed images.
- Fixed infinite recursion bug that could happen if a MemoryPolicy is set on a MultiDensityImageSource

### ScrollingAnimation
- Fixed issue where the animation could become out of sync if the properties on ScrollingAnimation were updated.

### macOS SIGILL problems
- Updated the bundled Freetype library on macOS to now (again) include both 32-bit and 64-bit symbols, which fixes an issue where .NET and preview builds would crash with a SIGILL at startup when running on older Mac models.
- Updated the bundled libjpeg, libpng, Freetype, and SDL2 libaries for macOS to not use AVX instructions, since they are incompatible with the CPUs in some older Mac models. This fixes an issue with SIGILLs in native builds.

### Native
- Added feature toggle for implicit `GraphicsView`. If you are making an app using only Native UI disabling the implicit `GraphicsView` can increase performance. Disable the `GraphicsView` by defining `DISABLE_IMPLICIT_GRAPHICSVIEW` when building. For example `uno build -t=ios -DDISABLE_IMPLICIT_GRAPHICSVIEW`

### Gestures
- Fuse.Input.Gesture now only has an internal constructor. This means that external code can't instantiate it. But before, they already couldn't do so in a *meaningful* way, so this shouldn't really affect any applications.

### Native TextInput
- Fixed issue where focusing a `<TextInput />` or `<TextView />` by tapping it would not update the caret position accordingly. 

### Route Navigation Triggers
- `Activated`, `Deactivated`, `WhileActive`, `WhileInactve` have all been fixed when used inside nested navigation. Previously they would only consider the local navigation, not the entire tree. If the old behavior is still desired you can set the `Path="Local"` option on the navigation.
- `Activated`, `Deactivated` have been fixed to only trigger when the navigation is again stable. If you'd instead like to trigger the moment the active page changes, which is closest to the previous undefined behavior, set `When="Immediate"`
- The `NavigationPageProxy` use pattern has changed. `Rooted` is removed, `Unrooted` is now `Dispose`, and the constructor takes the parent argument. This encourages a safer use (avoiding leaks).

### MapView
- Support MapMarker icon anchor X/Y/File properties when setting MapMarkers via JS
- Added `<MapMarker Tapped="{myHandler}"/>` to retain the data context for each tapped marker.
- Added `<MapView AllowScroll="false"/>` to disable the user panning and scrolling around.
- Fixed a bug causing crashes on iPhone 5s devices when using `ShowMyLocation="true"`

### WebView
- Added `<WebView ScrollEnabled="false"/>` to disable the user panning and scrolling around.

### Fuse.Box / Fuse.Ray
- Uno.Geometry.Box and Uno.Geometry.Ray has been replaced with Fuse.Box and Fuse.Ray.

### MemoryPolicy
- Added `QuickUnload` memory policy to keep data in memory for as short as possible.

### ImageTools
- Added supported for encoding/decoding images to/from base64 on DotNet platforms, including Windows and Mac OS X.

### Bugfixes
- Fixes a bug where the app would crash if a databinding resolved to an incompatible type (e.g. binding a number property to a boolean value). (Marshal.TryConvertTo would throw exception instead of fail gracefully).

### Fuse.Controls.Video
- Fixed a bug where HLS streams would become zero-sized on iOS.

### Expression functions
- added `index` and `offsetIndex` as funtions to get the position of an element inside an `Each`
- added functions `mod`, `even`, `odd`, and `alternate` to complement the index functions. These allow visually grouping elements on the screen based on their index.
- added trigonometric math functions `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `radiansToDegrees`, `degreesToRadians`
- added math functions `abs`, `sqrt`, `ceil`, `floor`, `exp`, `exp2`, `fract`,`log`, `log2`, `sign`, `pow`, `round`, `trunc`, `clamp`
- added `lerp` function for linear interpolation between values


# 1.0

## 1.0.4

### GraphicsView
- Fixed issue where apps would not redraw when returning to Foreground

### ScrollView
- Fixed possible nullref in Scroller that could happen in certain cases while scrolling a ScrollView
- Fixed nullref in Scroll that could happen if there are any pending LostCapture callbacks after the Scroller is Unrooted

### Fuse.Elements
- Fixed an issue where the rendering of one element could bleed into the rendering of another element under some very specific circumstances.


## 1.0.3

### ColumnLayout
- Fixed an issue that would result in a broken layout if a `Sizing="Fill"` was used there wasn't enough space for one column.

### Bug in Container
- Fixed bug in Container which caused crash when the container had no subtree nodes. This caused the Fuse.MaterialDesign community package to stop working.

### Fuse.Controls.Video
- Fixed a bug where we would trigger errors on Android if a live-stream was seeked or paused.

### Experimental.TextureLoader
- Fixed an issue when loading images bigger than the maximum texture-size. Instead of failing, the image gets down-scaled so it fits.


## 1.0.2

This release only upgraded Uno.


## 1.0.1

### Fuse.Elements
- Fixed a bug where elements with many children and some of them were rotated, the rotated elements would appear in the wrong location.


## 1.0.0

### iOS
- Fix bug which could cause visual glitches the first time rotating from Portrait to Landscape

### Fuse.Reactive
- The interfaces `IObservable`, `ISubscriber` and `IObserver` are no longer public (affects any class that implements them). These were made accidentally public in Fuse 0.36. These need to be internal in order to allow behind-the scenes optimizations going forward.

### Bugfixes
- Fixes a bug (regression in 0.36) where functions could not be used as data context in event callbacks.
- Fixed a bug where strings like `"20%"` did not marshal correctly to `Size` when databound.
- Fixed a defect in expression functions `x,y,width,height`, they will not use the correct size if referring to an element that already has a layout

### Instance/Each/Deferred
- Changes to the items will not be collected and new items added once per frame. This avoids certain processing bottlenecks. This should not cause any backwards incompatibilties, though the option `Defer="Immediate"` is available to get the previous behavior.
- `Defer="Deferred"` on `Instance`/`Each` allows the deferred creation of nodes without the need for a `Deferred` node
- `Deferred` now has an implied priority based on the node depth. Items with equal `Priority` will now be ordered based on tree depth: deeper nodes come first.

### Page busy
- A `Page` will now be busy for the first frame (or two) after it is prepared. This will block the `Navigator` from starting the transition during those frames, which should improve first frame jerkyness. The `PrepareBusy` property can be set to `None` to disable this behaviour.

### Text edit controls
- Fixed the behaviour of placeholder text in the text renderer used when targeting desktop. The placeholder text is now always visible when there is no text in the text control, even when it has focus.

### GeoLocation
- The GeoLocation module no longer throws an exception if there are no listeners to the `"error"` event when there is an error.
- Fixed an omission that meant that the old way of listening to GeoLocation events (using `GeoLocation.onChanged = ...` instead of the recommended `EventEmitter` `GeoLocation.on("changed", ...)`) did not work.

### Stroke
- The `Stroke` will no longer emit property changed events for its Brush unless it is pinned. This is not anticipated to be an issue for any projects.

### Fuse.Version
- A new static Uno class has been introduced, called `Fuse.Version`. It contains fields for the major, minor and patch-version, as well as a string with the full version number.

### Native
- Add implementation for `android.view.TextureView` to better support multiple `<GraphicsView />`'s and `<NativeViewHost />`'s on Android. 

### Container
- In order to fix a memory leak in `Container` the pre-rooting structure was changed. Children of the container will not be children of the `Subtree` until rooted. It is not believed this will have any noticable effect; other features, like Trigger, also work this way.

### Gestures
- Extended the ability of gestures at multiple levels in the UI tree to cooperate, or take priority
- SwipeGesture now has priority over ScrollView, even if in an ancestor node
- Edge swipes have priority over directional swipes, regardless of the node they are in
- Removed `SwipeType.Continuous` as it did not work correctly and wouldn't fulfill the known use-case even if it did. Consider using `Auto` instead.
- Deprecated public access to the `Scroller` class. This is an internal class and should not be used. All functionality is accessible via `ScrollView`
- Added `SwipeGesture.GesturePriority` and `ScrollView.GesturePriority` to adjust priorities
- Fixed an issue where a higher level capture where preempt one lower in the UI tree

### Visual
- The `then` argument to `BeginRemoveChild` is now an `Action<Node>` to provide the node to the callback. Add an `Node child` argument to the callback function.

### ImageTools
- Changed the algorithm for creating new file names for temporary images. Previously this used a date format that caused problems when several images were created in sub-second intervals, breaking custom map marker icons, for instance.
- Fixed a memory leak that occured when resizing multiple images one after another.

### Vector drawing
A new vector drawing system has been added to Fuse. This allows drawing of curves, shapes, and simple vector images.
- Added `Curve` which allows drawing of lines and polygons. `CurvePoint` can be used to bind to JavaScript observables and servers as the basis for drawing line graphs
- Reintroduced `Path`, `Ellipse`, `Star` and `RegularPolygon`. These are all backed by the new vector system.
- Added several options to `Ellipse` to allow drawing wedges, like with `Circle`
- Added `Arc` for drawing the outside edge of an `Ellipse`
- Added elliptic arc support to `Path` to support more SVG path data
- Removed `FitMode.StrokeMaximum` and `FitMode.ShrinkToStroke` as they could not be reliably supported or behave in a reasonable fashion. To fit accounting for stroke use a wrapping panel with padding instead.
- Removed `Path.ScaleMode` as stroke scaling is not supported as it was before
- Remove the `Fuse.Drawing.Polygons` and `Fuse.Drawing.Paths` packages. Their functionality has been replaced by the new vector system
- `Fuse.Controls.FillRule` has moved to `Fuse.Drawing.FillRule`

### Default Fonts
- Added the following default-fonts, that can be used like so `<Text Font="Bold" FontSize="30">This is some bold text</Text>`:
  * `Thin`
  * `Light`
  * `Regular`
  * `Medium`
  * `Bold`
  * `ThinItalic`
  * `LightItalic`
  * `Italic`
  * `MediumItalic`
  * `BoldItalic`

### Fuse.Audio
- Due to a bug in Mono we have temporarily removed support for PlaySound in preview on OSX.

### MapView
- Fixed a bug causing crashes on iPhone 5s devices when using `ShowMyLocation="true"`

### ImageFill
- Fixed a bug where the `MemoryPolicy` given would not be correctly used.


## 0.47

## MapView
- iOS: Fixed incorrect view recycling for custom MapMarker icons.
- iOS: Fixed ginormous custom MapMarker icons.
- Minor improvements

## Fuse.Json
- `Json.Escape` has been marked as obsolete, as it didn't correctly quote everything needed. Use `Uno.Data.Json.JsonWriter.QuoteString` instead. Note that `JsonWriter.QuoteString` also adds quotes around the result, so it's not a pure drop-in replacement.

## Page
- Fixed a bug where changes to `Page.Title` were not propagated properly to Property-bindings.

## Fuse.Nodes
- `IFrustum.GetProjectionTransform` and `IFrustum.TryGetProjectionTransformInverse` has been changed signature to `bool TryGet...(..., out float4x4)` so attempts to divide by zero etc can be reported to the call-sites.

## Share
- Added `Fuse.Share` package enabling the sharing of text and files with other applications.

## Harfbuzz text renderer
- The Harfbuzz text renderer is now the default text renderer in local preview and desktop builds. The new renderer supports complex text with emoji, bidirectionality, ligatures, etc. It is also faster than the old renderer. It's also possible to use this text renderer on mobile devices by building with `-DUSE_HARFBUZZ` (just like before).
- Fixed an issue where text elements with many lines would be measured incorrectly due to rounding.
- Fixed a bunch of bugs in the desktop text edit control when using the Harfbuzz text renderer. Some examples of bugs that were fixed are:
  * Not being able to move to the first line if the text control started with multiple newlines.
  * The cursor moving before the inserted character when adding text on the first line if that line is empty.
  * The cursor jumping to the wrong position when moving left and right in certain bidirectional strings.
  * The caret ending up in slightly off positions when moving up or down in multi-line text.

## TextInputControl
- The default setting for TextTruncation has changed from `Standard` to `None`. The `Standard`-setting is known not to work as expected on text-inputs, and the whole setting will probably be removed in an upcoming release. None of this applies to non-input controls.

## Timeline
- Fixed inconsistencies with how `Timeline` implemented `Resume`, `Pause`, and `Stop`. They now work in the same fashion as other media playback, such as `Video`. If you happened to depend on the old behaviour you can use the new `TimelineAction`.
- Added `TimelineAction` for extended control over a `Timeline` without mimicing media playback
- Deprecated `PlayTo`, use `TimelineAction` instead
- Deprecated `Resume`, use `Play` instead
- Deprecated several items in `IPlayback` as they are redundant. It is strictly a simple playback interface now.

## WrapPanel
- Fixed several layout issues with `WrapPanel` and `WrapLayout`
 * text should wrap correctly now
 * `Padding` is now applied
- Added `WrapPanel.RowAlignment` to align contents to the top/bottom/center of a row

## Input.Pointer
This is a series of advanced changes that should not affect UX level code.
- The public interface of Input.Pointer has changed to allow for extended gesture support. There is a behaviour change that an `identity` can have only one capture now. Most use-cases involving a single finger/button likely already met this restriction.

If you capture multiple pointers and cannot easily switch to using `ExtendCapture`, you can also use a unique identity instead. Create a `new object` and use that identity as the second capture. This should work as it did before.

- Added `ExtendCapture` to add additional points to an existing capture
- Added `ModifyCapture` as a new high-level interface to the capture mechanism
- Added `Gesture` to coordinate gesture support (experimental)
- `ReleaseAllCaptures` renamed `ReleaseCapture`, since there can be only one
- Removed `Pointer.IsSoftCaptured` and `Pointer.IsHardCaptured` in favour of just `IsCapture`. 
- The higher level `PointerEventArgs` still keeps many of the old entry points for compatbility/simplicity as it is more frequently used.

## PointerCapture
- Added `PointerCapture` as an explicit way to caputre the pointer and do compound controls (experimental)

## ScrollView / SwipeGesture
- Modified capturing on `ScrollView` and `SwipeGesture` to allow them to both exist on the same parent node and be usable at the same time.

## Fuse.Entities:
- This deprecated package has been removed. If you for some reason depended on it, it can now be found [here](https://github.com/fusetools/Fuse.Entities). Please note that this package is not actively maintaned nor supported. Use at your own risk ;)

## Fuse.Navigation:
- `PageResourceBinding` has been marked as deprecated. Instead of `<PageResourceBinding Target="something.Prop" Key="Foo" />` Use `Prop="{Page Foo}"` on `something` instead.
- Fixed an issue where the animation `Scale` property was not applied at rooting time

## ScrollView
- Fixed an incorrect change of `ScrollingAnimation.Range` if `To` or `From` were set. They would force an `Explicit` mode, but now only do that if the `Range` has not been set before. The behaviour of something like `<ScrollingAnimation Range="SnapEnd" To="100">` thus changes (it was undefined before, and is still undefined behaviour, as `SnapEnd` doesn't accept To/From values)

## Cycle
- Added `CycleWaveform.Square`
- Added `CycleWaveform.Offset`

## Duotone effect
- An effect that applies a duotone filter with customizable colors.

## Brush
- Changed `Brush` to use premultiplied alpha rendering which resolves several unpleasant visual anomolies
- Changed `LinearGradient` to interpolate using premultiplied alpha 
- Removed `Brush.BlendMode` as it wasn't working correctly, and cannot actually be supported correctly
- Added `LinearGradient.Interpolation` and set the default to `Linear`. Previously this would, incorrectly, do a smoothed gradient. To get the previous behaviour use `Interplation="Smooth"`, but note it is not supported on all renderers.

## Expressions in file paths
- UX expressions are now also supported in `FileSource` properties, e.g. `<Image File="Assets/{img}.png" />`. Remember to include the files in the `:Bundle` in your `.unoproj`.


# 0.46

## Router
- fixed an issue where relative paths would be incorrectly resolved (against current path instead of intended actual path)

## x and y UX expression functions
- One can now get the x or y position of an element relative to its parent by using the `x(element)` or `y(element)` functions in UX expressions.

## WebView
- Added 'URISchemeHandler' callback, which fires when a URL request matching the app's `UriScheme` is made.


# 0.45

## Timeline
- Fixed a defect where `PlayMode="Wrap"` could start flickering and skipping actions after the second loop

## JavaScriptCore
- Fixed a bug that lead to a crash on exit.

## Fuse.PushNotifications
- The `onReceivedMessage` now provides an optional second argument which indicates whether the notification was triggered from the notification bar. You can use it like this: `Push.onReceivedMessage = function(payload, fromNotificationBar) { .. }`

## ImageTools
- Android: Improved memory use and performance when resizing images. This should improve `Camera.takePicture` performance as well, and prevent some OOM crashes.
- Fixed bugs in reading photo orientation from EXIF when reading RAW and JPEG files on Android

## Camera and CameraRoll
- Rewritten image fetch from camera capture and cameraroll image picking activities for better Android device compatibility.

## PlaySound
- Added a trigger that can play bundled `.wav` sounds from UX. It is used like this `<PlaySound File="test.wav" />`

## Harfbuzz text renderer
- The text renderer enabled by building with `-DUSE_HARFBUZZ` now uses an ICU BreakIterator to find out where to linewrap text, instead of just using spaces. This means that it properly wraps scripts (like Kana) that don't normally use spaces between words, and also means that it can wrap text after hyphens.

## Fuse.Launchers
- Split the various launchers into their own packages so they can be used separately. They are named `Fuse.Launcher.Email`, `Fuse.Launcher.InterApp`, `Fuse.Launcher.Maps` & `Fuse.Launcher.Phone`
- `Fuse.Launcher` will remain and will continue allowing you to add all the above packages at once. This means that your current projects will keep working, and if you want to minimize the number of permissions you are using you can simple add the specific package references to your `unoproj` files.

## MapView
- Fixed issue where responses to requests for location permission were not correctly handled.


# 0.44

## Observable
- Fixed an issue with `.inner` and `.innerTwoWay` forwarding the `Observable` itself
- Fixed a bogus error when `.expand` was passed an empty Observable

## Fuse.Entities
- `Scene.WindowClosing` and `Scene.WindowClosed` has been removed. These were only hooked up for non-mobile targets in the first place, and wasn't really working.

## Native UI
- Android: Improved the way fuse manages the native controls when using `<NativeViewHost />`. This resulted in big performance improvement in complex native UIs.
- iOS: Fixed issue where autoscrolling in `<TextView TextWrapping="Wrap" />` could misbehave if the `TextView` was in a `Panel` that let its size grow (like `StackPanel`)

## Draggable
- Added `Axis` constraint to Draggable, allowing draggable behaviors locked to single axes if needed.

## BusyTask/WhileFailed
- `BusyTaskActivity.All` has been removed, there is now a `Common` which covers the same tasks and a `Any` which covers all possible tasks.
- Changed `WhileFailed` to be part of the BusyTask system. The biggest difference is that it will detect failures of any descendent elements, not just where it was used. This is unlikely to cause a behavioural change in most projects, but if you need the old matching use `Match="Parent"`.
- Removed the `WhileFailed.Message` resource. Add an error handler directly to the resource (such as ImageSource) if the error message is needed.
- Data bindings now mark a node as failed if the observable produces an error, or the value cannot be property converted. `WhileFailed` will detect this failure.
- Added the `Busy` behavior to help marking nodes as busy
- Deprecated `FuseJS/BusyTask`, use the `Busy` behavior instead

## TextInput
- Fixed an issue about certain text changes not propagating correctly

## Observable
- Added `Observable.mapTwoWay`: a two-way version of `map`
- Added `Observable.pickTwoWay`: a two-way version of `pick`
- Added `Observable.innerTwoWay`: a two-way version of `inner`
- Fixed numerous issues with `.inner()`, however, if you relied on one of the abnormal behaviours it might be problematic. To assist in migration you can use `.innerDeprecated()` temporarily, which is the old way of doing `.inner()` (it will be removed eventually). `.setInnerValue` is also no longer available on `.inner()` (but still exists on `.innerDeprecated), using a `.innerTwoWay` and assigning a value is the new approach.
- Deprecated `.inner().twoWayMap()` as it has numerous issues. The replacement is to use `.innerTwoWay()`, possibly combined with `.mapTwoWay()` which has a well defined behaviour.
- Deprecated `.beginSubscriptions` and `.endSubscriptions` interface. These had issues that couldn't be resolved via this interface. As we don't suspect they are actually used we have not provided a replacement. Please ask, and provide a use-case, if they are important for your code.
- Added `failedMap` and `isFailed` to help track failure conditions
- Failed Observables now lose any previous value. This was inconsistent before, sometimes they retained a value.
- Failed Observables will clear the binding correctly now (for `{Clear name}` bindings)
- Fixed a defect where `onValueChanged` would not respond to all changes
- Fixed clearing of bindings when assigning an undefined value
- Fixed forwarding of failed state in `combine`, `combineLatest`, and `combineArrays`
- Fixed clearing of state if input undefined in `combineLatest`

## StateGroup
- `State.On` has been removed. This value should not have been public as it did not reflect a usable value, and could corrupt the current state. Use `.Goto` to goto the current state and `StateGroup.Active` to get, or set, the state.

## WebView
- Added `ZoomEnabled` attribute, defaulting to "true". In the past, zoom gestures were enabled by default on iOS but disabled on Android due to an oversight. This unifies the end-user experience.
- Made Android WebView respect viewport tag and load content in overview mode to comply better with the iOS behavior.

## CameraRoll
- We now catch exceptions that occur during processing of a selected picture in the iOS CameraRoll. In the past this could result in orphaned promises.

## Completed
- Added `Completed` trigger that pulses when a node is no longer busy


# 0.43
## Navigator
- Allowed `SwipeBack` to change the direction per page, previsouly it only allowed disabling it
- Added `NavigatorSwipe` to simplify adding swipe gestures to a `Navigator`
- Clarified that `NavigationGotoMode.Prepare` means preparing an interactive transition, like sliding
- Added `Transition.Mode` to allow matching `Prepare` mode differently than non-prepare
- Added an `operationStyle` argument to `IRouterOutlet.Goto` to allow for different styles of transition
- Added a `Style` option to `RouterModify` and the JS `.modify` interface to allow further differentiating transition styles
- Added `WhilePageActive` to trigger changes based on the currently active page
- Fixed several issues with page caching in `Navigator`

## ImageFill
- Partially fixed a memory leak when changing the `Source` of the image. The leak is gone, but it still uses more memory than it should. A fix for that will be coming.

## Text rendering
- Fixed an issue in the text renderer enabled by compiling with `-DUSE_HARFBUZZ` where center- and right-aligned text would not properly update their alignment when the text element changed size.

## WhileCount
- Fixed how multiple conditions were combined on `WhileCount`. Previosuly two conditions would be combined with "OR", now the various range combinations are combined with "AND". Refer to the docs on how to do an inverted, or "OR", range, and how to make a `GreaterThanEqual` or `LessThanEqual` comparison (this has changed in a backwards incompatible fashion)
- Fixed some potential leaks and update paths on `WhileCount`

## NodeGroup
- Added `NodeGroup` which allows combining several nodes and resources together in a block

## JavaScript
- Updated the version of the V8 engine that we bundle to 5.5.
- Fixed some inconsistencies in how V8 handled marshalling Uno exceptions and String objects in JavaScript.
- Added support for the WebSocket API.
- XMLHttpRequest: Removed exception when calling abort on a finished response

## Triggers
- Changed the ordering behaviour of how trigger actions/events are resolved. This resolves some issues with previously undefined behaviour. It should not affect applications unless they were inadvertently relying on such undefined behaviour. This generally relates to triggers with actions that modified their own state, or have a cycle with other triggers, or contain nodes but no animators.

## Navigation
- Added `Page.Freeze` that can be set to `WhileNavigating` to freeze the page (block updates) during navigation
- Added `Navigator.DeferPageSwitch` to defer page navigation until the page is ready
- Removed the static "State" events from `Navigation`, replacing them with `INavigation.StateChanged`. This should not affect any UX code, unless you used a `WhileNavigating` in an incorrect place, in which case you may get an error now.
- Fixed `Transition` to work with swiping
- Renamed `NavigationControlBits` to `NavigationInternal` -- these are not meant to be used and are only public for technical reasons
- Fixed an issue of an incomplete back swipe causing oddness on the Navigator
- Fix issue where Unrooting and then Rooting of a LinearNavigation could make the `Active` property hold an invalid object reference

## Swipe
- `WhileSwipeActive` changed to be only active when the gesture is at progress="1". Previosuly this could activate immediately when the `IsActive` flag was switched, which led to inconsistent states. To get a behaviour close to the previous one set the new `Threshold` parameter to `0.01` (however, this is rarely desired).
- Fixed a defect where a second swipe gesture might not have been recognized
- Added `WhileSwiping` to detect an active swiping gesture
- Added `How="Cancelled"` to `Swiped` to detect when the user does not complete a gesture

## Panel
- Added a `IsFrozen` feature that allows temporarily blocking any new layout as well as new drawing. It's meant to be used in conjunction with navigation for smooth transitions.
- Several drawing and layout functions are now sealed. This prevents any derived class from implementing new layout, or drawing, which was never properly supported, and will fail now. You can instead derive from `LayoutControl` and override `DrawVisual` if necessary.

## Observable
- Fixed issue with duplicated items in `Each` using `addAll`
- Fixed issue of `refreshAll` not removing excess items
- Fixed issue of `replaceAt` not doing bounds checking

## TextEdit
- Use AppCompat's getDrawable on android. This stops a bunch of warnings about deprecated android APIs.


# 0.42

## Data bindings no longer clear their value by default when removed
- Data bindings used to clear (write `null` or `0`) to their target properties when removed from the tree, so that old data would no longer linger if a node was reused later (manifesting as flashing of outdated data). However, this behavior lead to undesired consequences that were hard to work around in other cases. Now data bindings no longer clear by default. 
  * This is unlikely to affect your app, but if you depended on the old behavior, you can restore the same behavior by using the new clear-bindings where needed: Change `{foo}` to `{Clear foo}`, and `{Read foo}` to `{ReadClear foo}`.

## Observable bugfixes
- Fixed bug where `.twoWayMap()` would not work correctly on boolean values.

## Busyness and Transitions
- Removed the public contructor and `Done` function of `BusyTask`. Only the static `SetBusy` function, and the JavaScript interface, should be used now.
- Added `BusyTaskActivity` to note the types of busyness and added `WhileBusy.Activity` to match only certain busy activities
- `WhileLoading` now uses the `BuyTask` system. The biggest difference is that it will detect loading of any descendent elements, not just where it was used. This is unlikely to cause a behavioural change in most projects, but if you need to old matching use `Match="Parent"`.

## Fixed data context bug with triggers and AlternateRoot
- Fixed bug where nodes injected by triggers or `AlternateRoot` would sometimes not get the correct data context. This may break your app if you have a bug dependency. The rule is that nodes should always get the data context according to where they are declared in the UX tree, as you read it in the code (not based on where the node is ultimately injected, e.g. by AlternateRoot).

## Introducing Reactive UX Expressions
- All properties in UX markup now support reactive expressions, e.g. `Width="spring({Property Size})"` and `Text="Hello, {username}!"`. For more details, see the documentation.

## New text renderer
- Improved the wrapping and truncation implementation with the text renderer that's activated by building with `-DUSE_HARFBUZZ`.
- Added default font fallbacks on desktop when using the `-DUSE_HARFBUZZ` flag. This means that we can use emoji, many Asian languages, and Arabic in preview.
- Fixed an issue that resulted in apps built using `-DUSE_HARFBUZZ` being rejected from the App Store due to referencing private symbols. This means that this flag can now be used in iOS releases.
- Fixed a bug where TextInputActions did not trigger on desktop text inputs using `-DUSE_HARFBUZZ`.

## Router and Navigation
- `NavigationGotoMode` became a normal enum, not `[Flags]` and loses the `ClearForwardHistory` flag. Uses of that flag can be replaced with a call to ClearForwardHistory on the target navigation.
- Added the `RouterModify` action as a UX parallel to the JS `.modify` function
- Added `ModifyRouteHow.PrepareBack`, `PreparePush` and `PrepareGoto` as ways to prepare for navigation combined with a swipe
- Added the `bookmark` function to the router JavaScript interface
- Added `SwipeGesture.IsEnabled` to allow disabling user interface
- Added `Navigator.SwipeBack` that accepts a direction to enable backwards swipe navigation

## Trigger
- `TriggerAction.Direction` has been replaced with `TriggerAction.When`. This includes the new `Stop` and `Start` option. The value `Both` has been replaced with `ForwardAndBackward` for clarity. Old UX code will continue to work.

## Navigator
- Fixed the removal of pages with `Reuse="None"` in Navigator

## TextInput
- iOS: Implement support for `LineSpacing` on `<Text />` when used inside `<NativeViewHost />`
- iOS: Implement support for `LineSpacing` on `<TextView />`

## Grid
- Numerous issues with Grid layout have been fixed. Unfortunately this changes how some existing grids might be arranged.
  * Proportional rows/columns now have no size when the grid is being shrunk to fit its contents. Previously they would have a minimum size related to their content; this value was actually incorrect, and caused other problems. This change fixes several layout issues with `Grid`.
  * A new metric called `Default` has been introduced as the default for `DefaultRow` and `DefaultColumn`. This maintains a behaviour similar, but not exactly the same as the old default. It is only usable for grids that fill a known space (or parent area), or have only 1 row or column. All other grids must set all Row/Column metrics correctly, or use `DefaultRow` and `DefaultColumn`.
  * The behavior of Grid's with cells containing `RowSpan` or `ColumnSpan` that extended beyond the intended bounds of the grid will now, more correctly, extend the grid instead of being clipped. Fixing the overflowing spans will restores the previous layout.
- Added `Grid.ChildOrder` that allows changing whether children are ordered as rows or columns.
- Removed the `Column.ActualWidth` and `Row.ActualHeight` properties. These were never meant to be publically readable as the value is not useful, nor guaranteed to be set.
- Removed the public `DefinitionBase.Implicit` property. This has an ambiguous meaning and wasn't intended to be exposed publically (no valid use-cases)
- The previously deprecated properties `RowData` and `ColumnData` have been fully removed. Use `Rows` and `Columns` instead.

## FileSystem
- Use `<app exe directory>/fs_data` for `dataDirectory` and `<app exe directory>/fs_cache` for `cacheDirectory` on OS X and Windows, to avoid directory conflict


# 0.41

## Navigator
- Fixed issues where certain route transitions would result in multiple active pages. This was a cache error that came up when using embedded `Navigator` objects and switching to/from the embedded pages.

## Deprecated packages
- Quite a few packages and classes have been marked as obsolete. This means that they are still available, but will produce warnings on use. In a future release, these may get removed fully.
- The packages `Fuse.Drawing.Batching`, `Fuse.Drawing.Meshes` and `Fuse.Entities`, as well as the classes `Cube`, `WireCube`, `SolidCube`, `Cylinder` and `Sphere` from `Fuse.Drawing.Primitives` and `Trackball` from `Fuse.Gestures` have been marked as obsolete. This is undocumented code that implement very basic 3D rendering, but haven't been in use for a long time, and is largely unmaintained at this point.
- `Fuse.Drawing.Polygons`, `Fuse.Drawing.Paths` as well as `Ellipse`, `Path`, `Star` and `RegularPolygon` from `Fuse.Controls.Primitives` has been marked as obsolete. This is either undocumented code that implement very basic path-rendering, but is known to be broken in many simple cases, and is largely unmaintained at this point.
- To avoid that new code accidentally starts using the  above code in the case where the user doesn't notice or ignores the warnings, `Fuse.Drawing.Paths`, `Fuse.Drawing.Polygons` and `Fuse.Entities` no longer gets forwarded through the `Fuse`-package. If you're using one of these, you can add these packages manually to your project while transitioning.

## Each
- Added `Each.Offset` and `Each.Limit` that allow limiting the number of items being displayed.

## TextInput
- Fixed issue where databinding to the same `Observable` on two different `<TextInput/>`s could end up in an infinite `ValueChanged` loop
- Fixed issue where tapping a `<TextInput />` in an area outside the bounds of the text would not focus the `<TextInput />`

## New text renderer
- Added a new text renderer, which can be used on for `Text` on both desktop and on device, and for `TextInput`/`TextView` on desktop. The renderer is currently disabled by default and can be enabled by building with `-DUSE_HARFBUZZ`. The new renderer brings the following features:
  * Support for complex text. The new text renderer can handle bidirectional text, ligatures, and colored glyphs.
  * Speed. The new text renderer is normally about 50% faster than the OS-specific text rendering we previously used on mobile devices, and can be up to 10x faster on particular devices.
  * Asynchronous loading. `Text` elements now have an experimental `LoadAsync` property which enables loading of the text element on a background thread when set to `true`.

## JavaScript implementations
- Optimised passing Uno `byte[]`s to and from JavaScript when running on iOS 10 using newly available functionality in the JavaScriptCore framework. The speed of this operation now more closely matches our other JavaScript engines on iOS 10.
- Fixed bug in btoa, atob implementation.
- Fixed issue "Uncaught ReferenceError: setTimeout is not defined" that appeared in some cases.
- Fixed memory leak in V8 when using HTTP.

# FuseJS/Base64 module
- Exposed functions `encodeLatin1` and `decodeLatin1`.
- Added `decodeBuffer` and `encodeBuffer` functions to decode between ArrayBuffer and Base64

## FuseJS event system overhaul
- The FuseJS modules that use events (GeoLocation, InterApp, LocalNotifications, Push, and Lifecycle) have gotten a new event subscription system. These modules are now instances of a class called `EventEmitter`, which is based on the API of Node's `EventEmitter` class. Though the old way remains working, the recommended way to subscribe to events has changed from `Module.onSomeEvent = myHandler` to `Module.on('someEvent', myHandler)`. With the new event system there's no longer a risk of overwriting the handler that someone else set, and there are additionally several convenience methods like `once`, `observe`, and `promiseOf`. Check out the docs!

## NativeModule
- Removed SetModuleFunction from the NativeModule interface. Use Module.CreateExportsObject instead.


# 0.40

## Fixed bug where outdated event handlers would be called
- Fixed a bug where some event types (e.g. `<Activated>`) would fire the old version of an event handler when a page is navigated to multiple times.  This fixes several weird issues reported by multiple users, e.g. https://www.fusetools.com/community/forums/bug_reports/serious_observable_bug_in_025.

## Bindings
- `{Property }` bindings now supports automatic conversion (bindings) between weakly compatible types, such as `float` and `Size`.
- Added `{SnapshotProperty ...}` which is a read-once property binding that reads the value at rooting time but does not listen for changes in the property.
- Moved `PropertyBinding` and from `Fuse.Controls` to `Fuse.Reactive` (might break Uno code and cached code, remember `uno clean`)
- Fixed a crash when doing two-way data-bindings to enum values.

## Visual
- `Visual.ParentToLocal` has been replaced with `TryParentToLocal`. It's possible that this function can fail, even under common use, thus it's important callers detect that condition.
- `Visual.FirstChild<T>` now searches for the *first* child, not the last child as it previously did. If you depended on the old behavior, you can manually traverse the `Visual.Children` list backwards, and search for the child.

## Transition
- Introduced `<Transition>` allowing for fine-tuning transitions between pages in `Navigator`

## ExplicitTransformOrigin
- Introduced `Element.ExplicitTransformOrigin` that allows setting a location for the `TransformOrigin`

## Fonts
- Added `SystemFont` which is a subclass of `Font` that gets fonts from the target device so they don't have to be bundled with the app.
- iOS: Fixed an issue where iOS 10 apps would crash during font loading.

## Navigator and PageView
- Added the ability to use non-template pages to `Navigator`
- Added `PageView`, which is a `Navigator` without any standard transitions or page effects
- Added a JavaScript interface to the `NavigationControl` (base type of `Navigator` and `PageControl`). This adds the `gotoPath` and `seekToPath` functions.

## Grid
- Fixed a crash when data-binding to the Rows/Columns property of a grid.

## Shapes
- Android: Fixed issue where `<Cricle />` inside `<NativeViewHost />` could end up not displaying.

## Brush
- Fixed a null value exception when binding a value to `SolidBrush.Color`

## Video
- iOS: Fixed bug in Video where calculating rotation could yeild wrong rotation due to rounding error.

## ScrollView
- Added `RelativeScrollPosition` to `ScrollPositionChangedArgs`
- Added serialization of `value` (the scroll position) and `relativePosition` to JavaScript for `ScrollPositionChangedArgs`

## DropShadow
- Unsealed `DropShadow`, making it possible to create `ux:Class`es of `DropShadow`

## NativeViewHost
- iOS: Fixed issue where having a `<NativeViewHost />` inside a `<PageControl />` would not handle input events properly
- Implemented forwarding of `HitTestMode` to the native view for elements inside a `<NativeViewHost />`

## ImageFill
- Added `<ImageFill WrapMode="ClampToEdge" />` to restore old, clamped rendering of the texture. This is useful if you're just using an `ImageFill` to mask an image with a circle or something along those lines.
- Added support for `WhileBusy` and `WhileLoading` while using an `ImageFill` brush inside a `Shape`

## Tapped
- Changed `Tapped` to be an attached event, which means handlers can be created by doing `<Panel Tapped="{onTapped}" />` instead of `<Panel><Tapped><Callback Handler="{onTapped}"/></Tapped></Panel>`.

## Fuse.PushNotifications
- Android: Fixed a crash when receiving two notifications at the same time.


# 0.39

## ios 10
- Fix problem with using Promises resulting in Error: "Invalid private name '@undefined'"

## TextInput
- Fix Android/iOS issue where `<TextInput />` could be seen for 1 frame onscreen when it were supposed to be hidden or behind other visual elements.

## New `Instance` behavior
- Introduced `<Instance>`, which instantiates `ux:Templtes`. Equivalent to `<Each Count="1">`, but reads better in UX and doesn't expose `Count` or `Items`.
- Uno level: Extracted base class `Instantiator` from `Each`, which `Instance` also inherits.

## Android Notification Icon

Users of Local & Push notifications on Android can now specify the icon to be used for the notification. 
  This is done in the same fashion as the regular android icons. In your project's unoproj specify:

```
    {
        "Android": {
            "NotificationIcon": {
                "LDPI": "Icon-ldpi.png",
                "MDPI": "Icon-mdpi.png",
                "HDPI": "Icon-hdpi.png",
                "XHDPI": "Icon-xhdpi.png",
                "XXHDPI": "Icon-xxhdpi.png",
                "XXXHDPI": "Icon-xxxhdpi.png"
            }
        }
    }
```

The icon must adhere to the android style guides. In short it must be white on a transparent background, any solid color will be converted to white by the android build process. Fuse has no control over this and cannot stop it happening.

The behavior around default notification icon has also changed. Before we simply used the app icon. This meant that when the icon had color, the color was removed by android often resulting in an white square. With this change we will either:

- Use the `Android.NotificationIcon` as specified above. Or if that is not specified we...
- Use the `Android.Icons` setting from your unoproj. Or if that is not specified we...
- Use the default notification icon, which is a small white Fuse logo.

## Observable improvements
- Added `.subscribe(module)` which can be used to create a dummy subscription on observables for the lifetime of the given module. This is an alternative to adding the observable to `module.exports` or using `.onValueChanged` in cases where you want to access the observable's value in a callback.

## Layout info in JS
- The `Placed` event now provides metadata to its argument to let you know more about the layout of an element in JS: `.x`, `.y`, `.width` and `.height`. Usage:

	<JavaScript>
		function panel_placed(args) {
			args // contains information about the new size and position 
		}
	</JavaScript>
	...
	<Panel Placed="{panel_placed}"/>

## Pointer events in JS
- Added localX and localY to pointer events in the JS API. This is the coordinate in the local coordinate space of the element that the event occurred on.

## Video
- Added support for rotation thats defined in the metadata of the video source. Only supported on iOS, Android and OSX. Due to a limitation in the Windows implementation this wont be supported on Windows for a while.
- Fixed a crash on Android 4.3 and below while trying to read the video-orientation.

## Easing improvements
- Added `CubicBezierEasing` which allows you create custom easing curves with two control points. See docs for more info.
- Refactored `Easing` from an enum into a base class, to allow custom easing curves. (UX interface unchanged, Uno code should also be mostly unaffected).

## Router
- Added `router.modify` to the JavaScript interface. This function can be used to provide more routing options, such as "Replace" mode and "Bypass" transitions.
- Added `gotoRelative` and `pushRelative` functions. These allow relative changes in route without needing to specify the full absolute path.

## Shadow
- Fixed `<Shadow />` so it still draws the shadow-rectangle when the element's color contains zero-alpha.
- Fixed the Softness-parameter so it looks consistent across different display densities.
- `<Shadow />` elements now understand that they should draw a round shadow rather than a rectangular one if it's parent is a `<Circle />`

## Support for resources in triggers
- Triggers can now have resource nodes (marked with `ux:Key`) inside, and they will be added to the parent node when the node is active. This allows e.g. per-platform or conditional styling.

Example:

	<iOS>
		<Font File="foo-ios.ttf" ux:Key="DefaultFont" />
	</iOS>
	<Android>
		<Font File="foo-android.ttf" ux:Key="DefaultFont" />
	</Android>
	<Text Font="{Resource DefaultFont}" />

## Navigator
- A proper navigation interface is now implemented on `Navigator`. This allows `Page` bindings to work for the active navigator page, such as `{Page Title}`.

## Container
- Added `Container` panel which allows you to build custom containers where children are placed under a custom node deeper in the tree.

## Image
- Added native support for `Color` on `<Image />`es that are inside `<NativeViewHost />`
- Fix issue where `<Image />` inside `<NativeViewHost />` would be laid out wrong

## Native views
- Fixed issue where ZOrdering inside `<NativeViewHost />` did not behave properly

## Bindings
- Added one-way (read-only or write-only) binding types: `{ReadProperty prop}`, `{WriteProperty prop}`, `{Read data}` and `{Write data}` 

## TextInput
- Removed `ActionStyle` from `<TextView />`. This is a `<TextInput />` specific property and it did not have any effect on `<TextVIew />`
- Fixed iOS issue where AutoCorrect suggestions would not trigger value changed events if a `<TextInput />` lost focus when the return key is pressed.
- Fixed issue where assigning a string with newlines to a `<TextView TextWrapping="Wrap" />` would fail to wrap the text.
- Fixed iOS issue where `ValueChanged` events did not fire if text where autocorrected when a `<TextView />` lost focus.

## ImageFill
- `<ImageFills />` now repeat the texture if a `StretchMode` like `PixelPrecise` or `PointPrecise` is used.

## Animation
- Fixed issue where animating `TextColor` did not presever the right init value


# 0.38

## Async texture loading
- Fixed issue where textures could become corrupt if uploaded async on Nvidia Tegra K1 class gpus. 

## Navigator
- To avoid problems with default routes and unintentional parameter differences, several default and empty-like parameters are now considered the same in `Navigator`. These are Uno null and empty string as well as JS null, empty object, and empty string. If these change only a "minor" page change is activated, which will cause an "onParameterChanged" handler to be called, but does not invoke animation by default.

## GraphicsView
- Fixed issue where using a `<GraphicsView />` inside `<GraphicsView />` and using it on desktop would crash the app

## Fuse.Scripting.Json
- Fixed issue where newline characters would not be escaped correctly when using `Json.Stringify` from Uno.

## WhileVisibleInScrollView
- Added the `WhileVisibleInScrollView` trigger that is active when an element is positioned in, or near to, the visible area of a ScrollView.

## Video
- Fixed null ref that could trigger if databinding `Progress` on `<Video />` to JavaScript

## Rooting
- Fixed an ordering issue with triggers and adding children. This was a hard to get defect that resulted in some trigger actions, such as in Navigator, not being activated correctly when the child is first added.

## Route validation
- Router will now give error if functions or observables are passed as route parameters (instead of silently failing). Route parameters must be serializeable as they are stored between refreshes in preview.

## Triggers
- Unsealed lots of `Trigger` classes making it possible to create useful `ux:Class`es of them.

## JavaScript cleanup
- Cleaner debugging: Reduced the amount of duplicate utility scripts compiled by the JS context, showing up in some JS debuggers (e.g. Safari).

## FileSystem
- Make `Fuse.FileSystem.Nothing`, `Fuse.FileSystem.FileSystemOperations`, `Fuse.FileSystem.BclFileInfo` and `Fuse.FileSystem.BclFileAttributes` internal, as they were marked as public by mistake.

## TextInput
- Fixed bug where an unfocused `<TextInput />` would not render RTL text correctly

## TextInput - BREAKING CHANGE
- Removed `PlaceholderText` and `PlaceholderColor` from `<TextView />`. These properties did not belong on `<TextView />` in the first place and was never properly implemented across platforms. Semantically `<TextView />` is just a viewer and editor for large amounts of text. If you need a placeholder it should be implemnted in UX
- Check out this example for how to implement a placeholder text for  `<TextView />`
```
	<TextView>
		<WhileString Test="IsEmpty">
			<Text TextWrapping="Wrap">My Placeholder</Text>
		</WhileString>
	</TextView>
```

## ImageTools
- Fix getImageFromBase64 on Android

## Effects
- Effects are now `Node`s, and can as a result be contained inside triggers.
- `Element.Effects` is no longer accessible. The new way of adding effects, is to add them to `Element.Children`, like other `Node`s.
- `Element.HasEffects`, `Element.HasActiveEffects` and `HasCompositionEffect` are no longer accessible. These were only meant as helpers for the implementation of `Element`, and shouldn't be needed elsewhere.

## Fuse.Controls.Video
- Implemented support for `Volume` in `<Video />` on OSX preview

## TextInput
- Fixed bug where the SoftKeyboard would not appear on screen when `<TextInput />` gets focused while in Landscape


# 0.37

## PushNotification
- Fixed marshalling of GCM push notifications, caused by change in protocol

## GeoLocation
- Fixed issue where location fetch requests on Android would run on the wrong thread

## Observable improvements
- Added `.addAll()`, `.insertAll()` and `.removeRange()` for faster list manipulation
- Fixed bugs in `.where()` and `.count()` dealing incorrectly with some operations
- `.where()` and `.count()` now supports objects as filters, e.g. `list.where({id: 4})`
- Added `.any( [criteria] )` which returns an observable boolean of whether the observable contains an object that meets the criteria.
- Added `.first( [criteria] )` and `.last( [criteria] )` which returns an observable of the first/last item that meets the criteria, or simply the first/last element if the criteria is omited.
- Added `.identity()`, `.pick()` and `.flatMap()`

## New `Observable.inner()` superpowers to ease two-way bindings on `ux:Property`
- On observables returned by `.inner()`: support for `.twoWayMap()` to ease construction of components with two-way bindable properties. For example usage, see https://github.com/Duckers/FusePlayground/tree/master/Components/DateEditor 
- On observables returned by `.inner()`: support for `.setInnerValue()` which sets the value of the inner observable without sending a message back to the observable returned by `.inner()`. When creating a component with a two-way bindable property, this should be used to notify users of the component that a property has been changed from within the component, typically driven by user interaction.
- Fixed initial value race condition in implicit observables for `ux:Property` causing unpredictable behavior
- BREAKING CHANGE: An `ux:Property` of a class type (e.g. `object` or `Brush`) with value `null` in Uno will now produce an empty observable `Observable()` instead of `Observable(null)` in JavaScript. This prevents a lot of annoying scenarios where e.g. `map()` will unexpectedly map `null` instead of a real value (often leading to crash). When the Uno side is `null`, `obs.value` will now be `undefined` (as the observable is empty, `length=0`). This might have backwards incompatible side effects if you relied on `null` being set.

## New ScrollView features
- Added `Scrolled` and `WhileScrolled` triggers which respond to scrolling within a region of the ScrollView. These provide more flexibility e.g. for dynamically loading more data in an infinite feed (compared to `WhileScrollable`).
- Visible elements are now kept in view when the layout of the ScrollView changes, e.g. when adding new items to a feed. Use `LayoutMode="PreserveScrollPosition"` to get the old behavior.
- Added `LayoutRole="Placeholder"` to create items that are part of a ScrollView or Navigation's layout but not a logical item (like page, or scroll anchor)

## LayoutParams
- `DeriveClone` renamed `CloneAndDerive` and `TrueClone` renamed `Clone` to help avoid confusion about what they do.

## LinearRangeBehavior
- Added `LinearRangeBehavior.Orientation` to allow vertical range controls

## WhileNavigating
- `WhileNavigating` changed to a `WhileTrigger` to add `Invert` functionality
- Fixed issue so `WhileNavigating` now finds ancestor navigation

## Fuse.Maps
- Adds `IconFile` attribute to `MapMarker`, letting you specify a file asset to replace the marker icon graphic.
- Adds `IconAnchorX` and `IconAnchorY` attributes to `MapMarker`, being normalized coordinates from 0,0 to 1,1 determining the point on the icon graphic where it rests on the map. This defaults to 0.5, 0.5, being centered.
- Fix issue that caused a crash on iOS when used together with FuseJS/GeoLocation package

## GeoLocation
- Improved the iOS implementation of GeoLocation. The most significant changes are that `getLocation` now respects its timeout parameter, and that multiple concurrent calls to `getLocation` are handled gracefully.

## Selection
- Added the Selection API, comprising `Selection`, `WhileSelected`, `ToggleSelection`, `Selectable`, `Selected`, and `Deselected`

## Each/Match/Deferred
- Fixed some issues to ensure the resulting children order matches the logical UX order of `Each` `Match` and `Deferred`. This affects code where these triggers are used directly inside each other without an intervening `Panel` (adding that `Panel` was the previous workaround).
- Fixed an issue where the content in an `Deferred` was not removed while unrootign the `Deferred`

## Select/With
- The previous reactive `Select` trigger has been renamed `With` to better reflect what it does and not cause confusion with the selection API.

## WhileString
- Added `WhileString`, a `WhileTrigger` that tests conditions on a string value.

## V8
- Optimise string handling by avoiding needless conversions back and forth to UTF-8.

## Native views
- Implement `<Image Url="..." />` support for images inside `<NativeViewHost />`

## Fuse.Reactive
- Fixed a crash due to unhandled types passed to the JavaScript VM.
- Fixed a crash while trying to re-bind data-bindings on unrooted nodes.
- Fixed a bug where databinding to outer data contexts often failed due to a race-condition.

## FileSystem
- Fix problem getting `dataDirectory` and `cacheDirectory` while running with `fuse preview`

## Fuse.Physics
- Moved declaration of attached property `Friction` from `Fuse.Physics.Body` to `Fuse.Physics.BodyAttr`. No UX changes are required.

## Fuse.Elements
- Moved declaration of attached properties `LayoutMaster` and `ResetLayoutMaster` from `Fuse.Elements.LayoutMasterBoxSizing` to `Fuse.Elements.LayoutMasterAttr`. No UX changes are required.
- `Element.OnDraw` has slightly changed meaning. It used do draw both the element itself *and* it's children (which was implemented in the base-class). Now it just draws the element itself. Instead, we have a new method called `Element.DrawWithChildren` that will call `Element.OnDraw` and then draw the children. This was done to accomedate `Layer.Underlay`, which required the base-class to draw some things both before and after the element itself was drawn. If you want to avoid drawing the children under some circumstances, override this method instead of `Element.OnDraw`.

## Shadow
- Added a `Shadow`-tag that is a generally faster alternative to `DropShadow`. It works by approximating the background of a rectangle by applying a gradient on the distance field of a rectangle instead. This only works well for rectangles and panels, but has a `Mode`-property that can be set to `PerPixel` (instead of it's default, `Background`) to get the same effect as with `DropShadow`.

## Android.StatusBarConfig
- Fixed a bug, where setting IsVisible on Android.StatusBarConfig accidentally also had effect on iOS.
- Fixed Android issue where the `StatusBar` visibility would be reset whenever the softkeyboard is onscreen. The visibility is restored when the keyboard is dismissed

## Input Handling
- Fixed a crash due to a null-pointer reference while handling input-events

## AlternativeRoot
- The content of AlternativeRoot can now be any class that inherits from Node, not just a Visual.


# 0.36

Due to technical reasons, this release did not make it out into the wild.


# 0.35

## Observables
- Fix issue where the `this.Parameter` observable in a JS module would not behave properly when a `<Navigator />` reuses pages

## Example project
- Fix issue where page 2 would not react on touch input

## Image loading
- An issue in some older Android versions, where the OpenGL context would be leaked under som circumstances has been worked around. This problem manifested itself as images seemingly randomly being swapped.

## Image
- Fix crash when setting `Image.Source` to null when inside `NativeViewHost`

## Native integration
- Fix issue where onscreen keyboard could randomly appear when using `WebView` in `NativeViewHost`

## Stability fix
- BREAKING CHANGE: databindings no longer resolve to data(e.g. `<JavaScript />`) local to the node, only to parent inherited data. This solves common problem scenarios where you would get cyclic databindings leading to memleaks and crash. This means the following will not work anymore:
```
<Panel Width="{foo}">
	<JavaScript>
		module.exports.foo = 10;
	</JavaScript>
</Panel>
```
If you depend on this behavior it can be written as:
```
<Panel ux:Name="p">
	 <JavaScript>
                 module.exports.foo = 10;
         </JavaScript>
	 <Panel>
	 	<DataBinding Target="p.Width" Key="foo" />
	 </Panel>
</Panel>
```
## WebView
- Fixed issue where databinding on HTML.Source didn't compile

## V8
- Cleaned up how exceptions that cross the Uno-JavaScript boundary work. The exception on the JS now contains information about the Uno exception, and if the exception is not caught in JavaScript and rethrown in Uno, the exception contains both Uno and JavaScript stack traces.

## FileSystem
- Add new JS FileSystem module, that will eventually replace the Storage module.
- Fix problem getting `dataDirectory` and `cacheDirectory` while running with `fuse preview`

## Navigation
- Added trigger `Activated`, fires when a navigation page becomes active
- Added trigger `Deactivated`, fires when an active page becomes inactive
- Added event `INavigation.ActivePageChanged`


# 0.34

## Navigation Animations
- The navigation animations `ExitingAnimation`, `EnteringAnimation`, `ActivatingAnimation`, and `DeactivatingAnimation` now delay their animation start 1-frame. This avoids first frame setup costs from interfering with the animation. This does not apply to seeking page progress, like swiping, or standard navigation in a PageControl.

## FuseJS `require`
- Add support for the `require('./directory')` pattern when `directory/index.js` exists to support more node packages.

## Native views
- Fix issue where Circles with Strokes would not display correctly on iOS
- Fix issue where inputevent sometimes would not come through when tapping on native iOS and Android buttons

## Deferred
- Added `Deferred` to stagger node creation

## FuseJS.Environment
- Added `mobileOSVersion` property to inspect Android and iOS OS version at runtime

## TextInput
- Add support for `IsEnabled` for elements inside `<NativeViewHost />`


# 0.33.1

## TextInput
- Fix issue where the `ValueChanged` on `<TextInput />` would fire when the textinput lose focus on iOS

## Image async and WhileBusy

- during loading images will now mark their nodes (and ancestors) as busy
- use the `WhileBusy` to do something while loading
- file image sources can also be loaded asynchronously now (previosuly it was only synchronous). Using `MemoryPolicy="UnloadUnused"` will use the asynchronous loading. The default setting of `MemoryPolicy="PreloadRetain"` will still use synchronous loading, though it isn't really "preloading" anymore.

## Navigation

- `SwipeNavigate` now uses the parent of the gesture itself, not the navigation parent, to determine the swipe size. In most cases this shouldn't affect anything. If it does then place your `SwipeNavigate` inside the panel with the correct size, or set the `LengthNode` to the desired element.

## Shapes
- Add support for native LinearGradient in NativeViewHost on Android and iOS
- Add support for native Ellipse shape inside NativeViewHost on Android and iOS

## Native views
- Fix issue where Android views would not rotate around the correct point
- Fix issue where some native views would not forward input events to fuse on iOS
- Fix issue where transforms on iOS could end up being incorrect
- Fix issue where Circles with Strokes would not display correctly on Android
- Add support for `Opacity` for elements inside `<NativeViewHost />`
- Add support for `ClipToBounds` for elements inside `<NativeViewHost />`
- Fix issue where `<TextInput />` sometimes would not render correctly on older versions of iOS
- Fix issue where Circles with Strokes would not display correctly on iOS

## StatusBar
- Fix issue where setting a color on `<Android.StatusBarConfig Color="#..." />` would not work

## Fuse.Reactive:
- Fix an issue where the maximum call stack size was exceeded during the message-pump for Observables

## Image
- ResampleMode=Mipmap has been deprecated. This have effectively been the same as ResampleMode=Linear for a long time, and apps should use the latter instead. We now generate a warning if you use the former.

## Misc
- Fuse.CacheFramebuffer is not longer exposed as a part of the public API. It was never meant as a visible part of the product. If you're using this, you'll have to implement similar functionality on your own.


# 0.33

## Native views
- Fix issue where setting `Visibility` to `Collapsed` or `Hidden` would not affect native views

## Fuse.Camera and Fuse.CameraRoll 
- Correct captured image orientation to EXIF values if available on Android. This solves camera orientation issues on Samsung devices.

## Misc
- Animating `Text.Color` and `Stroke.Color` no longer generates run-time warning.
- Fixed a bug where mask-textures didn't align porperly with the element they were on, if the element itself was translucent but had non-translucent children.

## Node.findData() JavaScript method
- Added Node.findData(key) method which returns an observable of the data at key from the parent data context. Can be used to access inherited "global" data from pages/components.

## Data context improvements
- Added support for multiple data objects per node. This fixes problems/ambiguities/bugs related to e.g. having multiple `<JavaScript>` tags per node, `<JavaScript>` direclty on children of `<Each>`, `<Select>` etc.
- As a result, `Node.DataContext` no longer exist, because there might be more than one data-contexts. For code where there were only one data-context, you can use `Node.GetFirstData()` as a replacement. Otherwise, you can use `Node.GetLocalData` to get all data-contexts, to figure out which one you need.

## JS
- Fixed bug where bundled modules evaluated every save when required with "<moduleid>.js".
## onValueChanged subscriber lifetime cleanup
## Observable/parameter subscriber lifetime cleanup
- `Observable.onValueChanged(module, callback)` - now expects `module` as first argument to tie the subscription to the lifetime of the module. Omiting the argument will still work but is deprecated and will leak.
- `this.onParameterChanged(function(param) {..})` deprecated (leaky). Use the new `this.Parameter.onValueChanged(module, function(param) {..}) instead.

## Triggers inside Each
- Fixed data context bugs with triggers, Match/Case and StateGroup when used directly inside an Each tag.
- Uno: WhileValue<T> no longer implements IValue<T>, but WhileTrue/False implements IToggleable, which means `<Toggle />` still works on them.

## Text rendering

- Fixed a bug where text was being truncated/ellipsized on iOS when it shouldn't have been due to rounding errors.

## TextInput

- Worked around an issue where `TextInput` controls were slow to activate the first time it's done when debugging an app using Xcode.
## JavaScript improvements
- Added `module.dispose` feature. Use `module.dispose = function() { ...` to clean up resources, observable subscriptions etc. held by a `<JavaScript>` object. The function will be called when the `<JavaScript>` object is unrooted/removed from the app. 
- Cleaned up object lifetime bugs related to multiple `<JavaScript>` tags in the same `ux:Class`.

## Navigation

- Added `PageControl.ActiveIndex` and `VisualNavigation.ActiveIndex`. `ActiveIndex` is a two-way bindable property suitable for JavaScript to get and set the page, as well as respond to page changes.
- A `Router` may now be used within a UX tree already containing a `Router`. This ends the path chain for the current router and allows distinct navigation for components.
- `Navigator` gains the properties `Reuse` and `Retain` to control the lifetime of pages
- `NavigationControl.IsReusable` is deprecated. Use `Reuse` and `Retain` instead

## ScrollView

- the `ScrollView.PropertyChanged` event, and associated types, have been removed. Use the standard property changed system instead.
- `ScrollView` public properties now generate property changed events

## Transform

- Several fixes were made to how `Transform` dynamically updates when using a `RelativeTo` and `RelativeNode`
- The transform hierarchy has a new `RelativeTransform` layer from which some classes (`Scaling`, `Translation`) are now derived
- The `Transform.RelativeNode` property is no longer available in other transform classes. It was not used in those anyway, so it can be safely removed from your code.
- The `ITransformMode` has changed to be more generic in how it handles subscriptions. If you're derived from this you'll need to implement the new interface and manually subscribe to events.
- `IResizeMode` is no longer a `ITransformMode`. `Resize` subscribes to the `Placed` events of both the `Target` and `RelativeNode`

## Viewport

- `IViewport` split into `IViewport`, `IRenderViewport` and common base `ICommonViewport`. This better tracks the intent of each viewport and identifies where they are being used. This was done since most locations that needed these could not provide the full interface previously, nor could they even define the fields correctly. If one of the fields you need is missing then please contact Fuse support to help with migration.
- `Viewport` can now be used at an arbitrary location in the UX tree, not just as the root element
- `Viewport.Flatten` has been removed, use `Mode="RenderToTexture"` instead.
- Added `IViewport.WorldToLocalRay`
- `Visual.WindowToWorldRay` has been removed, use `Viewport.PointToWorldRay` instead
- `Visual.WindowToLocal` has been made non-virtual. As it can't reasonably be implemented by a derived class we assumed nobody has actually done this. Please contact Fuse support to help with migration if you did.
- `DefaultShading.Viewport` is renamed to `RenderViewport` to avoid name collisions.
- `Trackball` has a new default forward vector of `0,0,1` instead of `0,0,-1`. This accounts for a normalization of our 3D space. This can be modified with the `ForwardVector` property.

## Cycle

- Add `Cycle.FrequencyBack` to control speed when returning to rest state

## GeoLocation
- Fix spelling of property name `auhtorizationRequest` to `authorizationRequest`

## Launcher
- LaunchCall now works with telephone numbers containing spaces


# 0.32.12

# SolidColor Opacity
- `<SolidColor Opacity="..." />` now works when used on Shapes and Panels inside a NativeViewHost

# TextInput
- Fix an issue where toggeling `IsPassword` would make TextInput on iOS change font and its caret glitch
- Fix issue where `IsPassword="true"` would use the Android default monospace font. Meaning that `Font="..."` now works on Android password TextInputs
- Fix issue on desktop where Caret would jump when an empty TextInput got typed into
- Fix issue where databinding PlaceholderText to an observable could make iOS crash

# TextView
- Fix an issue where the background on iOS TextView would always be white

# Native UI
- Add support for `<Panel Background="..." />` and `<Panel Color="..." />` on elements inside a NativeViewHost
- Fix issue where Native views could "pop" for 1 frame as their transforms were not up to date

# Match
- `Match` now inserts its nodes just after itself in the parent. This maintains the intended order. Previously is added to the end of the children -- if you need to this then move the `Match` itself to the end of the children.

# HitTestMode
- Fix an issue where changing the `HitTestMode` did not update the hit test bounds

# Fuse.Reactive
- Event-binding now correcly converts arguments, to prevent issues with invalid conversions when triggering events.
- Fix an issue where errors during data-binding could result in an unandled exception


# 0.32.0

## Huge performance boosts in JavaScript data marshalling 
- Optimization: Rewrote the JS/Uno interop layer to avoid thread sync to read data from JS. Up to 50X speed improvement in cases with a lot of data being displayed. 
- Optimization: Rewrote the JavaScriptCore scripting implementation that is used on iOS to use the C interface instead of the Objective-C interface, which means that certain Uno-JS interoperations are much faster. Up to 10X speed improvement in data intense cases.
- To allow important optimizations, exported JS data contexts containing reference loops are no longer supported and will generate a run time error. This is unlikely to affect your app. If it does and you are unable to migrate, please contact support and we will help you out.

## RaiseUserEvent
- `RaiseUserEvent.Name` renamed `EventName` to match `OnUserEvent` and avoid the `Node.Name` conflict

## Native shapes
- Support for `Shape`, `Rectangle` and `Circle` inside `NativeViewHost` has been aded.

## Camera
- `Camera.takePicture` now throws an exception if passed negative width or height.

## Observable
- The `Observable.slice()` method has been added.

## Bugfixes
- `Blur` and `Desaturate` both triggered an issue in iPhone 6's OpenGL ES driver, that caused transparent areas to become black was fixed.
- Fixed crashes in `MapView` which occured when preview refreshed and async action tries to touch now missing object.
- Data bindings now reset to the original value when the node is unrooted. Prevents flickering of old data in some cases during navigation.
- Multi-touch works on iOS again.
- A bug where `NativeViewHost`s didn't always have a `NativeViewParent` was fixed.
- A bug where `WebView.Eval` silently dropped pending evaluations was fixed.
- fixed an issue with "object reference is null", often seen while using the `Router`
- fixed a layout/hittest problem with the children of `Viewport`
- fixed an error, that leads to the "Ooops" screen in Fuse, resulting from errors in the JavaScript thread during a refresh

## Other
- A warning about failed data-binding was removed, as it lead to spurious errors in valid use-cases.


# Old

## iOS
- Fix visual glitch in iOS keyboard when moving focus between TextInputs
- Use the same default color for Button as XCode uses for UIButton

## TextInput
- Fix bug in where the caret in TextInputs on Android would be at the front of the string instead of the end of the string when focused
- Implemented SelectionColor for TextInputs on Android

## LinearGraident
- Fix bug causing LinearGradient to not invalidate if any of its GradientStops are animated

## Fuse.Maps
- Made Fuse.Maps required on both iOS and Android (it used to be needed on Android only, an unnecessary bit of complexity), also moved all the code from Fuse.Controls.MapView to Fuse.Maps. This should not impact user code in _any way_ so might not be worth mentioning.
- Rewrote MapView on Android and iOS to use Foreign Code over bindings for improved stability and cohesion.

- PullToRelaod now creates default states for unspecified ones. If you previously didn't have a `Rest` state and were relying on `Pulling` being the default you'll have to set that to the `Rest` state now (it was a defect that another state accidentally became the first state).

## Push & Local Notifications
- Both now have clearAllNotifications and clearBadgeNumber methods

## Lifecycle Query State
- Added state property where you can get the current state of the app
- Also added the BACKGROUND, FOREGROUND & INTERACTIVE properties which are constant you can compare with the current state.

## New Fuse.Platform package
- Added Fuse.Platform.Lifecycle and Fuse.Platform.InterApp for hooking onto application events in Uno.

## JavaScript

- Added a flag to select the Duktape JavaScript engine when targeting C++. This is sometimes desirable because the V8 JavaScript engine that we use on Android adds a few megabytes to the generated APK size, but one should be aware that Duktape is slower than V8. Build with `-DUSE_DUKTAPE` to use it.

## Invalidation

- `Visual.InvalidateRenderBounds` made protected since it's a call made only internal to the class

## JS
- Add support for sending and receiving ArrayBuffers in XMLHttpRequest. (req.responseType = 'arraybuffer');

## FuseJS Lifecycle
- Remove `onTerminating` from the js lifecycle api

## Monster

- The base type of navigation classes, `Navigation` has been renamed `VisualNavigation` (as it's navigation of `Visual` objects). The generic and static navigation functions however remain in the `Navigation` class.
- `PageControl` derives from a  common base `NavigationControl` now and some enums have been renamed: `PageControlInactiveState` => `NavigationControlInactiveState`, `PageControlInteraction` -> `NavigationControlInteraction`, `PageControlTransition` -> `NavigationControlTransition`
- Navigation no longer sends per-page progress messages, instead only updating the Navigation object itself. This should not affect UX-level user code, only Uno code that might subscribe.
- `INavigation` gains some new functions. `PageProgressChanged` is now a `NavigationHandler`.

- The children of triggers will now be added to their parent just after the trigger itself. This means the order of the UX file is now preserved even as triggers turn on/off. Previously the children would always be added to the end. If you need to add to the end then place the trigger at the end of the parent.
- How triggers and animations work has been changed. This corrects a few defects and should be backwards compatible.*
- `Padding` on visuals/primitives is now applied differently to be more useful and consistent. The local visual does not honour the padding anymore, only the children.

	<Rectangle Color="#F00" Padding="5">
		<Rectangle Color="#00F"/>
		
Previously the red rectangle would not show since it was the same size as the child. Now it will show in the padding area since it ignores the padding for the local visual.

- `Change.MixOp` has a new default of `Offset` rather than `Weight`. This changes how values are combined in a `Change` animator, fixing a few issues with easings such as `BackInOut`. For properties targetted by only a single animator the change is otherwise not noticable, only for 2+ animators. To get the old behavior use `MixOp="Weight"`.
- If you `Change` a `Size` property, such as `Height`, `MinHeigth`, `Offset`, etc. you must set the value of the property explicitly and not rely on the default setting. Animations from the default to a particular value will either not do want you want or do nothing at all.

- `TriggerAnimationState` has been made internal (it already had an internal constructor)
- *`UpdateStage`  `Mixers` and `PostLayoutMixers` has been removed. The `Layout` stage is no longer exlucsivel layout, and includes all trigger updates. The `AddDeferredAction` function takes a priority to assist in sub-stage ordering.
- *Triggers should more universally use bypass mode during rooting. If you notice an animation that isn't playing when you desire, then use the `Bypass="Never"` mode, or ask for assistance on how to configure the effect you want.

- `ux:Generate="Factory"` is replaced with `ux:Generate="Template"` to be consistent with the new `ux:Template` feature.

- `Element.CalcRenderBounds` no longer includes the `ActualSize` of the element by default. If there is a background it will, otherwise the derived classes must provide their correct size (in addition to calling the base).

- Fuse.Controls.Number has been deprecated. Use a Text control instead with JavaScript formatting:

	<Panel ux:Class="Foo">
		<double ux:Property="Value" />
		<JavaScript>
			exports.DisplayValue = this.Value.map(function(x) {
				return "$ " + x;
			});
		</JavaScript>
		<Text Value="{DisplayValue}" />
	</Panel>

- `OnUserEvent.Name` is renamed to `OnUserEvent.EventName`. This is to avoid a conflict with the generic `Node.Name` that arises due to the Node/Trigger refactoring.

##

- `KeyframeInterpolation.CatmullRom` has been given the friendlier name `Smooth`. The old name is left an alias for now (it will be removed at some point).

## MapView
- Removed `ZoomMin` and `ZoomMax` properties
- Made iOS and Android maps respond to the same kind of zoom values (a factor between 2 and 21)
- Fixed issue where databinding on `MapMarker` properties would fail outside of `Each`

## TextInput
- Added support for `AutoCorrectHint` to control auto-correct on iOS and Android
- Added support for `AutoCapitalizationHint` to control auto-capitalization on iOS and Android

## ScrollView sizing change

As styles are being deprecated the manner in which the @ScrollView determines it's content alignment and size has changed. It should, in most cases, be identical to before.

The one exception is with minimum sizing. If you previously did not specify an Alignment, Height/Width, or MinHeight/Width the minimum width would be set to `100%` by default. this is no longer done. If you need this then add `MinHeight="100%"` to the content of the @ScrollView.

## Animation control for navigation and scrolling

- Removed `StructuredNavigation.EasingBack` and `DurationBack` as they have no equivalent in the new motion system.
- Deprecated `StructuredNavigation.Easing` and `Duration` as they are now ambiguous in the new system. In the interim they will be mapped to `Motion.GotoEasing` and `Motion.GotoDuration`, though the meaning is not exactly the same (use `GotoDurationExp='0'` on a `NavigationMotion` to get a flat duration as before). Refer to the full `NavigationMotion` type.

	<LinearNavigation>
		<NavigationMotion GotoEasing="SinusoidalInOut" GotoDuration="0.4" GotoDurationExp="0"/>
		
- Removed `SwipeNavigation.SwipeEnds` and `PageControl.SwipeEnds`, use a `NavigationMotion` with the `Overflow` property instead.

	<PageControl>
		<NavigationMotion Overflow="Clamp"/>
	
- The package `Experimental.Physics` has been removed: the API is still under too much flux to release, and the code has moved to a private package in Fuse.Motion (which exposes high-level interfaces where appropriate). If you were using some of this code in your project please contact us and can make the previous source available.
- Introducing the `Fuse.Motion` package for high level simulation and physics configuration/behaviour
- The option to set an `Attractor.Simulation` has been removed for now, as the simulations are private. Use the `SimulationType` parameter to configure the type.
- `Attractor.SimulationType` has been removed. Use the `Type` and `Unit` property instead.
- Deprecated `ScrollableGoto` in favour of `ScrollTo`. This is simply a name change -- the old name still works with a deprecation warning.

## Swipe navigation

- `PageControl.AllowedSwipeDirections` and `SwipeNavigate.AllowedDirections` have been added to control the allowed swiping direction
- `SwipeNavigate.SwipeDirection` is replaced with `SwipeNavigate.ForwardDirection` to clarify the direction you swipe to go "forward". This new property is actually the opposite of the previous one, so if you have `Left` you want `Right` now, `Up` becomes `Down`, and vice versa.
- `SnapTo`, `EndSeekArgs`, and `UpdateSeekArgs` and `ISeekable` have been made internal to `Fuse.Navigation`. These are an implementation detail that cannot be used publically.

## Fuse.Video
- Fixed preview crashbug on Android
- Fixed bug causing preview to be stuck on "Host loading project..."
- Fixed memoryleak in .Net on Windows
- Fixed bug causing preview to be very slow when using video

## Added LocalNotifications

Supported on iOS and Android

## Bug fixes
- Fixed a compilation error that appeared when using Xcode 7.3

## Resolution and density changes

- `PointDensity` => `PixelsPerPoint`
- `OSPointDensity` is deprecated, replaced with a `PixelsPerOSPoint` which is not the same actual value

## Scrolling

- `ScrollingAnimation.ScrollDirections` by default now matches the `ScrollView.AllowedScrollDirections` (instead of just being vertical). If `Both` are allowed then `Vertical` is used. You can still override as desired.
- `BringIntoView` and collapsing items should now be properly reflected in the scroll position
- Added `ScrollingAnimationRange.SnapMax`, similar to `SnapMin` except for the maximum end of the `ScrollView` snapping area
- `ScrollView` respects `SnapToPixels` better now (there were a few cases previously where it would not)

## Fuse.Video
- Fixed bug where Video would crash on certain devices (ex LG G2)

## ColumnLayout 

- `ColumnLayout` handles Max/Min layout constraints now correctly. If you notice a change in your layout look to the `MaxWidth/Height` property to verify that if it is what you want.

##

- `SwipeNavigation.SwipeAllow` and `PageControl.SwipeAllow` to limit the direction the user may swipe. Default is `Both`, but may be `Forward` or `Backward` to allow swiping in one direction only.

##

- `PageControl.HitTestMode` is now `LocalBoundsAndChildren` by default so that items without a background can be swiped. If there is some reason you don't want this just override `HitTestMode="LocalVisualAndChildren"` on the Pagecontrol to get the previous behaviour.

## ZOffset

- introduce `Node.ZOffset` to control layer zordering of children

## RangeAdapter

- A new `RangeAdapter` that allows finer control over playback of parts of animations

## MapView API changes
- The MapMarker Location property has been removed. Use Latitude and Longitude properties instead.

## JavaScript operations

- State transition with `StateGroup` and `State` can now be done in JavaScript
- Animation playback of a `Timeline` can now be controlled in JavaScript
- Limited scrolling in a `ScrollView` is available now in JavaScript
- `MapView` tilt, bearing, location, zoom and markers can now be controlled in JavaScript.
- `WebView` url and loading of html can now be controlled via JavaScript `goto(myUrl)` and `loadHtml(myUrl, myBaseUrl)`

## Changed how properties with units (%, px etc.) are implemented

- Removed StylePropertyWithUnit, instead introduced `Unit`, `Size` and `Size2` in the `Uno.UX` namespace.

All properties that support units (such as `Width`, `Height`, `Anchor`) are now of type `Size` or `Size2`, and can be set in Uno code like this:

	elm.Height = 100; // defaults to points, implicit cast from float and int to Size
	elm.Height = Size.Points(100); // does the same as the line above
	elm.Width = Size.Percent(30);
	elm.Anchor = Size2.Percent(50, 50); // sets Anchor="50%,50%"
	elm.Offset = new Size2(Size.Points(100), Size.Pixels(30)) // sets Offset="100,30px"

This means that `Change` now also supports units. The original and target value must have the same units.
	
	<Panel Width="50%" ux:Name="p1">
		<WhilePressed>
			<Change p1.Width="100%" Duration="1" />
		</WhilePressed>
	</Panel>

## Misc

- Added `Observable.toArray` method that returns a copy of the values array
- `Fuse.Scripting.Marshal` is available to convert from JS types for Uno callbacks
- Deleted obsolete modules: `FuseJS/Fetch` and `FuseJS/FetchJSON`. Use plain `fetch()` instead.

## Data bind bundled files

- Files in the project bundle can now be data-bound by file name string. Example:

	    <JavaScript>
            exports.imageData = "image.jpg";
        </JavaScript>
        <Image File="{imageData}" Width="200" Height="200"/>

Given that `image.jpg` is included in the `.unoproj` bundle:

	"image.jpg:Bundle",

The file can also be included by glob. The following line will include all jpg files in the project folder, recursively:
	
	"**.jpg:Bundle",

## Data binding fixes

- Fixed bug where DataToResource would not work if bound to an Observable

## TextInput.InputHint
- `TextInputHint.Number` has been renamed to the more accurate `TextInputHint.Integer`. `Number` is still available as a deprecated alias during the transitional period to be removed in a future release.
- `TextInputHint.Decimal` has been introduced to allow decimal point value input.

## IsEnabled and IsContextEnabled

- the `IsEnabled` property is now local to the node and does not reflect the state of parent nodes as it used to. To get the actual contextual enabled status of a node use `IsContextEnabled`.

## Android and iOS MapView

- Added Fuse.Controls.MapView for iOS and Android via the Fuse.Maps package


## Changes to Fuse.Node

- The Node.Update event is removed (legacy API). Instead add and remove actions directly to UpdateManager when the object in question is rooted.
- The Node.Added and Node.Removed events are removed (legacy API). Add/remove operations have no logical consequence, and nothing should ever need to happen in response. instead, care about Rooted/Unrooted semantics.
- The Node.OnAdded/OnRemoved has been removed, and hence rooting protocol has changed. If you relied on these methods, contact the Fuse crew on the Slack community for help to migrate.

## Bugfixes

- Fixed bug in FuseJS `Observable` implementation that caused some subscribers to receive outdated update messages.
- Fixed bug in observable propagation that would sometimes give wrong array data in the UI.
- Made all processing in FuseJS transaction-based, so the UI will never update to reflect a mid-transaction state.

## FuseJS
- Added module fuseJS/Bundle to read `:Bundle` file types. You can read string async using `read` or sync using `readSync`

## Improved require() function (FuseJS)

`require()` can now require script files directly from the bundle, without declaring them as `ux:Global`.

You can now require files relative to the current script, or relative to the project root like this:

	var foo = require("./foo"); // relative to this file
	var bar = require("/bar.js");  // relative to project root
	var bar = require("bar");  // relative to project root, or global module
	
The bundle is also properly simulated in `fuse preview`, so adding new script files can be done on the fly. Oh, and it now also deals with circular dependencies gracefully. Happy birthday!

## Improved UI/JS synchronization

In Fuse, JavaScript and UI runs on separate threads, so that JS workload will never affect the smoothness of animation of the native, slick animation that is going on in the UI. However, up until this version, there has been some problems with update latency and inconsistencies due to the UI updating piecewise, giving weird "glitch frames".

This is now all fixed. We rewrote how UI synchronizes with JavaScript state to make it faster, prettier and always consistent. You're welcome.

## PageControl

- `PageControl` uses a new mechanism to maintain it's children. `Page` is no longer special as all children are considered pages. The new approach allows nesting of `PageControl`.
- New `PageControl.InactiveState` to control the visibility/enabled status of inactive pages. By default they will now be collapse and disabled for efficiency reasons. To get the old visible/enabled behaviour set `InactiveState="Unchanged"`
- New `PageControl.Transition`
- New `PageControl.Interaction`


## Visuals

- Primitives, `Image`, `Shape`, and `TextControl`, should not have any child nodes. This is being deprecated and the ability will be removed. It can only be partially enforced at the UX level (unfortunately with a not-so-clean error message for now). These nodes need to be leaf nodes for optimization reasons.

A common previous scenario might have been to add a `Rectangle` to a `Text` node:

```
<Text Alignment="Center" Padding="5">
	<Rectangle Layer="Background" Color="0,1,1,1"/>
</Text>
```

This should now be done using a wrapping `Panel` instead:

```
<Panel Alignment="Center" Padding="5">
	<Text Alignment="Center" Padding="5"/>
	<Rectangle Layer="Background" Color="0,1,1,1"/>
</Panel>
```

- Shapes (Circle, Ellipse, Rectangle, Star, RegularPolygon, Path) are no longer implemented with visual children in Graphics mode. They are directly drawn in the semantic control type. This will not likely affect any user code.
- Padding has been fixed in some shapes. This will alter the positioning of shapes that have padding.
- `Node.InvalidateVisual` is no longer `virtual`, override the `OnInvalidateVisual` function instead. This gives Node better control over when it is called, and how to invalidate
- `Node.IsVisualInvalid` has been removed as the invalidation system is active (at time of invalidation), thus nothing should (or did) check that flag

## NativeWithFallback

- The `NativeWithFallback` theme is now only available if you include the `Fuse.BasicTheme` package (it's what implements the fallback).

## WebView fixes
- Fixed issue where Url could only be set via observable strings (!)

## AlternateRoot

- `AlternateRoot` was added to allow adding nodes to a parent other than where they currently are in the UX tree

## Scripting

- Fixed a bug where certain UX filenames (e.g. folders starting with 'u' on
  Windows) caused exceptions in `JavaScript` elements due to unescaped paths.
- UTF-8 in JavaScript on Windows DotNet builds should now work.

## Removed unused fonts from Fuse.BasicTheme

These fonts cannot be referenced withouth adding them as globals yourself:

- RobotoBlack
- RobotoBlackItalic
- RobotoBold
- RobotoBoldItalic
- RobotoItalic
- RobotoLightItalic
- RobotoMediumItalic
- RobotoThin
- RobotoThinItalic
- RobotoCondensedBold
- RobotoCondensedBoldItalic
- RobotoCondensedItalic
- RobotoCondensedLight
- RobotoCondensedLightItalic
- RobotoCondensedRegular

## Timeline & Pan/Zoom/Rotate gesture

- `Timeline` is now off by default at progress 0, use `OnAtZero="true"` to force it to be on at progress=0. This setting is actually uncommon, and should only be used if you're certain it is applicable (when the animators don't have a rest state)
- Added `ZoomGesture`, `RotateGesture`, `PanGesture` and `InteractiveTransform`
- Added `RelativeTo="Size"` to `Resize` allowing resizing to the size of another element
- `Pulse` should no longer be used on a `WhileValue` /`WhileTrue` trigger. Use a `Timeline` instead if you need `Pulse` funtionality
- New `PulseForward` that plays a `Timeline` to the end and then deactivates it
- New `PulseBackward` that plays a `Timeline` to from the end to the start
- New `ColumnLayout.ColumnSize` that allows a dynamic `ColumnCount` based on the availabe size
- `Attractor` now better works with 2-way bindable values (something else can modify the target value that is also used in an attractor)
- All interactions can now be cancelled, the `CancelGestures` action can be used to do this.
- A `Cancelled` argument is added to `Node.BeginInteraction`. Behaviours must support this is they support interaction.

## New Color Properties

All controls (panels, shapes, text etc.) as well as `Stroke` now have a general purpose `Color` property, which is of type `float4`. This property controls the main color of the object. For a `Panel` it corresponds to `Background`. For a `Shape`, it corresponds to `Fill`, etc.

The main benefit of this property (beyond just being a nicer and more consistent name), is that `Color` as it is a `float4` can be animated using `<Change something.Color=..`, while `Background`, `Fill` and `Brush` cannot (as they are brushes).

We reccommending changing all uses of `Background` and `Fill` to `Color` when you only want to assign a static color. All examples and docs are updated to reflect this.

## GraphicsView
- `Fuse.Controls.GraphicsView.Background` has been removed in favor of simply using Control.Color

## Circular layout and behaviour

- `Fuse.Controls.Graphics.LinearSliderBehavior` renamed to `Fuse.Gestures.LinearRangeBehavior` to make it more accessible.
- the `Node.PointDensity` shortcut to `Viewport.PointDensity` has been removed as it caused an unresolvable loop in the code. Just use `Viewport.PointDensity` as there should always be a viewport on rooted nodes.
- `CircleLayout` can be used to arrange children around a circle, or partial circle
- `RangeControl2D` is a 2d semantic range control (there is no standard visual implementation of this)
- `CircularRangeBehavior` can be used for range controls to create a circular, or arc, based control
- `Element.IsInteracting` moved to `Node.IsInteracting` to support general interactions on nodes
- `InteractionCompleted` indicates the user is done interacting with an element (counterpart to `WhileInteracting`)

- `ElasticForce.CreateRadians` renamed `CreateAngle`, `CreateDegrees` removed and the adapters `AngularAdapter` and `AdapterMultiplier` added. Avoid using these directly though, use only `DestinationSimulatorFactor.Create`.
- `DestinationSimulationType.ElasticForceRadians` changed to `DestinationSimulationType.ElasticForceAngle` This is to change the type into a flags type and be more generic.


## Aspect

- An `Aspect` property is added to `Element`. It only has meaning with `BoxSizing="FillAspect"`. This sizes the element based the avaialble size provided to it from its parent. The size of the content of this element is not considered int he sizing.
	<Panel Width="20%" Aspect="1" BoxSizing="FillAspect"/>
This creates a square panel that is 20% the width of its parent.
- `LayoutParams.Clone` is split into different functions. `TrueClone` does a deep copy of all parameters, it is unlikely this one will be used often. `DeriveClone` does a typical element derivation, in particular it clears the locally set values such as `ContainerSize`.
- `DockPanel` now understand % relative units for is children. Those will be relative to the entire container. This is a change from previously where such relative units would always result in 0. Note this also applies to the `Dock="Fill"` items (the default ones). So if you previously used that to size relative to the remaining space you will have to wrap that in a Panel first to establish the new relative basis.  For example:

```
<DockPanel>
	...
	<Panel Width="50%">...
```

Becomes

```
<DockPanel>
	<Panel><Panel Width="50%">...
```

## V8

- We now use V8 in OSX and Windows local preview builds, DotNet builds, CMake builds, and MSVC builds
- The V8 library has been updated to version 4.8.271.9
- Added a `-DDEBUG_V8` build flag which enables the V8 debugger. See the [debugging guide](https://www.fusetools.com/learn/guides/debugging) for more information on how to use it.

## WhileInteracting

- `WhileInteracting` is active for a `SwipeGesture` while the user is swiping
- `WhileInteracting` is active for a `ScrollView` while the user is scrolling
- `IsInteracting` moved up to `Element` from `Control`
- `Swipe.IsActiveChanged` is now a `ValueChangedHandler<bool>`. `SetValue` renamed to `SetIsActive`. 2-way data binding enabled.

## Timeline

- `Timeilne` will now use a backwards animation when playing backwards
- `TriggerAnimation.CrossFadeDuration` (via Trigger.CrossFadeDuration) allows changin the duration of the cross-fade between forward/backward animations on direction switches
- `Timeline` is now "active" at Progress=0. This allows animators to have an effect even at this progress -- on other triggers the animators are essentially removed when the Progress==0.
- `Timeline.PlayMode` added with the option of `Wrap` to loop the timeline
- `Timeline.InitialProgress` to set the progress at rooting time
- `Timeline.Progress` is now a two-way bindable value
- `Pulse.Target` is now an `IPulseTrigger` allowing more items to be pulsed, such as `Timeline`
- `Video.ValueChanged` is removed, use `Video.ProgressChanged`

- `Cycle` a few properties have been made internal that were not meant to be public `IsZeroCrossing` and `IsOneCrossing`
- `Cycle.ProgressOffset` allows specifying the offset instead of taking the auto-calculated one. This may result in jerky animations on starting/stopping a trigger.
- `Cycle.Easing` allows an easing funtion to be applied to the progress. This disables the auto-calculated `ProgressOffset` and may reuslt in jerky starting/stopping.

## Layout Sizing Changes

- `DefaultLayout` no longer does two-pass sizing, only the maximum size of the first pass will be used to report its size. The previous two-pass was not numerically stable (each pass could produce larger and larger results, thus making 2 passes no better than 1)
- `StackLayout` no longer does two-pass sizing by default. While there are scenarios where it can be required it doesn't come up often and it has a significant cost associated with it. If an element of your StackPanel (possibly the background) no longer has the correct size you can enable the two-pass mode with `Mode="TwoPass"`.
- In some situations if a `Width` and `Height` were specified on an element the Max/Min values would be ignored, thus allowing the element to violate those constraints. This has been fixed.

- `Node.GetMarginSize` has a new signature `float2 GetMarginSize(LayoutParams lp)`. The previous avilableSize is the `Size` property of that object, and the `HasX` and `HasY` property can be used to check for their existence.
- `Node.ArrangeMarginBox` has a new signature `float2 ArrangeMarginBox(float2 position, LayoutParams lp)` as does `OnArrangeMarginBox`. This matches the change made to `GetMarginSize`.
- The layout engine no longer does a second pass when enforcing Min/Max properties, it simply constrains the size. Elements that need to adapt based on the max/min must do so during the initial sizing request, as `Image` and `Text` now do. The `LayoutParams` has the maximum and minimum information inside it.
- `SizeFlags` is removed, the user of `LayoutParams` removes the need for it

Layout now also makes a couple of assumptions:
- SnapToPixels is expected to work only if all parent nodes/elements have this enabled as well.  (At the moment it may still work without, but this is expected to change)
- The arrangement of a node may not be dependent on its position, but only its size. So a 100x100 element has the exact same arrange at 50,75 as it does at 5,7. This is to support an optimal layout system of panels where the position may not be known before the size.

## DrawContext.Current

- `DrawContext.Current` has been removed. Calls to `draw` with `DefaultShading` must include a `DrawContext: dc` now.

## SwipeNavigate

- `LengthNode` to use the size of a particular element as the swipe length instead of the navigation's owner
- `MaxPages` option to limit how many pages can be swiped with a single gesture

## Android TextRenderer
- A crash-bug when the `Value` property was null has been fixed.

## Element caching
- An internal crash-bug in the `Element`-caching that occurred when the element-tree was changed has been fixed.

## LoadHtml HTML 
- `LoadHtml` now takes an `<HTML>` node for inline HTML like the `WebView` for consistency.

## Text/TextInput LineSpacing

- We now respect LineSpacing on Android and iOS

## Opacity threshold

- Elements with a low opacity now remain hittable, previously they would stop being hit targets. This change allows a way for invisible things to receive hits, which was previously not possible (as well as removing a suspicious behaviour). The `HitTestOpacityThreshold` has also been removed. To make an item non-hittable use one of the alternatives: `Visibility="Hidden"`, `HitTestMode="None"` or `IsEnabled="false"`. 

For example, if you had a a trigger like this:

```
<EnteringAnimation>
	<Change Myself.Opacity="0"/>
</EnteringAnimation>
```

And relied on it becoming unhittable, you must now explicitly disable it and/or make it truly invisible:

```
<EnteringAnimation>
	<Change Myself.Opacity="0"/>
	<Change Myself.Visibility="Hidden"/>
	<Change Myself.IsEnabled="false"/>
</EnteringAnimation>
```

Setting things invisible and disabled also enables some performance gain in the application.


## LimitHeight/Width

- `LimitHeight` and `LimitWidth` are now style properties of `Element` directly, not attached properties. If you referred to them with the `LimitBoxSizing` prefix drop that from the UX files. In Uno the style properties are inside `Element` now.
- The default unit of `LimitHeight` and `LimitWidth` is now `Points` to be consistent with other unit based notations. You must add a % to the value if this is what was expected `100%`.

## WhileWindowAspect
- Cleanup and add fallback in case a root viewport is not found.

## WhileContainsText

- `ContainingText` is a deprected name, use `WhileContainsText` instead
- `WhileContainsText` now works on any `IValue<string>`, such as the base `TextControl`, not just a `TextInput`

## Layout

- `BoxSizingMode.Shadow` renamed `BoxSizingMode.LayoutMaster` to be consistent with class. This does not affect any UX code.
- Setting `LayoutMaster` to null reverts to the standard box-sizing model for the element
- Several globals were moved from `LayoutAnimation` into `LayoutTransition` to allow reuse elsewhere. This should not require any UX change as the global names have not changed. Uno change will require using the other class name `LayoutAnimation.PositionLayoutChange` => `LayoutTransition.PositionLayoutChange`.
- `ITranslationMode`, `IScalingMode`, `IResizeMode` derive from `ITransformMode` now and have a `Flags` property. If you should happen to have one in your code you can simply return `TransformModeFlags.None`

- New `TransitionLayout` action
- New `TransformOriginOffset` for `Translation.RelativeTo`. Provides a distance, in local space, between the `TransformOrigin` of the source Node and the `RelativeNode`. It expects `Element` for both nodes (will use a 0,0 origin if not an element)
- New `PositionOffset` for `Translation.RelativeTo`. Provides a distance, in local space, between the position of the two nodes.
- New `SizeFactor` for `Scaling.RelativeTo". Provides the ratio in sizes between the two Element's. This allows scaling one element to be the size of another.

## iOS Text fixes
- Setting Text.TextWrapping=NoWrap Native theme will no longer lead to text-wrapping


## Android Video fixes
- Sending Android apps to the background will how pause/resume any playing Videos.
- Playing a video on Android while other music is playing on the device will now acquire audio focus and stop other audio.

## OnKeyPress and OnBackButton
- Added `OnKeyPress` trigger taking a Key value
- Added `OnBackButton` OnKeyPress extension with `BackButton` preset to capture Android back button event

## WhileWindowSize
- Added `WhileWindowSize` trigger which lets you gate on window dimensions (in points).
- Supports `GreaterThan`, `LessThan` and `EqualTo` float2's.
- `<WhileWindowSize GreaterThan="640,480" LessThan="1280,720">`

## Layout

- `StackPanel` and `StackLayout` now handle oversized content differently. It has a `ContentAlignment` parameter which decides how to align that content, and defaults to match the alignment of the panel itself. (Only alignment in same direction as the orientation of the panel is supported). 

This means the alignment of some old code could change if the content was too big for the containing panel. The old behaviour was equivalent to `ContentAlignment="Top"` or `ContentAlignment="Left"` (depending on `Orientation`).

The new defaults are considered the more correct behaviour and this is considered a bug fix.

- `Grid` and `GridLayout` have the same change as `StackLayout`, though it supports all non-default alignments for `ContentAlignment`.

- The `Layout` constructor and several of its functions are now internal. They were not intended to be public before as it is an internal mechanism. The high-level layout specification remains as-is (all UX code remains unaffected).
- removed unused `DrawCount` facility

## WhileCanGoBack and WhileCanGoForward

- Fixed the Context/NavigationContext inconsistency with other navigation triggers. To target navigation triggers, `NavigationContext` is the property to use now.

## WebView

- Added `Source` and `BaseUrl` attributes for loading html source via databinding in the context of a base url (use depends on platform though both android and ios webkit views use the same concept).
- Added `LoadHtml` Action for telling a webview to load html source from a string and a baseurl.
- Added `HTML` node for WebView letting you cdata inline html as such:
```
<WebView>
	<HTML>
		<![CDATA[
			<h1>Hello world</h1>
		]]>
	</HTML>
</WebView>
```

## DebugAction
- `DebugAction` no longer outputs time and frame by default in addition to its Message.
- `DebugAction` can contain certain debug nodes. For now these are `DebugProperty`, `DebugTime` and `DebugFrame`
- `DebugTime` outputs the current application time
- `DebugFrame` outputs the current total frame count
- `DebugProperty` takes a `Tag` string identifier and a `Value` property string (like `Change` and `Set`) and prints that current value prefixed with the Tag
- A `DebugAction` without a `Message` only prints its child debug nodes if any.


## TextEdit

- the namespace `Fuse.Controls.TextEdit` is renamed `Fuse.Controls.FallbackTextEdit` to avoid collision and be clearer as to its purpose
- `TextInput` is now derived from `TextEdit` 
- `TextEdit` is introduced as an unstyled text input type. Most things (ex. triggers) that accepted a `TextInput` before now accept a `TextEdit`.

##

- The setter `HierarchicalNavigation.ReuseExistingNode` now correctly uses the provided value (previously it just assigned false)
- Some parts of the animation system have been marked internal; they were incorrectly marked as public before. They cannot be supported in the manner they were exposed. It's unlikely to impact any user code.
- `TriggerAnimation.GetTotalDuration` renamed `TriggerAnimation.GetAnimatorsDuration` to avoid conflict/confusion with what it does and a new time scaling feature

## 

- `LimitBoxSizingData` has been removed. The properties `LimitWidth` and `LimitHeight` can now be placed directly on the element. Units use the usual syntax: `<Panel LimitWidth="100%"/>`
- `Cycle` gains the `Waveform` option. Of particular interest is `Sawtooth` which animates in one direction in a linear fashion

## More Layout animations

- `Transform` now has an internal constructor. User classes are not supported as it's important internally to have a controlled list.
- `INavigation.ActivePage` added to return the currently active page. This fixes some issues using DirectionNavigation and PageBinding.
- `LayoutChanged` has been removed, leaving only `Placed`. It also does not contain any previous world information, as it was not possible to derive in a consistent fashion. An interested listener must use `Preplacement` instead, but generally this is all part of an internal mechanism that should not be used in user code.

## Layout animations

- `LayoutArgs.PositionChange` is renamed to `WorldPositionChange` and gains `OldPosition` and `NewPosition`
- `LayoutAnimation.GetPositionChange` has been made internal (it should not have been exposed before)
- `RelativeTo="LayoutChange"` should no longer be used and will be removed. Use instead the specific `WorldPositionChange` or `SizeChange` depending on which animator
- `PositionChange` is also added as a `RelativeTo` option, but refers specifically to the position within the parent (non-global changes)
- a new `Released` trigger that pulses when a pointer is released in the node (without capture or previous down event)
- `WhilePressed.Capture` allows a `false` option (default `true`) to not capture the mouse to track the trigger. It will be active so long as the pointer is within the element and pressed.

## TextInput placeholder

- TextInput now has PlaceholderText and PlaceholderColor properties, to show descriptive text in these while empty.

## MaxWidth/Height change

- The implied 100% MaxWidth/Height is no longer implied if a corresponding Width/Height parameter is specified. This means that an element with a `Width` parameter is no longer constrianed to its parent width by default, and a one with a `Height` parameter is not constraint to the parent height by default. This affects only a small fraction of layouts, resulting in larger elements. If you need the old behaviour on an element just add back in the explicit MaxWidth/Height property:

	`<Panel ... MaxWidth="100%" MaxHeight="100%">`
	

## WhilePaused, WhilePlaying and WhileCompleted triggers

- Added WhilePaused, WhilePlaying and WhileCompleted triggers, these can be used in any media playback element in fuse. Currently only Video

## Fuse.Video

- Added support for video playback on mobile exporttargets. Video can be played from file or network stream, supported formats are limited to the formats the specific device or os you are building for. [Android supported formats](http://developer.android.com/guide/appendix/media-formats.html) [iOS supported formats (found under player.movie)](https://developer.apple.com/library/mac/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html)

## LayoutMasterBoxSizing

- To avoid potential confusion with effects the `ShadowBoxSizing` has been renamed `LayoutMasterBoxSizing`. In particular, the `ShadowElement` property is not `LayoutMaster`.

## ButtonText

- `ButtonText` is no longer in the global namespace (that was an error), it is now `Fuse.BasicTheme.ButtonText` as it is theme specific. If you used `ButtonText` somewhere you need to replace that with `Fuse.BasicTheme.ButtonText`

## UpdateManager

- The UpdateManager has an `PostAction` now which collects actions to be run prior to primary update. The dispatch invoker now uses this mechanism to avoid mixing the actions with the deferred actions.


## TextInput Action

You can now react to the primary keyboard action on a `TextInput`. Use the `ActionTriggered` property to specify a callback or use `TextInputActionTriggered` trigger.

	<TextInput ActionStyle="Search" ActionTriggered="{goSearch}">
		<TextInputActionTriggered>
			<ReleaseFocus/>
		</TextInputActionTriggered>
	</TextInput>
	
The `ActionStyle` property selects what the standard action button on the keyboard displays.

## TextInput completness and polish

- Multiline textinput on iOS implemented
- Better integration of textinput on mobile export targets, native focus cooperates with fuse focus to request and dismiss the keyboard

## NativeViewHost

- A `NativeViewHost` is now required wiht the `Graphics` or `Basic` theme to create native only controls such as `WebView`. For example:

	<NativeViewHost>
		<WebView Url="https://fusetools.com"/>
	</NativeViewHost>
	
Previously a `WebView` would work directly in the graphics themes. This was not desired as we wished to make clear the special status of these controls. 
- `Fuse.iOS.Controls.WebView` and `Fuse.Android.Controls.WebView` should not be used anymore, and previos code using them will likely fail now. Use the above setup to get a native `WebView`.
- `NativeViewHost` no longer inherits any style from its parent nodes. It uses the platform basic style and does not cascade upwards. You will have to add styles to the Node to have them apply to items inside of it.

## Extended WebView API
- WhileLoading, PageBeginLoading and PageLoaded triggers
- GoBack, GoForward and Reload triggers for webview taking a WebView argument to point at a specific view.
- LoadURL trigger action for telling a webview to go to a certain url with WebView and Url args
- EvaluateJS trigger action for executing arbitrary javascript within a webview context and optionally passing the stringified json result of the evaluated JS to a FuseJS callback. 

## Android NativeTheme corrected transform origin
- Default origin on Android views is center while Fuse transforms are based on top/left. This should be corrected now.

## Android NativeTheme Text alignment

- A bug where changing the value of a `Text`-element did not cause the text to resize has been fixed.

## FuseJS `Observable.insertAt`

- `observable.insertAt(index, value)` inserts a value at a specific index in an Observable.

## V8

- We now use the V8 JavaScript engine on Android. This enables JavaScript debugging on Android and is faster than the previous JavaScript engine.

## FuseJS `Observable.map`

- The `map` function on `Observable`s now accepts a function with an optional index parameter, as in `observable.map(function (x, i) { return x + " has index " + i })`.

## LayoutChange

- `LayoutChange` in the `Move` and `Resize` animators now requires that `X` and `Y` (or `Vector`) are specified. It previously assumed those values were `1` which is a defect, and was not intended to work. The default is 0 meaning the transform will have no effect.
```
	<Move RelativeTo="LayoutChange"/>
	<Resize RelativeTo="LayoutChange"/>
```
Becomes:
```
	<Move RelativeTo="LayoutChange" Vector="1"/>
	<Resize RelativeTo="LayoutChange" Vector="1"/>
```
This is to facilitate values other than `1` during layout transitions (for example, to animate X and Y independently).
- `IResizeMode.GetSizeChange` has new parameters, expressed as a base size and delta instead of old and new size.


##

- `Node.IsRooted` has a new meaning now. It becomes `true` only after the `OnRooted` function is called on the Node. This is most likely what code meant when checking this status, thus no change is anticipated to be necessary.
- Rooting stages are now clearer and children will not be rooted until their parent is essentially finished rooting.

##

- `Fuse.iOS` has been restructured for clarity. Native views are now in the `Fuse.iOS.NativeViews` namespace and leaf implementations are in the `Fuse.iOS.Controls` packages, where the names match the Fuse control of the same name.

##

- `Uno.GraphicsContext` is deprecated and should no longer be used. Use only `DrawContext` to retain a consistent GL state.
- `DrawContext.ViewportPixelSize` renamed to `GLViewportPixelSize` to better reflect what it is -- as it is not the same as the IViewport.PixelSize in all situations. You should avoid using the `GLVuiewportPixelSize`, it usually isn't the value actually wanted.

##
- Fixed: multi-line text-input on iOS. Earlier, the multi-line flag was ignored on iOS.
- Fixed: custom fonts in simulator should now load correctly.

- `Circle` an angle of 0 now points to the right (not up) to coincide with the natural direction and screen coordinates. Subtract 90 from existing values to get the same result.

## New FuseJS Features
We have begun making new features available to JS, this is only the beginning of this functionality so expect a lot of growth here in the coming months.
- The `InterApp` module allows you you to receive and handle custom URIs from other apps and also to launch other apps using their custom uri.
- The `Lifecycle` module lets you listen your app's lifecycle events. These lifecycle events are normalized across platforms and behave well even on platforms like android which are known to have erroneous evnents)
- The `Maps` module lets you open the platform's maps app at a given location or initiate a search on the map.
- The `Phone` module lets you start a call to a given phone number
- The `Email` module lets you open the platform's mail app at the 'compose' screen populating the fields with js strings.

## X,Y, Offset

- `Element` gains an `X`, and `Y` property which replace the old `Offset` property. If `X` is specified it sets the default horizontal alignment to Left and then offsets from that alignment. If `Y` is specified it sets the default vertical alignment to Left and then offsets from that alignment.
- The `Offset` property still offets but no longer modifies the alignment, thus stretching can still be used. To migrate either replace `Offset` with `X` and `Y` or set `Alignment="TopLeft"`.

## Grid Columns and Rows

- Renamed properties on Grid and GridLayout: `ColumnData` -> `Columns` and `RowData` -> `Rows`. The old `Rows` and `Columns` (which are only used in Uno code) are now called `RowList` and `ColumnList` respectively.

To migrate, change:

	<Grid RowData="1*,2*" ColumnData="100px,auto">

To:

	<Grid Rows="1*,2*" Columns="100px,auto">

## Native

- An `<App>` without a theme tag implied a `Basic` theme previous, but now it implies an "empty" theme. Add `Theme="Basic"` to your App, and include the `Fuse.BasicTheme` package in your project to get the basic theme.
- `Fuse.Elements.ImageElement` removed. Use the high-level `Image` to wrap native/graphics images.
- The hit test for `Image` is now strictly within the visible image, not the empty area in the control, in cases where the image does not fill the control entirely
- `Fuse.Shapes` is no longer part of the standard namespaces. `Circle` and `Rectangle` are now controls in Fuse.Controls.
- `WhileSliding` has been replaced with the more generic `WhileInteracting`
- `ScrollViewer` renamed `ScrollView`.
- `ScrollView.Behavior` removed. You can use the `KeepFocusInView` and `UserScroll` properties directly. If you need a scroll view that doesn't have standard behaviour you'll have to create a style that doesn't add that behavior.
- `IScrollable` has been removed. A `Scroller` must be rooted inside a `ScrollView`.
- `BasicTheme` `Button` no longer sets the style of all text contained within, only the `ButtonText` has a style now. If you were using `Text` inside a button you can use `ButtonText` instead.
- Many of the basic controls are now derived from `Panel`, making it even more important you never style panel. If you need a custom panel type then create one with `<Panel ux:Class="MyPanel"/>` and apply a style to that panel.
- `Node.LayoutRole` made a style property of `Layout` since that is the only node in which it applies (used by Layout)
- `Fuse.LayoutRole` moved to `Fuse.Layouts.LayoutRole`
- `Control.VisualTree` has been removed. Several controls, like `ScrollView` derive now from `ContentControl` which exposes `Content`. This likely doesn't require any code change, but if you were using `VisualTree` in a custom control, you must now use `ContentControl` and the `Content` property.
- `Control.Overlays` has been removed. You can use `Layer="Overlay"` on a panel instead now (from which most controls are derived). A few controls, like `ScrollView` no longer have multiple children, and thus must be placed inside a `Panel` if you need an overlay or background.
- `Control.OnHitTestControlChildren` has been removed, just use `OnHitTestChildren`

## BottomBarBackground and StatusBarBackground renamed

BottomBarBackground and StatusBarBackground are now remove in favour of the more consistantly named BottomFrameBackground and TopFrameBackground. These have been available in uno for a while so if you are already using them then you dont have to worry.

API for both are exactly the same as before.

DOCUMENTATIOΝ PULL REQUEST: https://github.com/fusetools/docs/pull/47

## ScrollViewer renamed to ScrollView

- The ScrollViewer has been renamed to ScrollView.

## TextControl

- The property 'IsMultiline' has been removed. If the string has newlines in it, it is multiline.

## DelayBack

- The meaning of `DelayBack` and `DurationBack` has now changed. The delay is now measured from the end of the timeline, and is the delay prior to the transiton starting. The transition still takes `DurationBack` time, but does not start until after `DelayBack` time. This attempts to create a more understandable definition of the `...Back` properties.

- `ProgressAnimator` has been removed. The `TrackAnimator` should be used instead.

## Handle renamed to Name

### Docs update : https://github.com/fusetools/docs/pull/46

- The `Node.Handle` and `State.Handle` properties are renamed to `Node.Name` and `State.Name` respectively
- `ux:Name` now sets the `Name` automatically on `Node` and `State`, and vice versa. (the `ux:` prefix is therefore no longer strictly required for `Name` on `Node` and `State`)
- Script events that used to provide a `handle` property now provide a `name` property instead

Previously:

	<Page Handle="foo" />

Now:

	<Page ux:Name="foo" />

Or alternatively:

	<Page Name="foo" />


## Misc

## HitTest

- If you override a `HitTest...` function you must override the matching `HitTest...Bounds` function and produce an appropriate bounds, otherwise hit test clipping will prevent the node from getting events.
- `IViewport.PixelToWorldRay` is replaced with `IViewport.PointToWorldRay` since point space is more common. Divide by `PointDensity` to calculate in pixel space (not valid in all situations).
- Hit test clipping is now based on `HitTestBounds` and not the `RenderBounds` of controls. If you have a custom control that doesn't seem to get messages add a custom `HitTestLocalBounds` definition. Standard controls should all respond correctly.

##

- `Number.Format` now takes a shorter format string, for example: `F2` instead of `{0:F2}`
- `Effect.ExtendsRenderBounds` and `Effect.RenderBounds` removed and replace with `ModifyRenderBounds` to allow chaining and effects to clip the bounds (as Mask does)
- `RenderNode` now invalidates when children are added or removed and propagates layout to the children

## FuseJS
- Added Observable.refreshAll + documentation at https://github.com/fusetools/docs/pull/45
- Added NativEvent to be able to call events from Uno.
- Storage: Added deleteSync, writeSync and readSync.
- Fetch and FetchJson is deprecated, use the browser based fetch (lowercase f) API instead.
- Added optional parameter to NativeEvent to decide if events should be queued before the handler is set
- Added localStorage web api shim
- Added setInterval
- Added FuseJS/GeoLocation
- Added a FuseJS/HttpClient, this fixes a lot of bugs in XMLHttpRequest and fetch.
- Added FuseJS/Environment that got platform conditionals 

## PullToReload

- `PullToReload` trigger added to support common behaviour of pulling down on a scroller to reload the contents
- `ColumnLayout` added as a new layout type
- The `ScrollViewer` has had some adjustments in how it responds to resizing. The result should be smoother now than before.
- `ScrollViewer.SnapMinTransform` can now be set to false to disable any visual handling of the snap region at the top/left.

## Text properties

- The `FontSize`, `TextAlignment`, `TextColor`, and `Font` properties are no longer inherited properties and must be set specifically on the new `TextControl` or derived types (specifically `TextInput` or `Text`). If you used such a property on a non-TextControl before and need it to cascade to the children set it in a `Style` on that node instead.

Previously:
	<Panel FontSize="16">
		<Text/>

Could become:
	<Panel>
		<Text FontSize="16"/>

Or to affect all Text children:
	<Panel>
		<Style>
			<Text FontSize="16"/>
		</Style>



- `Text` and `TextEdit` derive from common `TextControl`. Shared properties moved into base class. `TextElement` and `TextEdit` must be embedded in one of these controls now (to acquire the new `ITextPropertyProvider` for rendering details)

# Layout in Node class

- `Panel` accepts `Node` as children, not just `Element`
- Some properties/functions moved from `Element` into `Node`: LayoutRole, ArrangeMarginBox, GetMarginSize, InvalidateLayout, IsMarginBoxDependent, BringIntoView
- `ArrangeMarginBox` requires a third parameter, the default was `SizeFlags.Both` before
- Some types moved from `Fuse.Elements` into `Fuse`: SizeFlags, LayoutRole, InvalidateLayoutReason, LayoutDependent
- `Element.ParentElement` has been removed as the parent may not be an element (case `Parent` to `Element` if you really need this, be aware of null)
- `Element.ElementRoot` has been removed as it is no longer clear what it means, and should not be used
- `BringIntoViewArgs.Element` replaced with `Node`
- `InvalidateVisualReason` removed as it wasn't provided consistently and wasn't used
- `Element.RenderNode` split into `RenderNodeWithEffects/WithoutEffects`. `RenderBounds` becomes a property on Node, as does `HitTestBounds`.
- `Element.Bounds` has been removed as it implied a feature that wasn't there. Use `new Rect(float2(0),ActualSize)` if you should actually need the local logical bounds of the control.

## ParentNode refactoring
- `Node.ParentNode` renamed to `Node.Parent`
- `INodeParent`, `IResourceParent` and `IWindow` removed. Accept a `Node` instead.
- `App` now suports behaviors (e.g. `<JavaScript>`) directly (added to hidden root node)

## -- previous release

- Added `BringIntoView` trigger action to match the `Element.BringIntoView` function
- PageBinding adds options `Default` and `AllowNull` to specifiy what happens if no resource is found

## TransformOrigin

- `TransformOrigin` enum removed, replaced with singletons in `TransformOrigins` implementing `ITransformOrigin`.
- New modes `HorizontalBoxCenter` and `VerticalBoxCenter` for 3D transforms
- `Rotation` now supports XYZ values, these are treated as Euler angles (see Quaternion.FromEulerAngles). Shortcuts to `DegreesX` `DegreesY` and `DegreesZ` are now provided. The previous `Degrees` remains and is equivalent to `DegreesZ`
- `Rotation.Vector` renamed `EulerAngle` to better reflect what it is and avoid confusion with rotation around a vector


## Cameras

- `IWindow` now derives from `IViewport`, most fields move to base
- `Frustum.PixelToWorldRay` has been removed. You must now use the `IViewport` interface `Node.Viewport` to get the world ray
- `DefaultShading.Camera` is replaced with `Viewport` and it expects a viewport (defaults to DrawContext.Viewport)
- `Perspective` removed from `IViewport` as it doesn't belong there. Wrap your app in a `Vieport` and define the `Perspective` property
- `ICamera` is now `IFrustum` as it better defines the purpose of those classes
- `OrthographicCamera` renamed `OrthographicFrustum`

## Visibility

- `Node.IsVisible` changes meaning: true if the node and all of its parents are visible (this is now a non-virtual function)
- `Node.IsLocalVisible` introduced to mean if the local node is marked as visible (this is a virtual function)
- `Node.IsVisibleChanged` event raised whenever `IsVisible` may have changed


## Layout Changes

- `InvaildateLayout` now takes a `InvalidateLayoutReason` parameter, but a suitable default has been provided
- `Element.IsLayoutInvalid` has been removed as it cannot provide meaningful information.
- `Element.OnResized` has been removed, subscribe to the `Placed` event instead
- `Element.OnPlaced` has been removed, subscribe to the `Placed` event instead
- `PlacedArgs` fields simplified. Use the `ActualXXX` element properties for current data.
- `ResizedArgs` removed, only `PlacedArgs` is used now
- `IActualSize` replaced with `IActualPlacement`
- `PlacedArgs` and `PlacedHandler` now in the `Fuse` namespace
- `INavigaionPanel.Placed` changed signature to match standard `Element.Placed(object sender, PlacedArgs args)`
- `INavigationPanel.ChildAdded/Removed` changed to `EventHandle<Node>`, with signature `(obejct sender, Node child)`

## Navigation naming

- Renamed `IPageProgress` to `INavigation`
- `INavigationContext` merged into `INavigation`
- `IPageProgress.Count` renamed `PageCount`, and `PageCountChanged` event
- `IPageProgress.Current` renamed `PageProgress` and `PageProgressChanged` event
- `PageIndicator.PageProgress` is now `Navigation`
- `StructuredNavigation.ProgressChanged` event removed, use `PageProgressChanged`
- `NavigationContext` property renamed `Navigation.Navigation`
- `{Page key}` binding will use the closer of `Navigation.Page` or the current page of `Navigation.Navigation`
- `CurrentPageBinding` behavior removed, use `Navigation.Page` or `Naviation.Navigation` property on element instead


##

Removing some items from the public API (weren't meant to be public)
- DiscreteSingleTrack
- DiscreteKeyframeTrack
- SplineTrack
- EasingTrack
- IMixerMaster
- Mixer

Rename `ProgressRange` to `ProgressAnimation` to be consistent.


## Shadow layout

- the `Element.IsLayoutInert` boolean has been replaced with a `LayoutRole` enum. Use `LayoutRole.Inert` to replicate the old `IsLayoutInert` true setting
- remove unused internal `Element.LayoutHappened`

## Attractor

- `CreatePixelFlat` factories renamed `CreatePoints`
- `CreateAngular` factories renamed `CreateRadians`
- `Attractor.SimulationType` allows specifying which simulation type to use
- `Attractor.MaxSpeed` is no longer available since not all simulation types support it
- `SmoothSnap.CreatePoints` parameters have been tweaked to be a bit slower (this affects EdgeNavigation)
- `Attractor.TimeMultiplier` can be used to increase or decrease the speed of the animation

## Navigation Changes

- `ITitleNode`, `TitleChanged`, and related title events have been removed. Instead the resource system should be used with a `CurrentPageBinding`:

```
<Panel>
	<CurrentPageBinding PageProgress="MyNavigation"/>

	<Text Value="{Page Title}"/>
</Panel>
```

- `IPage` has been removed as nothing used it or called its functions
- `NavigationContext` can now be set on any node and establishes the context for that tree
- `Navigation.TryFind` now returns an `INavigationContext`, not a `Navigation`
- `CanGoBack` trigger renamed `WhileCanGoBack`
- `Fuse.Controls.IPageProgress` moved to `Fuse.Navigation.IPageProgress`
- If the same element is added again to `HierarchicalNavigation` it will simply transition to that element now instead of pushing it on the top. This seems to better match the expected use of app navigation. To get the old behaviour set `ReuseExistingNode="false"` on the navigation.

- `TriggerAction.Perform` was made protected, it should not be called directly. Use the `PerformFromNode` function.
- A generic `TriggerAction.TargetNode` is available for all triggers now.

##

- `WhileBool` (WhileTrue/WhileFalse) now search their ancestors for a value node on rooting. If avilable they use that as the value instead of an explicit `Value`. Set `Value` to `true` or `false` explicitly to force a local value.
- The `While` is gone, use `WhileTrue` instead. Use the `Value` property instead of `On` to set it on/off.
- `Accordion1D` has been removed as it is not used (replaced by other physics simulations)
- Several changes were made to the internals of how sizing/positioning are handing in layout. This fixes some high-level defects with redrawing and layout. Other than those defects no other layout change is intended.
- Pointer gestures, like Tapped, Clicked, WhilePressed, etc. will only operate on the first pointer within an element (the first finger/button that clicks). Additional actions by other fingers/buttons will not trigger the gesture. This is a future-proofing step to ensure more complex gestures can be supported later, and also because this is typically what is intended.
- `WhilePressed` now deactivates when then pointer does not hit the underlying element, previously it would be activate so long as the mouse remeains pressed.
- `ScrollViewer.UserScroll` added which enables/disables user pointer control. This allows a ScrollViewer with only programmatic control. This is a shortcut to adding the `SuppressUserScroll` flag to Behaviors.

## PageBinding

- `Node.GetResource` replaced with `Node.TryGetResource` which returns a bool and takes an `out` object as the last parameter. This change is necessary since resources can legitmately be set to a null value.

## Triggers

- `CubicOut` had an error that returned a constant value, this has been fixed
- `Trigger.Start` and `Trigger.Stop` are no longer virtual (was not intended, could not work)


## Value

We've made several changes to unify the binding of values in controls. A variety of properties are now called `Value` and you need to change your code.

- `Switch.Toggled` => `Switch.Value`
- `WhileToggled` => `WhileTrue`,
- `WhileNotToggled` => `WhileFalse`
- `Text.Content` => `TextContent.Value`. Several related classes/methods also have `Content` => `Value` changed. You probably don't use them directly but will have to change the references if you do.
- `TextInput.Text` => `TextInput.Value`.  Several related classes/methods also have `Text` => `Value` changed. You probably don't use them directly but will have to change the references if you do.

Other changes:

- `IToggle` changed to `IValue<bool>` interface, `Toggled` is gone, use `Value`
- `IToggle.Condition` removed, used `Value`
- `RangeControl` / `Slider` now use a double value instead of a float, and implement `IValue<double>`
- `WhileSliding` added as trigger tied to `Slider`
- several more properties made stylable
- `WhileEdgeSwiped` renamed `EdgeSwipeAnimation` to follow the trigger naming conventions.

Also several internals have changed, but they shouldn't need any changes in high-level code.


## MemoryPolicy

- `Image.FilePreload` removed, use a `MemoryPolicy` instead. The default policy preload bundle files. To allow an image to be disposed use `MemoryPolicy="UnloadUnused"` on the `Image` or `ImageSource`.

## Disposables

- `IAutoDisposable` renamed `ISoftDisposable`
- All soft disposables are now disposed when the app goes into the background (all ImageSources)

## TextureFill changes

- Introducing `ImageFill` to replace `TextureFill`. Shares sizing modes with `Image`
- Remove `TextureFill`
- A change of alignment/stretching in texture filling -- the new modes in `ImageFill` are now correct
- `RendererContext.ElementSize` renamed `CanvasSize` to match Brush
- Brushes expect a `CanvasSize` to be drawn correctly
- `Texture` has been removed from `Fuse.Effects.Mask` use an `ImageSource` or the `File` property as a shortcut.

* Change in how Style works (https://github.com/fusetools/changeblog/wiki/Change-in-how-%60Style%60-works)
