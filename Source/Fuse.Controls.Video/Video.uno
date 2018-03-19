using Uno;
using Uno.UX;
using Fuse;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Triggers;

namespace Fuse.Controls
{

	public abstract class VideoSource
	{
		public event EventHandler SourceChanged;

		protected void OnSourceChanged()
		{
			if (SourceChanged != null)
				SourceChanged(this, EventArgs.Empty);
		}

	}

	public class FileVideoSource : VideoSource
	{
		FileSource _file;
		public FileSource File
		{
			get { return _file; }
			set
			{
				_file = value;
				OnSourceChanged();
			}
		}
	}

	public class UrlVideoSource : VideoSource
	{
		string _url;
		public string Url
		{
			get { return _url; }
			set
			{
				_url = value;
				OnSourceChanged();
			}
		}
	}

	/** Displays a video.

		`Video` allows playback of video from file or stream through its properties `File` and `Url` respectively.
		It is similar to Image; they share the properties `StretchMode`, `StretchDirection` and `ContentAlignment` and they work in the same way for both classes.

		## Useful properties
		
		Video comes with a set of properties that can be used to configure it or control it, in addition to the properties shared with Image:

		- `Volume`: range from 0.0 to 1.0, default is 1.0
		- `Duration`: the duration of the video in seconds
		- `Position`: the current position of the video in seconds
		- `IsLooping`: a bool specifying if the video should loop or not, default is false

		## Useful triggers that can be used with `Video`

			<Video>
				<WhilePlaying />    <!-- Active while the video is playing -->
				<WhilePaused />     <!-- Active while the video is paused -->
				<WhileCompleted />  <!-- Active while the video is done playing -->
				<WhileLoading />    <!-- Active while the video is loading -->
				<WhileFailed />     <!-- Active if the video failed to load or an error occured -->
			</Video>

		## Useful actions that can be used to control `Video`

		Fuse comes with a set of actions that can be used to control video playback. They all have a common `Target` property that specifies which `Video` element they control.

			<Pause />                   <!-- Pauses playback, leaving the current position as-is -->
			<Stop />                    <!-- Stops playback and returns to the beginning of the video -->
			<Resume />                  <!-- Resumes playback from the current position -->

		## Supported formats

		`Video` is implemented by using the videodecoder provided by the export target and therefore supports whatever the platform supports. Be aware that Windows, OS X, Android and iOS might not share support for some formats

		- [Android supported formats](https://developer.android.com/guide/appendix/media-formats.html)
		- [iOS and OS X supported formats (found under 'public.movie')](https://developer.apple.com/library/mac/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html)
		- [Windows supported formats](https://msdn.microsoft.com/en-us/library/cc189080%28v=vs.95%29.aspx?f=255&MSPPError=-2147217396)
		
		## Playing from the local file system

		Videos can also be played from the local file system of the device the app is running on. This can be done by prepending `file://` to the absolute path of the video:

			<Video File="file:///data/data/com.fuse.app/video.mp4" />
		
		Notice the three slashes at the start. This is due to unix file system paths always beginning with a `/`

		## Example

		The following example shows how to play a video, display its playback progress using @ProgressAnimation, and pause/resume the video using the @Pause and @Resume animators.

			<DockPanel>
				<Video ux:Name="video" Dock="Fill" File="fuse_video.mp4" IsLooping="true" StretchMode="UniformToFill">
					<ProgressAnimation>
						<Change progressBar.Width="100" />
					</ProgressAnimation>
				</Video>
				<Rectangle ux:Name="progressBar" Dock="Bottom" Fill="#f00" Width="0%" Height="10" />
				<Grid Dock="Bottom" ColumnCount="2" RowCount="1">
					<Button Text="Play">
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
			</DockPanel>
			
	*/
	public partial class Video : Panel, IMediaPlayback
	{

