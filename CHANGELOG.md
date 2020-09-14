# Unreleased

### Fuse.physics
- Refactor `Draggable` using IGesture System.
- Introduce `Translation` property to `Draggable` to track translation position when user drag a visual with `Dragabble` behavior attached
- Introduce two new Triggers:
  - `DragStarted` Pulse when dragging activity has been started
  - `DragEnded` Pulse when dragging activity has been ended
- Drag and Drop API. Experimental support for drag and drop between visual element. Introduce sets of Triggers:
  - `WhileDraggingOver` Activated when Visual that contain `Draggable` behavior and `WhileDraggingOver` trigger is overlaped / intersected with the `Target` Visual property that is defined in `WhileDraggingOver`
  - `WhileDroppingBy` Activated when Visual that contain `WhileDroppingBy` trigger being overlaped / intersected by `Source` Draggable Visual
  - `Dropped` Pulse when Draggable Visual is being dropped to the target visual and vice versa.

### Fuse.Controls.Primitives
- `TextControl` accessibility feature. Introduce `MinFontScale` and `MaxFontScale` Property to control the minimum or maximum text scaling behavior when the text/font size configuration setting on the phone has changed. Now default Fuse will honor the phone's text/font size configuration setting and will change all of the texts or labels in the Fuse App to match the setting. If you don't want the behavior you can pass a compiler flag:`IGNORE_FONT_SCALING` when building the app i.e: `uno build ios -DIGNORE_FONT_SCALING`

### Fuse.Auth
- Introducing Fuse.Auth, the easiest way to perform user authentication using biometric sensor that reside on the device such as fingerprint or FaceID
- Introducing Platform SignIn. a Sign In mechanism that use `Sign In With Apple` on iOS and `Google SignIn` on Android. There is two API added, `PlatformSignIn` as trigger action and `FuseJS/Auth` as javascript module.

### MapView
- Adds a map overlay to a MapView using `MapOverlay` Node. There are 3 types of overlay that are supported : Polyline, Polygon and Circle

### Fuse.Triggers
- Added trigger action `SetWindowOrientation` for setting device orientation
- Added trigger action `SetStatusBarUI` for setting look and feel of statusbar

### StatusBar
- `Android.StatusBarConfig` Added property to change status bar style: Dark or Light.

# 1.14

## 1.14.0

