## DataContext
- Removed some deprecated methods and classes from `Node`: `IDataListener`, `OnDataChanged`. These were not meant to be public.
- Deprecated `{}` in favour of the new `data()` function. `{}` had unusual binding rules and would often not bind to the intended context. `data()` always binds to the prime data context, it's unambiguous and predictable.