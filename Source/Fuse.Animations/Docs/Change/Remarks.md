## Animating layout properties

While animating layout properties such as `Width`, `Height` or `Margin` is possible, it can lead to huge performance issues.
This is because the app has to recalculate its entire layout for each frame of the animation.

A much faster alternative is to use @LayoutAnimation, as it only needs to recalculate layout for the children of the element being animated.
Take a look at the @LayoutAnimation docs for more info.