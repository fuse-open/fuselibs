## Router 
- Deprecated the GoUp behavior which causes unexpected behavior and defects. This fixes an issue of pressing the hardware back button at the root state (on Android).  The old behavior can be had by setting `GoBackBehavior="GoBackAndUp"` on the router, but be aware it is deprecated and will be removed.
- Added `Router.BackAtRootPressed` to allow intercepting a back button action on the root page.

