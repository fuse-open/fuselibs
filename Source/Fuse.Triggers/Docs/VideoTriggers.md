The following example shows how we can use triggers inside a @Video to display
an overlay over the video when it is loading, paused, completed, or has failed.
It also uses these triggers to display a play button and a pause button only at
appropriate times.


	<StackPanel>
		<Panel>
			<Panel ux:Name="overlay" Background="Black" Opacity="0">
				<Text ux:Name="overlayText" Color="White" Alignment="Center" />
			</Panel>

			<WhileTrue ux:Name="showOverlay">
				<Change overlay.Opacity="0.5" Duration="0.2" />
			</WhileTrue>

			<Video ux:Name="video" Url="http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4" >
				<WhilePlaying>
					<Change playButton.Visibility="Hidden" />
					<Change pauseButton.Visibility="Visible" />
				</WhilePlaying>

				<WhileLoading>
					<Change showOverlay.Value="True" />
					<Change overlayText.Value="Loading..." />
				</WhileLoading>

				<WhilePaused>
					<Change showOverlay.Value="True" />
					<Change overlayText.Value="Paused" />
				</WhilePaused>

				<WhileCompleted>
					<Change showOverlay.Value="True" />
					<Change overlayText.Value="Completed" />
				</WhileCompleted>

				<WhileFailed>
					<Change showOverlay.Value="True" />
					<Change overlayText.Value="Error" />
				</WhileFailed>
			</Video>
		</Panel>

		<Grid ColumnCount="2">
			<Button ux:Name="playButton" Text="Play">
				<Clicked>
					<Resume Target="video" />
				</Clicked>
			</Button>
			<Button ux:Name="pauseButton" Text="Pause" Visibility="Hidden">
				<Clicked>
					<Pause Target="video" />
				</Clicked>
			</Button>
		</Grid>
	</StackPanel>