		VideoSource _source;
		[UXContent]
		/** The source of this video.
		
			Using this property can not be combined with using `Url` or `File`.
		*/
		public VideoSource Source
		{
			get { return _source; }
			set
			{
				if (_source != null)
				{
					_source.SourceChanged -= OnVideoSourceChanged;
					ClearSource(_source);
				}

				_source = value;

				if (_source != null)
				{
					_source.SourceChanged += OnVideoSourceChanged;
					SetSource(_source);
				}
			}
		}

		void OnVideoSourceChanged(object sender, EventArgs args)
		{
			SetSource(_source);
		}

		void ClearSource(VideoSource source)
		{
			if (source is FileVideoSource)
				File = null;

			else if (source is UrlVideoSource)
				Url = null;
		}

		void SetSource(VideoSource source)
		{
			if (source is FileVideoSource)
				File = ((FileVideoSource)source).File;

			else if (source is UrlVideoSource)
				Url = ((UrlVideoSource)source).Url;
		}

		FileSource _file;
		/**
			Loads a video from a File.

			Only one of `File`, `Url` or `Source` can be specified.
		*/
		public FileSource File
		{
			get { return _file; }
			set
			{
				if (_file != value)
				{
					_file = value;
					OnSourceChanged();
				}
			}
		}

		string _url;
		/** A Url describing an http video stream resource to be played.

			Only one of `File`, `Url` or `Source` can be specified.
		*/
		public string Url
		{
			get { return _url; }
			set
			{
				if (_url != value)
				{
					_url = value;
					OnSourceChanged();
				}
			}
		}

		float4 _scale9Margin = float4(10);
		bool _hasScale9Margin;
		/** For `StretchMode="Scale9"` this defines the four margins that split the video into 9-sections for scaling. */
		public float4 Scale9Margin
		{
			get { return _scale9Margin; }
			set
			{
				if (!_hasScale9Margin || _scale9Margin != value)
				{
					_scale9Margin = value;
					_hasScale9Margin = true;
					OnParamChanged();
				}
			}
		}

		bool _isLooping;
		/** Whether the video is playing in a loop.
			@default false
		*/
		public bool IsLooping
		{
			get { return _isLooping; }
			set 
			{ 
				if (_isLooping != value)
				{
					_isLooping = value;
					OnParamChanged();
				}
			}
		}

		bool _autoPlay;
		/** Whether the video automatically starts playing.
			@default false
		*/
		public bool AutoPlay
		{
			get { return _autoPlay; }
			set 
			{ 
				if (_autoPlay != value)
				{
					_autoPlay = value;
					OnParamChanged();
				}
			}
		}

		StretchMode _stretchMode = StretchMode.Uniform;
		/** Specifies how the size of the video element is calculated and how the video is stretched inside it.
			@default StretchMode.Uniform
		*/
		public StretchMode StretchMode
		{
			get { return _stretchMode; }
			set 
			{ 
				if (_stretchMode != value)
				{
					_stretchMode = value;
					OnRenderParamChanged();
				}
			}
		}

		StretchDirection _stretchDirection = StretchDirection.Both;
		/** Specifies whether a video can become larger or smaller to fill the available space.
			@default StretchDirection.Both
		*/
		public StretchDirection StretchDirection
		{
			get { return _stretchDirection; }
			set 
			{ 
				if (_stretchDirection != value)
				{
					_stretchDirection = value;
					OnRenderParamChanged();
				}
			}
		}

		StretchSizing _stretchSizing = StretchSizing.Natural;
		/** During layout this indicates how the size of the image should be reported.

			This is typically modified when using larger videos in a layout where you don't want the video to influence the size of the panel but to just stretch to fill it.
			@default StretchSizing.Natural
		*/
		public StretchSizing StretchSizing
		{
			get { return _stretchSizing; }
			set 
			{ 
				if (_stretchSizing != value)
				{
					_stretchSizing = value;
					OnRenderParamChanged();
				}
			}
		}

		Fuse.Elements.Alignment _contentAlignment = Fuse.Elements.Alignment.Center;
		/** Specifies the alignment of the video inside the element. 
		
		This is used when the video itself does not fill, or overfills, the available space.
			@default Fuse.Elements.Alignment.Center
		*/
		public Fuse.Elements.Alignment ContentAlignment
		{
			get { return _contentAlignment; }
			set 
			{
				if (_contentAlignment != value)
				{
					_contentAlignment = value;
					OnRenderParamChanged();
				}
			}
		}

