## Vector Drawing
- Fixed a defect in partial line drawing in Preview that resulted in a spurious line being drawn. This happened when the partial curve overlapped the end of the path data.
- Fixed a defect that prevented a single-segment, horizontal or vertical, line from rendering in `Path` with `StretchMode="Uniform"` (the default `StretchMode`).