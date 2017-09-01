using Uno;

namespace Fuse.Triggers
{
	public interface IPlayback : IProgress
	{
		/** Stops playback and sets progress to 0 */
		void Stop();
		/** Pauses playback and retains current progress */
		void Pause();
		/** Resumes playing when stopped or paused. May continue in previous direction if supported, such as in @Timeline */
		void Resume();
		double Progress { get; set; }

		/** Deprecated 2017-02-27. All implemenations must return `true` for this interface */
		[Obsolete]
		bool CanStop { get; }
		[Obsolete]
		bool CanPause { get; }
		[Obsolete]
		bool CanResume { get; }
		
		/** Deprecated 2017-02-27 */
		[Obsolete]
		void PlayTo(double progress);
		[Obsolete]
		bool CanPlayTo { get; }
	}

	public interface IMediaPlayback : IPlayback
	{
		float Volume { get; set; }
		double Position { get; set; }
		double Duration { get; }
	}
	
}

namespace Fuse.Triggers.Actions
{
	public abstract class PlaybackAction : TriggerAction
	{
		public IPlayback Target { get; set; }

		internal PlaybackAction() { }
	}

	/** Stop a video or timeline.

		The position is set to the beginning, and the playback is stopped.
	
		## Video Example
		
			<Grid Rows="3*,1*" >
				<Video ux:Name="video" Url="http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4" StretchMode="Uniform" />
				<Grid Columns="1*,1*">
					<Button Text="Start">
						<Clicked>
							<Resume Target="video" />
						</Clicked>
					</Button>
					<Button Text="Stop">
						<Clicked>
							<Stop Target="video" />                
						</Clicked>
					</Button>				
				</Grid>
			</Grid>

		## Timeline Example

			<StackPanel>
				<Rectangle Width="150" Height="150" Margin="60" ux:Name="rect" CornerRadius="10" >
					<Stroke ux:Name="rectStroke" Offset="10" Width="3" Color="#3579e6" />
					
					<Timeline  ux:Name="timeline" TimeMultiplier="0.4">
						<Rotate>
							<Keyframe DegreesZ="360" Time="1" />
						</Rotate>
						<Change Target="rect.Color">
							<Keyframe Value="#3579e6" Time="1" />
						</Change>
					</Timeline>
				</Rectangle>

				<Slider Width="250" ux:Name="targetProgress" Value="0.5" Minimum="0" Maximum="1" />
				<Button Text="Animate to" Alignment="Bottom">
					<Clicked>
						<PlayTo Target="timeline" Progress="{ReadProperty targetProgress.Value}" />
					</Clicked>
				</Button>

				<Button ux:Name="resume" Text="Resume" Alignment="Bottom">
					<Clicked>
						<Resume Target="timeline" />
					</Clicked>
				</Button>

				<Button Text="Pause" Alignment="Bottom">
					<Clicked>
						<Pause Target="timeline" />
					</Clicked>
				</Button>

				<Button Text="Stop" Alignment="Bottom">
					<Clicked>
						<Stop Target="timeline" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	public sealed class Stop : PlaybackAction
	{
		protected override void Perform(Node target)
		{
			var t = Target ?? target.FindByType<IPlayback>();
			if (t != null)
				t.Stop();
		}
	}

	/** Pause a video or timeline
		
		This stops playback but does not change the current position.

		## Example
		
			<Grid Rows="3*,1*" >
				<Video ux:Name="video" Url="http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4" AutoPlay="true" StretchMode="Uniform" />
				<Grid Columns="1*,1*">
					<Button Text="Resume">
						<Clicked>
							<Resume Target="video" />
						</Clicked>
					</Button>
					<Button Text="Pause">
						<Clicked>
							<Pause Target="video" />
						</Clicked>
					</Button>
				</Grid>
			</Grid>
	*/
	public sealed class Pause : PlaybackAction
	{
		protected override void Perform(Node target)
		{
			var t = Target ?? target.FindByType<IPlayback>();
			if (t != null)
				t.Pause();
		}
	}

