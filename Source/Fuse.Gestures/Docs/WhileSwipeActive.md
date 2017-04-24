This example animates a panel when it has been swiped up.

	<Panel Width="100" Height="100">
		<SwipeGesture ux:Name="swipe" Direction="Up" Length="50" Type="Simple" />
		<WhileSwipeActive Source="swipe">
			<Scale Factor="1.5" Duration="0.4" DurationBack="0.2" />
		</WhileSwipeActive>
	</Panel>
