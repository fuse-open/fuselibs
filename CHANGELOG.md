# Unreleased

## Notifications
- Fix regression causing iOS apps not to be accepted to the Store apparently due to use of push-notifications even though they are not used in the project.

## Navigation
- `Navigator` blocks input to pages while trasitioning to new pages. To get the old behaviour, where input is not blocked, set `<Navigator BlockInput="Never">`.

## Fuse.Reactive
- Added `OnLostData` to the `IListener` interface. This is needed to properly deal with changes in context in
 Preview, Model, and some JavaScript situations.
- Added `OnLostData` to the `InnerListener` class. Implementations should deal with this scenario.
- Changed null coalesce `??` to use the default when the left operand doesn't exist, not just when it's null

## Fuse.Marshal
- `ToDouble` replaced with `TryToDouble` for naming consistency (old names remain as deprecated)

## Fuse.Panel
- Fixed a bug where `IsFrozen` would ignore `Panel.Opacity`.

## Scripting
- `Fuse.Scripting`'s `Function` type has a `Call` method, this now takes a `Scripting.Context`. This guarentees that it can only occur on the VM thread.
- `Fuse.Scripting`'s `Object` type has a `CallMethod` method, this now takes a `Scripting.Context`. This guarentees that it can only occur on the VM thread.
- IMirror is no longer implemented by ThreadWorker. This functionality has been moved to the context
- Moved `ArrayMirror`, `ClassInstance`, `ModuleInstance`, `ObjectMirror`, `Observable`, `ObservableProperty`, `RootableScriptModule` & `ThreadWorker` to the `Fuse.Scripting.JavaScript` namespace
- Removed the `CanEvaluate` method and instead rely on the passing of the `Scripting.Context` to know if we are on the VM thread or not. This required adding some methods to the `ISubscription` which take the `Scripting.Context`
- The 'wrapping' functionality has been moved from the `ThreadWorker` to a standalone static class called `TypeWrapper`. The `IThreadWorker` no longer provides `Wrap` & `UnWrap`
- `ThreadWorker.ScriptClass` functionality moved to context. We will likely want to factor this out to a helper class however for now the major benefit is that `ThreadWorker` no longer owns these features.
- Remove the public `Context` property from the `ThreadWorker`. Sadly the context is still available via the internal field so that the tests can work. This will need to be fixed.
- `Fuse.Reactive` now depends on `Fuse.Scripting` so that it can talk about the `Scripting.Context` in it's provided interfaces.
- `DateTimeConverterHelpers` moved to its own uno file.
- `IMirror`'s `Reflect` now takes a `Scripting.Context`
- IThreadWorker no longer implement IDispatcher

# 1.4

## 1.4.0

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

See [the commit history for this file](https://github.com/fusetools/fuselibs-public/commits/master/CHANGELOG.md) for older entries.
