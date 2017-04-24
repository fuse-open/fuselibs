
## Why not just Move, Scale and Rotate directly?

When you want to do several transformations on the same element, the order in which they are applied matters. Being explicit about adding transforms lets us exploit this fact.

```
<Rectangle Color="Green" Width="50" Height="50">
	<Translation X="100" />
	<Rotation Degrees="45" />
</Rectangle>

<Rectangle Color="Red" Width="50" Height="50">
	<Rotation Degrees="45" />
	<Translation X="100" />
</Rectangle>
```

The top rectangle is moved 100 points to the right, and then rotated by 45 degrees. It ends up being placed 100 points to the right of its original position.

The second rectangle however is rotated first, and then moved. Because of the initial rotation, the positive X direction is now towards the bottom right. Because of this, the rectangle ends up 100 points towards the bottom right.


## Caveats

Scaling an element too much can lead to aliasing effects. This is because the element being scaled is first rendered to a texture, which then gets scaled. This makes animating the `Scaling` very fast compared to animating an elements `Width` and `Height`.