### Experimental.TextureLoader
- Marked all members as obsolete. Please use `TextureLoader` in `Uno.Graphics.Utils` instead (#1327).

### Fuse.Android
- Switched to AndroidX libraries (#1323).

### Fuse.iOS
- Auto Resizing Mask Fix (#1316).
- Fixed compile-time warnings (#1335).

### Fuse.Charting
- Fix crash caused by accessing disposed object (#1322).
- Added the following properties (#1317).
    - `PlotPoint.RadialOffset`
    - `PlotPoint.RadialScale`
    - `PlotWedge.RadialOffset`
    - `PlotWedge.RadialScale`

### FuseJS/GeoLocation
- Added `authorizationStatus` (#1319).

### Fuse.Gestures
- Added `HoldPress` trigger (#1320).

### FuseJS/InterApp
- Added `launchApp(uri)` (#1324, #1325).

### Fuse.PushNotifications
- Updated `IsRegistered` and updated dependencies (#1318).

### Fuse.Triggers
- Print run-time warning instead of throwing exception (#1321).

### Fuse.Vibration
- On iOS you can do feedback vibration by leveraging Taptic Engine (#1338). There are 9 types of vibration:
  * Soft
  * Rigid
  * Light
  * Medium
  * Heavy
  * Success
  * Warning
  * Error
  * Selection

### Expressions
- Added more string functions (#1337):
  - `trim` function
  - `indexOf` function
  - `substring` function
  - `replace` function
  - `insert` function
  - `split` function
  - `startsWith` function
  - `endsWith` function

[`v1.13.0...v1.14.0`](https://github.com/fuse-open/fuselibs/compare/v1.13.0...v1.14.0).

# 1.13

## 1.13.0

### FuseJS
- FuseJS/Environment: add property to retrieve current device locale using BCP47 format (#1313).

### Fuse.Alerts
- Fixed threading issue on iOS 13 (#1299).

### Fuse.Camera
- Fixed threading issue on iOS 13 (#1294).

### Fuse.CameraRoll
- Fixed threading issue on iOS 13 (#1293).

### Fuse.Common
- Fixed system fonts on iOS 13 (#1291).
- Added the following methods to public API (#1310).
    - `Fuse.Json.Parse(string)`
    - `Fuse.Json.Parse(string[])`

### Fuse.Controls.Native
- Added support for Dark Mode on Android (#1290).
- Added support for Dark Mode on iOS (#1309).
- Added new scriptmodule `FuseJS/DarkMode` (#1290).

### Fuse.Controls.Navigation
- Added Page Navigation swipe from edges (#1279).

### Fuse.Drawing.Surface
- Fixed SVGPathParser to better parse minimized svg data (#1302).

### Fuse.GeoLocation
- Fixed dependencies/permissions on Android (#1245).
- Added new scriptmethod `isLocationEnabled` (#1245).

### Fuse.ImageTools
- Fixed crop function not using height parameter (#1300).

### Fuse.Launcher.InterApp
- Added docs for Universal and App Links support (#1282).

### Fuse.Maps
- Updated dependencies on Android (#1284).

### Fuse.Models
- Upgraded zone.js to v0.9.1 (#1296).
- Allow unsetting/overriding Model (#1306).

### Fuse.PushNotifications
- Fixes and updates for Android and iOS (#1220, #1314).
- Added scriptmethod `isRegisteredForRemoteNotifications` (#1220).
- Fixed threading issue on iOS 13 (#1292).

### Fuse.Reactive.Expressions
- Fixed run-time warnings (#1312).

### Fuse.Scripting.JavaScript
- Upgraded V8 to v7.6.303.30 on Android (#1297).

### Fuse.Storage
- Add `UserSettings` module. This module provides key-value pairs mechanism to store and retrieve primitive data types (string, number, boolean) as well as an array and a JSON object (#1310).

### Fuse.Triggers
- Added `Value` property on `TransitionState` (#1286).

### Fuse.iOS
- Fixes threading issue on iOS 13 (#1308).

[`v1.12.0...v1.13.0`](https://github.com/fuse-open/fuselibs/compare/v1.12.0...v1.13.0).

# 1.12

## 1.12.0

### Fuse.Controls.Native
- Fixed readonly `TextInput`.

### Fuse.Elements
- Added `DiskCache` property on `HttpImageSource`.

### Fuse.Scripting.JavaScript
- Fixed building with `-DUSE_JAVASCRIPTCORE` on Android.

### Fuse.Sensor
- Added a new script module - FuseJS/Sensor.

### Fuse.Share
- Updated to new android file permission requirements when sharing.

### FuseJS
- Added definitions file for TypeScript.
- Renamed the following methods (for TypeScript compatibility):
    * FuseJS/FileSystem: `delete` -> `remove`
    * FuseJS/FileSystem: `deleteSync` -> `removeSync`
    * FuseJS/Timer: `delete` -> `destroy`
    * FuseJS/Storage: `deleteSync` -> `removeSync`

See also [v1.11.3...v1.12.0](https://github.com/fuse-open/fuselibs/compare/v1.11.3...v1.12.0).


# 1.11

## 1.11.0

### Fuse.Camera
- Updated with new file permission requirements for newer androids.
- Catered for out of memory error.
- Post photo capture - rotation fix: If out of memory, won't crash but will downsize image to fit memory before adjusting rotation.
- Fixed android app name.

### Fuse.Scripting.JavaScript
- Upgrade V8 to 6.9.427.23 on Android.

### Other news
- Switched to NPM for distribution.


# 1.10

## 1.10.0

### Experimental.TextureLoader
- Added a set of overloads that return the texture object directly instead of passing the texture via callbacks. The old callback-based overloads are deprecated.

### Fuse.Controls.WebView
- Improves WebView to handle `mailto:`, `sms:`, and `tel:` special URLs supported by system apps on Android and iOS.

### Fuse.LocalNotifications
- Fix bug on iOS where an app is launched (not restored) from a notification and the notification isn't delivered.

### Fuse.Controls.DatePicker
- Fixed bug which caused dates not to be selectable if the control was inside a WhileTrue on iOS.

### Fuse.Deprecated.CameraView
- This obsolete package has been removed. All functionality should be present in `Fuse.Controls.CameraView` instead.

### Camera
- New feature: `checkPermissions()` - Check if your app has access to the camera.
- New feature: `requestPermissions()` - Request permission to access the camera. In iOS, if the user has previously denied access this function will redirect them to your app settings in their iPhone / iPad.

### CameraRoll
- New feature: `checkPermissions()` - Check if your app has access to the gallery.
- New feature: `requestPermissions()` - Request permission to access the gallery. In iOS, if the user has previously denied access this function will redirect them to your app settings in their iPhone / iPad.


# 1.9

## 1.9.0

### Android Layout
- Fixed an issue causing an empty (`Size` = 0) layout to be performed on Android during app startup.

### ScrollView
- Implement support for horizontal scrolling in ScrollViews inside a `NativeViewHost` on Android

### Color Expressions
- Added the functions `darken`, `lighten`, `saturate`, `desaturate`, `scaleSaturation`, `scaleLightness` and `adjustHue` for improved color  handling in UX expressions.
- Added the functions `rgbaToHsla` and `hslaToRgba` for color conversions in UX expressions.

### Diagnostics
- Improved diagnostics to provide UX source location on several kinds of errors.

### DotNet/Preview Gradients
- Gradient rendering in preview previously had some limitations in the ranges of `StartPoint` and `EndPoint` it could accept. This has been fixed: points inside and outside of the element render correctly now.

### EdgeNavigator
- Changed `NavigateToggle` to work without a `NavigationContext` and remove some potential errors.

### LayoutMaster
- Fixed a redundant layout invalidation when `Element.LayoutMaster` is changed. This would result in broken `LayoutAnimation` as multiple layouts could be triggered by a `Change`.

### Layout
- Fixed invalid layout caching when a relative container size changed. This affected `ScrollView` and `DockPanel`, in particular it may have resulted in stale sizes when the keyboard appeared, or orientation changed.

### MapView
- Fixed a crash when tapping the user's current location on iOS.
- Fixed incorrect zoom factor changes when the location changed on iOS.

### Router
- Deprecated the `GoUp` behavior which causes unexpected behavior and defects. This fixes an issue of pressing the hardware back button at the root state (on Android).  The old behavior can be had by setting `GoBackBehavior="GoBackAndUp"` on the router, but be aware it is deprecated and will be removed.
- Added `Router.BackAtRootPressed` to allow intercepting a back button action on the root page.

### Video
- Fixed issue where `Video` on Android could end up not finding the rotation metadata on its video source
- Fixed issue where `Video` on iOS could render incorrect on some rotations
- Removed size flip in `VideoVisual`, looks like this used to work due to bug dependency. But the native video players flip the size themselves.
- Add `VideoOrientationPage` to ManualTestApp, this page tests video with mp4 files with different rotations in their metadata section.
- Use proper transforms for rotation in the video rendering code

## WrapPanel / WrapLayout
- Fixed `WrapPanel` to update its layout when a layout property changes.

## Fuse.Views
- Fixed a crash when pushing the back-button on Android.
- Support for `Fragment` on Android


# 1.8

## 1.8.0

## Android
- Fixed a defect that performed layout with a 0 density on Android at startup

### Path
- Fixed bug where setting `Data` on a `Path` could end up not rendering inside a `NativeViewHost` on iOS

### Vector Drawing
- Fixed a defect in partial line drawing in Preview that resulted in a spurious line being drawn. This happened when the partial curve overlapped the end of the path data.
- Fixed a defect that prevented a single-segment, horizontal or vertical, line from rendering in `Path` with `StretchMode="Uniform"` (the default `StretchMode`).
- Fixed a defect that prevented a `Path` with a single horizontal or vertical line from rendering in Preview (DotNet).
- Fixed the width of strokes in Preview (DotNet). They were too small on devices with a density other than `1`.
- Fixed a Preview/DotNet rendering defect that resulted from unclosed paths in `Path.Data`.

### Grid
- Fixed a `Grid` defect that resulted in some cells not calculating the correct layout size.
- `Grid` now detects a common invalid configuration and emits an error. This may trigger on projects that currently work, but are relying on undefined/broken behavior.

### Instance / Each
- Added `IsEnabled` to allow conditional instantion of templates in `Instance`
- Added `Match` to pick a specific template
- Added `Defaults` to limit default instances, useful when using bindings to match criteria

### EdgeNavigator
- Improved the JavaScript model and object support on `EdgeNavigator`.
	- `EdgeNavigator.Pages` functions like `PageControl.Pages`, binding model data to templated pages.
	- Set `IsRouterOutlet="true"`  to enable `Router` functionality.

### Internal APIs
- The following `protected internal` members have been made just `internal`, as they refer to `internal` types and weren't meant to be available to derived types:
    * `Fuse.Controls.TextInputControl.Editor`
    * `Fuse.Controls.TextInputControl.TextInputControl(TextEdit)`
    * `Fuse.Physics.ForceFieldTrigger.SetForce(Body, float)`
    * `Fuse.Physics.ForceFieldEventTrigger.OnTriggered(Body)`
    * `Fuse.Controls.TextControl._textRenderer`

### SafeEdgePanel
- Added `SafeEdgePanel` to assist in creating iPhone X capable layouts.

### Grid
- Fixed a defect in the default metric mode of `Grid` that could result in incorrect layout calculations, in particular if putting a `Grid` inside a `StackPanel` with `auto` columns.

### Selection
- Added `isSelected` function for determine selection status within an expression

### Stroke
- Fixed Android strokes to use the correct cap and join instead of always being Butt and Bevel.

### Element
- Added `Size` and `Height` to `Element` as an alternate way to control the layout. This is useful for some animation and binding situations.

### Cycle
- Added `Restore` option `Forward` to allow animating forward to return to rest state

### Device and window()
- Marked several types internal that should not have been public: `SystemUI` and related types
- Changed `ClientPanel` to use `Padding` instead of panels.
- Added `window()` function to get device UI borders: `safeMargins`, `staticMargins` and experimental `deviceMargins`. This will allow developing for devices with extended border areas such as the iPhone X
- Added `Device` global to query platform details, such as `Device.isIOS` and `Device.isAndroid`
- Removed the `RelativeToKeyboardMode` relative translation. This was undocumented and did not appear to work correctly, or do something useful. To move relative to device controls you can now use `window().safeMargins` and `window().staticMargins`

### Keyframe
- Fixed `Keyframe` to allow expressions on the property values.

### SwipeGesture
- A `Simple` or `Auto` `SwipeGesture` will no longer automatically activate at the halfway point, whereas a `Active` gesture will.  To get the old default behavior, which is considered a defect, use `Threshold="0.5"`.
- Added a `SwipeGesture.Threshold` to configure the automatic activation distnace.

### Image loading errors
- Added more info to the messages reported on failure during image loading.

### Fuse.Scripting
- Marked `NativeMember.Context` as Obsolete. Either use passed-down `Context`, or dispatch to `ThreadWorker` instead.

### FuseJS
- Added support for passing arguments from UX to the model constructor using the `ModelArgs` attribute.


# 1.7

## 1.7.4

### Restored missing bug-fixes
- There were a few bug-fixes from 1.6 that somehow missed 1.7. Those have now been restored. In particular:
  * Added back removed API `Context.Invoke(Action ...)`.
  * Fixed a NullReferenceException in `NativeEvent.RaiseAsync(params object[])`.

## 1.7.3

### Router
- Fixed a crash in `Router.GoUp` that could be seen when pressing the back button at the root page of navigation.

## 1.7.1

### Fuse.Nodes
- Fixed a bug where triggering `onParameterChanged` on an element would lead to a crash.

## 1.7.0

### PageControl
- Fixed a crash resulting from adding dynamic pages and binding by name

### Partial Curves
- Added support for drawing partial curves to `Path` and `Curve`. Refer to the `PathStart`, `PathLength` and `PathEnd` properties.
- Added the path expressions `pathPointAtDistance` and `pathTangentAngleAtDistance` for locating an offset along a `Path` or `Curve` and the heading.

### Router
- Fixed `goBack` to properly modify the route with two duplicate routes in the history## JavaScript
- Several functions in `ScriptModule` and related classes have been marked `internal`. These were never meant to be part of the public API.
- Added `JavaScript.Names` with option `Require` to prevent injecting names into the JavaScript code namespace

### TextColor Opacity
- Fixed a failure to render translucent `TextColor` correctly
- Fixed the rendering of opaque emoji when `TextColor` is translucent (they will not also be translucent, though still  use the font coloring)

### Node Data Context
- Removed some deprecated methods and classes from `Node`: `IDataListener`, `OnDataChanged`. These were not meant to be public.
- Deprecated `{}` in favour of the new `data()` function. `{}` had unusual binding rules and would often not bind to the intended context. `data()` always binds to the prime data context, it's unambiguous and predictable.
- Fixed the object provided to JavaScript callbacks in `args.data`. It will now always be the prime data context, not just the next contextual data.
- Deprecated and removed several functions which were not meant to be public. The deprecated ones will be removed shortly, as the current interface cannot be supported in the future.   `ISiblingDataProvider`, `ISubtreeDataProvider`, `IDataEnumerator`, `Node.GetFirstData`, `Node.EnumerateData`, `Node.BroadcastDataChange`, `Node.IDataListenere`, `Node.OnDataChanged`, `Node.AddDataListener`, `Node.RemoveDataListener`, `IObject`, `IArray`

### LinearGradient
- Fixes invalid gradients in desktop preview (DotNet targets)

### Navigator
- Fixed the invalid reuse of an existing page if the context does not match

### Expressions
- Added support for boolean `==` and `!=` expressions, which can be used for things like negating boolean expressions.
- Added support for the logical not operator. This means you can do "!someBoolean" to logically negate it.
- Fixed negation operator (`-`, eg. `-someValue`).
- Added vector accessors `x(v)`, `y(v)`, `z(v)`, `w(v)` to access the component values of float/2/3/4 values. (Note: `x` and `y` have an overloaded meaning now, also providing Element position).
- Added `atanVector` to compute arc-tangent from a `float2` input

## FuseJS
- Fixed bug where arrays inside arrays would produce unexpected behavior
- Fixed bug where a cycle in the object graph would result in infinite recursion in some cases
- Fixed bug where changing the value of a property from an object to a primitive value would cause odd behavior in some cases.

### ScrollView
- Fixed bug where ScrollView's inside a NativeViewHost would scroll to fast
- Fixed bug where the scrolling indicator in a native ScrollView would not show on iOS
- Added `ContentSize` property on the `Fuse.Controls.Native.IScrollViewHost` interface. Needed by iOS to layout the native scrollview correctly

### Control
- Setting the `Background` property to something else than SolidColor or StaticSolidColor has been deprecated, and gives a warning. Support for this will be removed in an upcoming release.

### Video
- Setting the `StretchMode` property to `Scale9` on VideoVisual has been depecated, and gives a warning. Support for this will be removed in an upcoming release.
- Removed `protected` constructor for `LayoutFunction`, this was not meant to be public. Sealed the derived classes, they were not meant to be extendable.


# 1.6

## 1.6.1

### Fuse.Scripting
- Restore accidentally broken NativeEvent.RaiseAsync() API.
- Rolled back NativeProperty constructor API to the pre-1.6 state. Code updated to 1.6 needs to be rolled back as well.
- Previous changes resulted in a breaking change we would rather avoid so we reintroduce `Invoke(Action ..)` so we can take it through the usual deprecation cycle.

## 1.6.0

### Image
- Fixed issue where `<Image />` inside a `<NativeViewHost />` on android could display incorrectly

### ScrollView
- Fixed bug where ScrollView's inside a NativeViewHost would scroll to fast
- Fixed bug where the scrolling indicator in a native ScrollView would not show on iOS
- Added `ContentSize` property on the `Fuse.Controls.Native.IScrollViewHost` interface. Needed by iOS to layout the native scrollview correctly

### Let
- Introduced an experimental `Let` feature that allows creating expression aliases and local variables in UX
- Added specific type version of `Let`, such as `LetFloat` and `LetString`. This improve the ability to connect pieces of the UX together and do animation/transitions in UX without using JavaScript.

### Instantiator
- Improved the internals of `Instantiator` (the base for `Each` and `Instance`). This also fixed a few corner cases with templates not updating, but should otherwise not affect user code.
- Fixed the creation of templates in `Each` / `Instance` when the data context is null/non-extant. It will now not instantiate the templates are all. This prevents some kinds of binding defects and improves efficiency with default templates.

### Element
- Fixed an incorrect cascade of `MinWidth` / `MinHeight`. This could only be noticed in certain scenarios using `BoxSizing="FillAspect"`.
- Fixed the `width`, `height`, `x`, and `y` functions to support an element losing its layout. They become undefined in this case, thus allowing a syntax like `width(element) ?? 50`

### StackPanel
- Fixed the invalid propagation of MaxWidth/MaxHeight in a StackPanel to its children

### Data Context
- Resolved a situation with nested context binding `{}`, such as `With` and `Instance`, where the data would not correctly update

### Selection
- Fixed the ordering of events so that `SelectionChanged` is emitted after the bound value is updated

### Expressions
- Deprecated `UnaryOperator.OnNewOperand` and `OnLostOperand`.  These are part of a broken pattern of using unary expressions (and were not present on Binary/Ternary/QuaternaryOperator). You generally shouldn't need this, and should implement `Compute` instead. In the rare cases you need the virtuals you'll need to extend Expression and implement `Subscribe`, using `ExpressionListener` as a way to capture the correct functionality.
- Moved `VarArgFunction.Argument` to `Expression.Argument`. It's in a base class so still has visibility in `VarArgFunction`.
- `VarArgFunction.Subscription.OnNewData` and `OnLostData` have been sealed. They should not have been open for overriding before as it conflicts with the inner workings on the class. Only the `OnNewPartialArguments` and `OnNewArguments` should be overridden.
- Improved error handling on several operators and math functions. Instead of exceptions these should produce the standard conversion/computation warnings for invalid types.
- Added `size()` function to force conversion to a `Size` or `Size2` type. Useful when dealing with unknown types and some operators that would otherwise result in the undesired conversion.

### Navigation
- Fixed an issue with `Navigator.Pages` not registering pages correctly in certain initialization orders
- Added `$navigationRequest` to `Navigation.Pages` objects. This can be used to fine-tune the navigation.

### Instance
- Added `Instance.Item` to work similar to an `Each` with a single data item

### Expression Functions
- Added `nonNull` for special evaluation handling for temporary null values. This may be useful in migrating code that is now producing many incompatible argument warnings.
- Changed operators / functions to report warnings if they are provided with invalid arguments. This should help locate errors in code that were previously silent and just didn't evaluate, or evaluated wrong.  Consider using the `??` operator, and the `isNull`, `isDefined` and `nonNull` functions to deal with non-data scenarios.
- Removed `protected` from `BinaryOperator.OnNewOperands`. This was intended to be `internal` as there is no correct way to overload it. If you happened to use it we can provide a different base-class to use for you.

### Fuse.Preview Selection
- Removed the following APIs, that were never meant to be exposed to user-code:
  * `Fuse.Visual.DrawLocalSelection(DrawContext, Rect)`
  * `Fuse.Visual.DrawSelection(DrawContext)`
  * `Fuse.AppBase.InvalidateSelection()`
  * `Fuse.App.DrawSelection(DrawContext)`
  * `Fuse.Preview.SelectionManager`
  * `Fuse.Preview.ISelection`

### Conversions
- Added `float()` expression to force conversion to float values
- Added `string()` expression to force conversion to string values

### Timer
- Fixed issue where creating a repeating `Timer` with 0 delay in JavaScript would not prevent the worker thread to become idle.

### RangeControl
- `RangeControl.Value` and `RangeControl2D.Value` are not longer clamped to the `Range` of the control. This fixes issues where the `Value` was incorrectly modified when the range and value were both data bound. The user behaviors `LinearRangeBehavior` and `CircularRangeBehavior` will both however clamp to the range -- the user cannot select outside the range.

### Observables and bindings
- Fixed an issue where missing data was propagated as null. This will affect Observable's that contain zero data, and may have resulted in some bindings showing old/incorrect data.

### Multi-density image sources
- Fixed an issue where the desired size of a multi-density source ended up as the pixel size of the selected image source. The effect was that images rendered on a high-density screen, would appear larger than on a low density screen.

### Timeline
- Fixed an issue where `PlayMode="Wrap"` would not loop if the duration was less than 1 second

### Expressions
- Added `isDefined` to check if a value is known in the context
- Added `isNull` to check if a value is null or doesn't exist

### Router
- Added object support to `Router` script functions, such as `goto`, `push`, `bookmark`, etc. This mirrors the upcoming Model ability to use objects as path elements.
- Added object support to `Modify/Push/GotoRoute` actions.
- Added `NavigationControl.modifyPath` to the JavaScript interface. This allows extended local path manipulation without using a router.

### TextView
- Fixed iOS issue where the return key would display "next" instead of "return".

### Navigation
- `Navigator` blocks input to pages while transitioning to new pages. To get the old behaviour, where input is not blocked, set `<Navigator BlockInput="Never">`.

### Fuse.Reactive
- Added `OnLostData` to the `IListener` interface. This is needed to properly deal with changes in context in
 Preview, Model, and some JavaScript situations.
- Added `OnLostData` to the `InnerListener` class. Implementations should deal with this scenario.
- Changed null coalesce `??` to use the default when the left operand doesn't exist, not just when it's null

### Fuse.Marshal
- `ToDouble` replaced with `TryToDouble` for naming consistency (old names remain as deprecated)

### Fuse.Panel
- Fixed a bug where `IsFrozen` would ignore `Panel.Opacity`.

### Fuse.Controls.DatePicker/Fuse.Controls.TimePicker
- Fixed an Uno reflection bug that caused these pickers to crash in preview.

### Scripting
- `Fuse.Scripting`'s `Function` type has a `Call` method, this now takes a `Scripting.Context`. This guarantees that it can only occur on the VM thread.
- `Fuse.Scripting`'s `Object` type has a `CallMethod` method, this now takes a `Scripting.Context`. This guarantees that it can only occur on the VM thread.
- IMirror is no longer implemented by ThreadWorker. This functionality has been moved to the context
- Moved `ArrayMirror`, `ClassInstance`, `ModuleInstance`, `ObjectMirror`, `Observable`, `ObservableProperty`, `RootableScriptModule` & `ThreadWorker` to the `Fuse.Scripting.JavaScript` namespace
- Removed the `CanEvaluate` method and instead rely on the passing of the `Scripting.Context` to know if we are on the VM thread or not.
- The 'wrapping' functionality has been moved from the `ThreadWorker` to a standalone static class called `TypeWrapper`. The `IThreadWorker` no longer provides `Wrap` & `UnWrap`
- `ThreadWorker.ScriptClass` functionality moved to context. We will likely want to factor this out to a helper class however for now the major benefit is that `ThreadWorker` no longer owns these features.
- Remove the public `Context` property from the `ThreadWorker`. Sadly the context is still available via the internal field so that the tests can work. This will need to be fixed.
- `Fuse.Reactive` now depends on `Fuse.Scripting` so that it can talk about the `Scripting.Context` in it's provided interfaces.
- `DateTimeConverterHelpers` moved to its own uno file.
- `IMirror`'s `Reflect` now takes a `Scripting.Context`
- IThreadWorker no longer implement IDispatcher
- `Fuse.Scripting.JavaScript`'s `ThreadWorker` no longer blocks on construction
- Implemented `console.error`, `console.warn` and `console.info`
- Improved formatting for the above functions, as well as for `console.log`
- The `ScriptMethod<T>` constructor now throws if it's passed `ExecutionThread.MainThread` with Func, instead of failing to run it later on.
- The `ScriptMethodInline` constructor that takes an `ExecutionThread` as an argument is now obsolete. Use the one without instead. JavaScript needs to run on the JavaScript thread anyway.
- The `ScriptMethod<T>` constructor that takes `Func` and `ExecutionThread` as arguments is now obsolete. Use the one without instead.
- Calling script-methods that doesn't take any arguments should now consistently give an error. This was already the case for many functions. This is intended to ensure user-code is forward-compatible.
- `ScriptException.ErrorMessage` has been marked as obsolete, use `ScriptException.Message` instead.
- `ScriptException.Message` no longer includes all details about the script-exception, only the message itself. If you want the extra information, use `ScriptException.ToString()`, or check the specific fields.
- `Fuse.IScriptException` has been marked as obsolete. This was previously unused.
- `ScriptException.JSStackTrace` has been marked as obsolete, use `ScriptException.ScriptStackTrace` instead.
- `ScriptException.SourceLine` has been marked as obsolete, and consistently returns null now. The latter was always the case except for when using V8 before. The same information can be deduced from the project files and FileName + LineNumber fields.
- `ModuleResult.Object` has been marked as obsolete. Use `ModuleResult.GetObject(Context)` instead.
- `ModuleResult.Exports` has been marked as obsolete. Use `ModuleResult.GetExports(Context)` instead.
- `Function.Call`, `Function.Construct`, `Object.InstanceOf` and `Object.CallMethod` now takes a `Context` as their first argument. The old signatures has been marked as obsolete.


### JavaScript: JavaScriptCore on Android
- Added support for JavaScriptCore on Android. Build with `-DUSE_JAVASCRIPTCORE` to enable it on Android. JavaScriptCore is by default enabled on iOS.


# 1.4

## 1.4.1

### Expressions
- Fixed an issue where toUpper and toLower would crash on null intput. Now they propagate null instead.

### DatePicker/TimePicker
- Fixed an issue where some properties (for example `TimePicker.Is24HourView`) wouldn't work when set from UX.
- Fixed a documentation issue with `TimePicker` where the code example used the wrong name for the `Is24HourView` property.

## 1.4.0

### Notifications
- Fix regression causing iOS apps not to be accepted to the Store apparently due to use of push-notifications even though they are not used in the project.

### TextInput
- Fixed issue on android where placeholder text on a `<TextInput IsPassword="true" />` would be drawn as password dots

### Scripting.Context
- Invoke now takes an `Action<Scripting.Context>`. This is the first step in refactoring our scripting layer to make sure code does not evaluate JS on the wrong thread
- The `Observable` property has been removed from Context & IThreadWorker

### Fuse.Reactive.JavaScript
- Fuse.Reactive.JavaScript has been renamed to Fuse.Scripting.JavaScript & the separate VM packages are now subdirectories of this package

### DesktopApp Updates
- Fixed an issue about certain event not triggering a proper update and redraw on desktop preview/build

### RangeControl
- `LinearRangeBehavior` now correctly responds to `UserStep` values, providing quantized input
- Fixed `RangeControl.RelativeValue` to properly update when bound in UX
- Allowed `Minimum` to be less than `Maximum` on `RangeControl` making it easier to do left-to-right `100..0` ranges.
- Fixed a defect in position calculations in `LinearRangeBehavior`. It now uses the immediate Element parent for bounds calculation as opposed to the `RangeControl`.
- Added `UserStep` support to Android and iOS native Slider

### WebView
- Exported the methods goBack, goForward, reload and stop for use in FuseJS
- Fixed regression in 1.3 that broke WebView when using URISchemeHandler

### ScrollViewPager
- Fixed a NullReferenceError that could happen while using ScrollViewPager in preview

### DatePicker
- Introduced Fuse.Controls.DatePicker class, which wraps native date pickers on Android and iOS. See the `DatePicker` class documentation for more details.

### TimePicker
- Introduced Fuse.Controls.TimePicker class, which wraps native time pickers on Android and iOS. See the `TimePicker` class documentation for more details.

### TextView
- Fixed bug on Android where setting `TextWrapping="NoWrap"` would force the `TextView` to be single line. New behavior is to instead allow the view to scroll horizontally instead of automatically wrapping the text.

### MultiDensityImageSource
- Added native support, meaning it can be used by images inside a `NativeViewHost`.

### Video
- Fixed bug in Video where playback actions, like `Play`, used before the video was initialized would end up getting swallowed.
- Added some JavaScript methods to `Video` to make it easier to control playback from JavaScript, as well as obtaining information the video duration.
- Made `Video.Duration` and `Video.Position` property-bindable.

### Fuse.Marshal:
- Fixed a bug where UX expressions that produce two component floats did not expand to four compoent floats the same same way as literals did.

### Fuse.Reactive framework changes (Uno-level)
- These are breaking changes, but very unlikely to affect your app:
 * The `DataBinding`, `EventBinding` and `ExpressionBinding` class constructors no longer take a `NameTable` argument.
 * The `Name` and `This` expression classes has been removed. The UX compiler will now compile these as `Constant` expressions that contain the actual objects instead.
 * The `IContext` interface no longer contains the `NameTable` property.
 * The `Fuse.IRaw` interface removed (now internal to the `Fuse.Reactive.JavaScript` package). Had no practical public use.
 * The `Fuse.Reactive.ListMirror` class is no longer public. This was never intended to be public and has no practical public application.
 * Added detailed docs for many of the interfaces in the `Fuse.Reactive` namespace.
 * The `Fuse.Reactive.IWriteable` interface has changed (breaking!). The method signature is now `bool TrySetExclusive(object)` instead of `void SetExclusive(object)`. Unlikely to affect your code.
 * `IObservable` and `IObservableArray` no longer push their initial value on `Subscribe`.

### Image
- Image will now respect Exif orientation.


# 1.3

## 1.3.2

### Callback
- Fixed a regression where args.sender was no longer the `ux:Name` of the parent of the trigger.

## 1.3.1

### Navigation
- Fixed an issue where `PageControl.ActiveIndex` would not update if navigation done with JavaScript `seekToPath` or `Router` interfaces.

## 1.3.0

### Native UI:
- Fixed bug on iOS that could cause native views from thirdparty libraries to get an incorrect position. (Fixes issues with Firebase AdMob)

### JavaScript: Optional explicit require() of UX symbols
- Symbols declared with `ux:Name`, `ux:Dependency` or `dep` are now also available to `require()` for `<JavaScript>` modules using the `ux:` prefix. This allows us to write code that plays nicer with transpilers and linters. Using require for names declared in UX is optional, but may make the code more readable and maintainable, e.g. `var router = require("ux:router")` over just using `router` with no declaration.

### Fuse.Drawing.Surface
- Fixed a problem where horizontal or vertical lines would not draw in the .NET backend.

### Attract
- Fixed an issue with `attract` not updating when using a data binding as the source value

### Fonts
- Fixed bug where the default font on Android could end up being null.

### ViewHandle
- Fixed issue where Images with Mask could end up not displaying. This happend due to unnecessary invalidation of the implicit native GraphicsView in the app root. This invalidation was introduced when the Surface API was implemented for native. Invalidation is now opt-in on ViewHandle

### Fuse.Drawing.Primitives
- Fixed issue where Circles could draw incorrect due to floating point precision
- Fixed issue where Rectangles could render incorreclty due to FP16 precision limitation.

### Navigation
- Added `Navigator.Pages` to bind the local history to an observable/model
- Added `PageControl.Pages` to bind the list of available pages to an observable/model
- Fixed the semantics of `PageControl.ActiveIndex` to work with dynamic pages. The output, getter, will only be updated when the navigation is intentionally changed to a new page. Previously it would always reflect the current page, which causes problem with dynamic pages. The variation between th desired target and actual target only lasts while the desired target is not yet rooted.
- Changed how `Router` maintains history. This resolves several minor issues, including local histories (though this isn't fully exposed yet). It's intended to be backwards compatible for all known use-cases.
- Changed `IRouterOutlet` and related types to be internal. This was not meant to be public as it's a private detail of the navigation system and could not be implemented correctly by users.
- Removed the `Navigator` `IsReusable` property. These were deprecated over a year ago. Use `Resuse="Any"` instead.
- Removed `PageControl.TransitionEasing` and `Pagecontrol.TransitionDuration`. These were deprecated over a year ago. Use a `NavigationMotion` object instead with `GotoEasing` and `GotoDuration` properties.
- Removed `PageIndicator.DotTemplate` and `PageIndicator.DotFactor`. These were deprecated over a year ago. Use a `ux:Tempate="Dot"` child instead.
- Removed `Navigation.PageData`. It was always meant to be internal and has no public use.
- Allowed `GoBack` and `WhileCanGoBack` on the router to properly interact with bound observable/model `PageHistory`

### ScriptClass
- Added ScriptPromise. This adds support for passing Promises between Uno and the scripting engine. Very useful when dealing with async stuff and JavaScript
- Added ScriptReadonlyProperty. This feature lets you expose readonly data in JavaScript. Useful for exposing constants for example

### WebView
Fixed issue where custom URI schemes were matched too greedily in URLs, making for erroneously intercepted URL requests.

### Delay Push Notification Registration on iOS

On iOS you can now put the following in your unoproj file:

```
    "iOS": {
        "PushNotifications": {
            "RegisterOnLaunch": false
        }
    },
```
which will stop push notifications registering (and potentially asking for permissions) on launch. Your must then call `register()` from JS when you wish to begin using push notifications. On android this option & register are silently ignored.

### Image
- Fixed issue where an `<Image />` could fail to display inside a `<NativeViewHost />` on iOS
- Fixed an issue where a JPEG image from a misconfigured server using `image/jpg` would fail to load.

### Each
- Fixed a bug where replacing the whole list of items with an empty list would not immediately remove the items from the UI.

### Router
- Added several features to allow navigation/routing from within UX, whereas previously JavaScript code was required.
- Added `ModifyRoute`, `GotoRoute` and `PushRoute` actions to replace `RouterModify`. These all have a `Path` property.
	<Each Items="{tags}">
		<Text Value="{tag}">
			<Clicked>
				<PushRoute Path=" 'list', 'tag' : ('id': {tag})"/>
			</Clicked>
		</Text>
	</Each>
- Added `gotoRoute`, `pushRoute`, and `modifyRoute` expression events which allow for simple navigation in event handlers.
	<Button Text="View Details" Clicked="gotoRoute( 'home', 'user' : ( 'id': {userId}) )"/>

### ScrollViewPager
- Added `ScrollViewPage` which simplifies the creation of infinite scrolling lists

### Ellipse
- Added missing hit testing from `Ellipse`. If you relied on there not being any hit testing on an ellipse add `HitTestMode="None"`

### Video
- Xamarin Mac was upgraded to support 64-bit executables on macOS.

### Triggers
- Fixed an issue where certain triggers would not skip their animation/actions as part of the Bypass phase. This will not likely affect many projects, but may resolve some spurious issues where animations did not bypass under certain conditions.
- Fixed an issue where `WhileVisibleInScrollView` did not respect the Bypass phase for element layout.
  * If you required this behaviour add `Bypass="None"` to the trigger -- in exceptional cases you can add `Bypass="ExceptLayout"` to get the precise previous behaviour, but it should not be required, and is only temporarily available for backwards compatibility.
- Several triggers were modified to properly look up the tree for a target node, whereas previously they may have only checked the immediate parent. The affected triggers are `BringIntoView`, `Show`,`Hide`,`Collapse`, `Toggle`, `TransitionState`, `Callback`, `CancelInteractions`, `Stop`, `Play`, `Resume`, `Pause`, `TransitionLayout`, `BringToFront`, `SendToBack`, `EvaluateJS`, `RaiseUserEvent`, `ScrollTo`. This should only change previous behavior if the action was previously configured incorrectly and did nothing or already found the wrong node. Many of the actions have a `Target` to target a specific node, or `TargetNode` to specify where the search begins.
- Changed/fixed `Trigger` to provide the trigger itself as the target node to a `TriggerAction`, previously it'd provide the parent of the trigger. The old behaviour was due to an old tree structure. This should have been updated a long time ago. This allows actions to reference the trigger in which they are contained. If you've created a custom Uno `TriggerAction` and need the old behaviour modify your `Perform(Node target)` to use `target.Parent`. Triggers should in general scan upwards from the target node.

### ScrollView
- Added minimal support to WhileVisibleInScrollView for changes in Element layout updating the status

### Fuse.Drawing.Surface
- Added support for the Surface API in native UI for iOS. Meaning that `Curve`, `VectorLayer` and charting will work inside a `NativeViewHost`.

### TextInput
- Fixed issue on Android causing text to align incorrectly if being scrolled and unfocused.

### WrapPanel
- Added possibility to use `RowAlignment` to align the elements in the major direction of the `WrapPanel` as well as in the minor.

### Optimizations
- Optimized UpdateManager dispatcher to deal better with high numbers of dispatches per frame (as when populating long lists).
- Optimized how ZOrder was computed which improves layout and tree initialization speed. Inlcudes a minor change on the `ITreeRenderer` interface, unlikely to affect your code.
- Optimized how bounding boxes are calculated (improves layout and rendering performance).
- Optimized how render bounds are compounded for larger lists.
- Several low-level optimizations that speeds up scenarios with long lists (e.g. scrollviews). Here are the Uno-level details:
 * Optimized the implementation of the `Visual.Children` collection to be an implicitly linked list. This avoids all memory allocation and shifting in connection with inserting and removing nodes from a parent, and ensures a `O(1)` cost for all child list manipulations.
 * Introduced new public API: `Node.NextSibling<T>()` and `Node.PreviousSibling<T>()`, which can be together with `Visual.FirstChild<T>()` and `Visual.LastChild<T>()`. The recommended way of iterating over the children of a `Visual` is now `for (var c = parent.FirstChild<Visual>(); c != null; c = c.NextSibling<Visual>())` where `Visual` can be replaced with the desired node type to visit.

### Marshalling
- Fuse.Scripting now knows about the JS `Date` type, allowing instances to be passed to/from Uno in the form of `Uno.DateTime` objects. This support extends to databinding, `NativeModule`s, `ScriptClass`s, and the `Context.Wrap/Unwrap` API.
- Binding an object that does not implement `IArray` to a property that expects `IArray` will now automatically convert the value to an array of length 1.

### UpdateManager changes (Uno-level)
- Breaking change: Several entrypoints on UpdateManager now take a `LayoutPriority` enum instead of `int` as the `priority` argument. Very unlikely to affect user code code.
- Fixed an issue where writes to `FuseJS/Observables` would not dispatch in the right order on the UI thread if interleaved with `ScriptClass` callbacks (slightly breaking behavior).


# 1.2

## 1.2.1

### Fuse.Elements
- Fixed an issue where the ElementBatcher ended up throwing an Exception complaining about the element not having a caching rect.


## 1.2.0

### Fuse.Text
- Fixed an issue where the combination of `-DUSE_HARFBUZZ`, `-DCOCOAPODS` *and* certain Pods (in particular Firebase.Database has been identified) caused an app to link to symbols that the AppStore disallows.

### Each
- Fixed an issue where removing an element would not actually remove the element

### Image
- Fixed issue where an `<Image />` could fail to display inside a `<NativeViewHost />` on iOS

### Router
- Added `findRouter` function making it easier to use a router in a page deep inside the UI
- Fixed and issue where relative paths and nested `Router` gave an error about unknown paths

### UX Expressions (Uno-level)
- Introduced support for variable arguments to UX functions - inherit from the `Fuse.Reactive.VarArgFunction` class.
- The classes `Vector2`, `Vector3` and `Vector4` in `Fuse.Reactive` are now removed and replaced with the general purpose, variable-argument version `Vector` instead. This ensures vectors of any length are treated the same way. This is backwards incompatible in the unlikely case of having used these classes explicitly from Uno code.
- Added support for name-value pair syntax: `name: value`. Can be used for JSON-like object notation and named arguments in custom functions. Any vector of name-value pairs is interpreted as an `IObject`, e.g. `{name: 'Joe', apples: 10}` is an object.

### Templates
- Added `Identity` and `IdentityKey` to `Each`. This allows created visuals to be reused when replaced with `replaceAt` or `replaceAll` in an Observable.
- Triggers may now use templates which will be instantiated and added to the parent when active (like a node child).
	<WhileActive>
		<Circle ux:Generate="Template" Color="#AFA" Width="50" Height="50" Alignment="BottomRight"/>
	</WhileActive>
- Added templates to `NodeGroup`, which can now be used in `Each.TemplateSource` and `Instance.TemplateSource`
- `Each`, using `TemplateSource`, will no longer respond to template changes after rooting. This was done to simplify the code, and to support alternate sources, and is a minor perf improvement. It's not likely to affect any code since it didn't work correctly, and there's no way in UX to modify templates after rooting.
- A memory leak was fixed by changing `Instantiator.TemplateSource` to a WeakReference. Only if you assigned this property a temporary value in Uno would this change impact your code.
- Clarified/fixed some issues with how `Each`/`Instances` handled default templates. Previously if no matching template was found all the specified templates, or a subset, might have erronously been used. Now, as was always intended, if you use `MatchKey` and wish to have a default template you must specifiy `ux:DefaultTemplate="true"` on the default template. You cannot have multiple fallback templates, just as you can have only one template of a particular name.
- If a `ux:DefaultTemplate="true"` is specified it will be the template that is used; the complete list of templates will not be used.

### Fuse.Share
- Fixed issue where using Fuse.Share would crash on iPad. Users must provide a position for spawn origin for the share popover. Check the Fuse.Share docs for more details.
- Made iOS implementation internal, this was never ment to be public in the first place

### Optimizations
- Optimized hit testing calculations. Improves scrolling in large scroll views with deep trees inside, among other things.
- Optimized redundant OpenGL rendertarget operations. Gives speedups on some platforms.
- Optimized invalidation strategy for transforms, to avoid subtree traversion. This improves performance generally when animating large subtrees (e.g. scrollviews).
- Backwards incompatible optimization change: The `protected virtual void Visual.OnInvalidateWorldTransform()` method was removed. The contract of this method was very expensive to implement as it had to be called on all nodes, just in case it was overridden somewhere. If you have custom Uno code relying on this method (unlikely), then please rewrite to explicitly subscribe to the `Visual.WorldTransformInvalidated` event instead, like so: Override `OnRooted` and do `WorldTransformInvalidated += OnInvalidateWorldTransform;`, Override `OnUnrooted` and to `WorldTransformInvalidated -= OnInvalidateWorldTransform;`, then rewrite `protected override void OnInvalidateWorldTransform()` to `void OnInvalidateWorldTransform(object sender, EventArgs args)`
- To improve rendering speed, Fuse no longer checks for OpenGL errors in release builds in some performance-critical code paths
- Improved perceived ScrollView performance by preventing caching while pointers are pressed on them, avoiding inconsistent framerates.
- Fixed a bug which prevented elements like `Image` to use fast-track rendering in trivial cases with opacity (avoids render to texture).
- Optimized how bounding boxes are calculated (improves layout and rendering performance).

### Multitouch
- Fixed issue where during multitouch all input would stop if one finger was lifted.
- Added the option to opt-out of automatic handling of touch events when implementing a native view.

### Attract
- Added the `attract` feature, which was previously only in premiumlibs. This provides a much simpler syntax for animation than the `Attractor` behavior.

### Gesture
- The experimental `IGesture` interface has changed.
  * The `Significance`, `Priority` and `PriotityAdjustment` have been merged into the single `GetPriority` function.
  * `OnCapture` is changed to `OnCaptureChanged` and provides the previous capture state
- `Clicked`, `DoubleClicked`, `Tapped`, `DoubleTapped`, and `LongPressed` have been corrected to only detect the primary "first" pointer press. If you'd like to accept any pointer index add `PointerIndex="Any"` to the gesture.
    <Clicked PointerIndex="Any"/>
- `SwipeGesture`, `ScrollView`, `LinearRangeBehaviour` (`Slider`), `CircularRangeBehaviour`, `Clicked`, `Tapped`, `DoubleClicked`, `DoubleTapped`, `LongPressed`, `WhilePressed` all use the gesture system now. They have a `GesturePriority` property which can be used to adjust relative priorities -- though mostly the defaults should be fine.
- The `SwipeGesture.GesturePriority` default is changed from `High` to `Low`. This better fits with how the priorities should work together in a typical app and in general shouldn't affect any usual layouts. You can alter the priority with `GesturePriority="High"`

### Each Reuse
- Added `Reuse` to `Each` allowing the reuse of nodes
- Added `OnChildMoved` to `Visual`. Anything implementing `OnChildAdded` or `OnChildRemoved` will likely need to implement `OnChildMoved` as well. This happens when a child's position in `Children` list changes.
- Added `OnChildMovedWhileRooted` to `IParentObserver`

### UX Expression improvements
- Added `parameter(page)` function which returns the routing parameter of the page parsed as an JSON string.
- UX expressions now support arbitrary array lookups, e.g. `{someArray[index+3]}`. The same syntax can also be used with string keys, e.g `{someObject[someKey]}`. The lookup is fully reactive - both the collection and the key/index can change.

### JavaScript Dependency Injection
- Added support for injecting UX expressions into `<JavaScript>` tags using the `dep` XML namespace. See docs on `JavaScript.Dependencies` for details.

### WhileVisibleInScrollView
- Added `How` property to `WhileVisibleInScrollView` trigger that accepts values `Partial` (default) and `Full`. When set to `Full`, the trigger is only active when the whole element bounds are inside view.

## WebSocket
- Fixed connection problems on ios devices.


# 1.1

## 1.1.1

### Navigation
- Fixed an issue where `Activated` and `WhileActivated` within an `EdgeNavigator` did not correctly identify an active state
- Changed `EdgeNavigation` to return a page in `Active` when no side-panels are active

### Fuse.Share
- Fixed a crash in the iOS implementation for Fuse.Share that could happen on iPad.

### FuseJS
- Fixed a bug where disposing a JavaScript tag that has called the findData-method could lead to a crash.


## 1.1.0

### WhileActive
- Fixed a crash in the rooting of certain tree structures using any of the Navigation triggers such as `WhileActive`

### Fuse.ImageTools
- Fixed bug preventing handling of `KEEP_ASPECT` resize mode on Android when using ImageTools.resize

### Fuse.Camera
- iOS: Fixed crash when using Fuse.Camera alongside `<iOS.StatusBarConfig IsVisible="false" />`

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

### FuseJS
- Fixed a bug where disposing a JavaScript tag that has called the findData-method could lead to a crash.

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


## Old

See [the commit history for this file](https://github.com/fuse-open/fuselibs/commits/master/CHANGELOG.md) for older entries.
