### Video
- Fixed issue where Video on Android could end up not finding the rotation metadata on its video source
- Fixed issue where Video on iOS could render incorrect on some rotations
- Removed size flip in VideoVisual, looks like this used to work due to bug dependency. But the native video players flip the size themselves.