	/** Resume or start a video or timeline
	
		This continues playing from where the video or timeline was paused (or from the start if `Stop` was called).
		
		A timeline will play either forward or backward, depending on the last play direction.

		## Video Example
	
			<Grid Rows="3*,1*" >
				<Video ux:Name="video" Url="http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4" StretchMode="Uniform" />
				<Button Text="Play">
					<Clicked>
						<Play Target="video" />
					</Clicked>
				</Button>
			</Grid>

		## Timeline Example

			<StackPanel>
				<Rectangle Width="150" Height="150" Margin="60" ux:Name="rect" CornerRadius="10" >
					<Stroke ux:Name="rectStroke" Offset="10" Width="3" Color="#3579e6" />
					
					<Timeline  ux:Name="timeline" TimeMultiplier="0.4">
						<Rotate>
							<Keyframe DegreesZ="360" Time="1" />
						</Rotate>
						<Change Target="rect.Color">
							<Keyframe Value="#3579e6" Time="1" />
						</Change>
					</Timeline>
				</Rectangle>

				<Slider Width="250" ux:Name="targetProgress" Value="0.5" Minimum="0" Maximum="1" />
				<Button Text="Animate to" Alignment="Bottom">
					<Clicked>
						<PlayTo Target="timeline" Progress="{Property targetProgress.Value}" />
					</Clicked>
				</Button>

				<Button ux:Name="play" Text="Play" Alignment="Bottom">
					<Clicked>
						<Play Target="timeline" />
					</Clicked>
				</Button>

				<Button Text="Pause" Alignment="Bottom">
					<Clicked>
						<Pause Target="timeline" />
					</Clicked>
				</Button>

				<Button Text="Stop" Alignment="Bottom">
					<Clicked>
						<Stop Target="timeline" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	public class Play : PlaybackAction
	{
		protected override void Perform(Node target)
		{
			var t = Target ?? target.FindByType<IPlayback>();
			if (t != null)
				t.Resume();
		}
	}
	
	/**
		@deprecated Use @Play
	*/
	public sealed class Resume : Play
	{
		public Resume()
		{
			//DEPRECATED: 2017-02-27
			Fuse.Diagnostics.Deprecated( "Use `Play` instead of `Resume`", this );
		}
	}
	

	/** Play to a specific point in a timeline
	
		## Example
		
			<StackPanel>
				<Rectangle Width="150" Height="150" Margin="60" ux:Name="rect" CornerRadius="10" >
					<Stroke ux:Name="rectStroke" Offset="10" Width="3" Color="#3579e6" />
					
					<Timeline  ux:Name="timeline" TimeMultiplier="0.4">
						<Rotate>
							<Keyframe DegreesZ="360" Time="1" />
						</Rotate>
						<Change Target="rect.Color">
							<Keyframe Value="#3579e6" Time="1" />
						</Change>
					</Timeline>
				</Rectangle>

				<Slider Width="250" ux:Name="targetProgress" Value="0.5" Minimum="0" Maximum="1" />
				<Button Text="Animate to" Alignment="Bottom">
					<Clicked>
						<PlayTo Target="timeline" Progress="{ReadProperty targetProgress.Value}" />
					</Clicked>
				</Button>

				<Button ux:Name="resume" Text="Resume" Alignment="Bottom">
					<Clicked>
						<Resume Target="timeline" />
					</Clicked>
				</Button>

				<Button Text="Pause" Alignment="Bottom">
					<Clicked>
						<Pause Target="timeline" />
					</Clicked>
				</Button>

				<Button Text="Stop" Alignment="Bottom">
					<Clicked>
						<Stop Target="timeline" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	[Obsolete]
	public sealed class PlayTo : PlaybackAction
	{
		public double Progress { get; set; }

		public PlayTo()
		{
			//DEPRECATED: 2017-02-27
			Fuse.Diagnostics.Deprecated( "Use the TimelineAction with `How=\"PlayTo\" instead.", this );
		}
		
		protected override void Perform(Node target)
		{
			var t = Target ?? target.FindByType<IPlayback>();
			if (t != null)
				t.PlayTo(Progress);		
		}
	}

}