		float _volume = 1.0f;
		/* The volume of the audio in the range from 0.0 (no sound) to 1.0 (full sound)
		 	@default 1.0
			*/
		public float Volume
		{
			get { return _volume; }
			set 
			{ 
				if (_volume != value)
				{
					_volume = value;
					OnParamChanged();
				}
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			Children.Add(new Fuse.Controls.VideoImpl.VideoVisual());
		}

		protected override void OnUnrooted()
		{
			RemoveAllChildren<Fuse.Controls.VideoImpl.VideoVisual>();
			base.OnUnrooted();
		}
		
		/** @advanced */
		public event EventHandler RenderParamChanged;

		/** @advanced */
		public event EventHandler ParamChanged;

		/** @advanced */
		public event EventHandler SourceChanged;

		void OnRenderParamChanged()
		{
			if (RenderParamChanged != null)
				RenderParamChanged(this, EventArgs.Empty);
		}

		void OnParamChanged()
		{
			if (ParamChanged != null)
				ParamChanged(this, EventArgs.Empty);
		}

		void OnSourceChanged()
		{
			if (SourceChanged != null)
				SourceChanged(this, EventArgs.Empty);
		}

		public void Stop()
		{
			if (Playback != null)
				Playback.Stop();
		}

		/** Deprecated 2017-02-27 */
		[Obsolete]
		public void PlayTo(double progress)
		{
			if (Playback != null)
				Playback.PlayTo(progress);
		}
		[Obsolete]
		public bool CanPlayTo
		{
			get { return Playback != null ? Playback.CanPlayTo : false; }
		}
		[Obsolete]
		public bool CanStop
		{
			get { return true; }
		}
		[Obsolete]
		public bool CanPause
		{
			get { return true; }
		}
		[Obsolete]
		public bool CanResume
		{
			get { return true; }
		}
		/* End-Deprecated */

		public void Pause()
		{
			if (Playback != null)
				Playback.Pause();
		}

		public void Resume()
		{
			if (Playback != null)
				Playback.Resume();
		}


		[UXOriginSetter("SetProgress")]
		public double Progress
		{
			get { return Playback != null ? (Playback as IPlayback).Progress : 0.0; }
			set { if (Playback != null) (Playback as IPlayback).Progress = value; }
		}

		/*** The position of the video in seconds */
		public new double Position
		{
			get { return Playback != null ? Playback.Position : 0.0; }
			set { if (Playback != null) Playback.Position = value; }
		}

		public double Duration
		{
			get { return Playback != null ? Playback.Duration : 0.0; }
		}

		public event ValueChangedHandler<double> ProgressChanged;

		IMediaPlayback _playback;
		IMediaPlayback Playback
		{
			get { return _playback; }
			set
			{
				if (_playback != null)
					_playback.ProgressChanged -= OnProgressChanged;

				_playback = value;

				if (_playback != null)
					_playback.ProgressChanged += OnProgressChanged;

				if (IsRootingCompleted)
				{
					OnProgressChanged(null, null);
				}
			}
		}

		static Selector _positionName = "Position";
		static Selector _durationName = "Duration";
		static Selector _progressName = "Progress";

		void OnProgressChanged(object sender, EventArgs args)
		{
			UpdateScriptClass(Duration);

			OnPropertyChanged(_positionName);
			OnPropertyChanged(_progressName);

			if (ProgressChanged != null)
				ProgressChanged(this, new ValueChangedArgs<double>(Progress));
		}

		internal void OnDurationChanged()
		{
			OnPropertyChanged(_durationName);
		}

		public void SetPlayback(IMediaPlayback playback)
		{
			Playback = playback;
		}

		public void SetProgress(double value, IPropertyListener origin)
		{
			if (origin != this)
			{
				Progress = value;
			}
		}

	}

}
