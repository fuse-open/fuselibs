## Grid
- Fixed a `Grid` defect that resulted in some cells not calculating the correct layout size.
- `Grid` now detects a common invalid configuration and emits an error. This may trigger on projects that currently work, but are relying on undefined/broken behavior.