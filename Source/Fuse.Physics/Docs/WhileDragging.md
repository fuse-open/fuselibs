This example shows a rectangle that animates while it is being dragged:

	<Panel>
		<Rectangle Background="Blue" Width="50" Height="100">
			<Draggable/>
			<WhileDragging>
				<Rotate Degrees="90" Duration="0.8"
					Easing="BounceOut" EasingBack="BounceIn"/>
			</WhileDragging>
		</Rectangle>
	</Panel>
