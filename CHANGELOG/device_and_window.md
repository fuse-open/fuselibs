## Device and window()
- Marked several types internal that should not have been public: `SystemUI` and related types
- Changed `ClientPanel` to use `Padding` instead of panels.
- Added `window()` function to get device UI borders: `safeMargins`, `staticMargins` and `deviceMargins`. This will allow developing for devices with extended border areas such as the iPhone X
- Added `Device` global to query platform details, such as `Device.isIOS` and `Device.isAndroid`
