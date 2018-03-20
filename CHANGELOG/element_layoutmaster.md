## LayoutMaster
- Fixed a redundant layout invalidation when `Element.LayoutMaster` is changed. This would result in broken `LayoutAnimation` as multiple layouts could be triggered by a `Change`.