## Safe Layout

Many devices have areas of the screen containing system controls, such as the time or back button, or have physically occluded regions, such as rounded corners or the camera on an iPhone X. Your app must accommodate these regions: you should draw a background in these areas but should not place controls there.

Fuse has a few features to help create your layout.

> It's recommended that you test your layout on various devices, in particular, those with physical margins, like the iPhoneX. The XCode simulator allows you to test on a variety of iOS devices.


## SafeEdgePanel

The @SafeEdgePanel is a panel that adds padding for the safe areas.  You should use it for any panel that touches the side of the display.

For example, this panel adds a title at the top of the screen.

    <DockPanel>
        <SafeEdgePanel Edges="LeftTopRight" Dock="Top" Color="#FFF" ExtraPadding="2">
            <Text Value="App Title" Alignment="Center">
        </SafeEdgePanel>
    </DockPanel>
    
On supported devices, this will draw the color `#FFF` behind the status bar. The text is positioned as to overlap with any system controls or device margins.

A @SafeEdgePanel is essentially a @Panel with a device dependent `Padding`. The `Edges` property states which edges it touches, and thus which padding values are set. The property `ExtraPadding` allows you to add extra padding to this.

### Fewer Edges

The rather wordy `Edges` properties like `LeftTopRight` allow for fine control over how you construct your layout. Though it's typical to specify three edges, it's common to have fewer edges.

For example, you may wish to have a swipe panel form the right that is within the bounds of the title and action bars. In this case, you'd only specify `Edges="Right"`.

    <DockPanel>
        <SafeEdgePanel Dock="Top" Edges="LeftTopRight" Color="#FFF">
            <!-- title area -->
        </SafeEdgePanel>
        <SafeEdgePanel Dock="Bottom" Edges="LeftRightBottom" Color="#FFF">
            <!-- action bar -->
        </SafeEdgePanel>
        
        <SwipeGesture Edge="Right" LengthNode="rightNode" ux:Name="rightSwipe" Type="Active"/>
        <SwipingAnimation Source="rightSwipe">
            <Move Target="rightNode" X="-1" RelativeTo="Size"/>
        </SwipingAnimation>
        <SafeEdgePanel PadEdges="Right" Color="#EFE" Alignment="Right" Anchor="0%,50%" ux:Name="rightNode" MinEdgePadding="10,5">
            <!-- right side bar -->
        </SafeEdgePanel>
    </DockPanel>
        
The title bar accounts for the top margins, and the action bar for the bottom margins, thus the side bar only needs to add padding for the right device margins with `Edges="Right"`.


## window()

The values used by `SafeEdgePanel` are available directly with `window().safeMargins`. You can use these values for finer control over your layout.

For example, you may wish to have an action button in the bottom right corner. It makes more sense to adjust its margin than create a wrapping `SafeEdgePanel` panel with padding -- though that would work fine as well.

    <Circle Width="50" Height="50" Color="#EEF"    Margin="window().safeMargins">
        <!-- icon & activation code -->
    </Circle>

This code specifies all four margins, but since it's in the bottom right corner the top and left margins have no visible effect.  Though it works here it may not always be okay. To get a strict a bottom-right margin use the expression `window().safeMargins * (0,0,1,1)` instead. This zeros out the top-left margin, keeping the bottom-right.

> You may also use the `x/y/z/w` functions to extract parts of the margins. For example, `x(window().safeMargins)` gets the left margin value. Margins are specified as `float4` in the "left, top, right, bottom" ordering.


## ClientPanel

The @ClientPanel is only suitable for basic apps that don't have edge panels, and where the color blends with the `App.Background` color.
