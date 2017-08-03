﻿using System;
using System.Reflection;
using MonoMac.Foundation;
using MonoMac.AVFoundation;
using MonoMac.CoreVideo;
using MonoMac.CoreMedia;
using MonoMac.CoreFoundation;
using MonoMac.OpenGL;
using MonoMac.CoreGraphics;
using System.Drawing;

namespace Fuse.Video.Mono
{
	public class VideoHandle
	{
		public AVUrlAsset Asset;
		public AVPlayer Player;
		public AVPlayerItem PlayerItem;
		public AVAudioPlayer AudioPlayer;
		public AVPlayerItemVideoOutput Output;
		public byte[] Pixels;
		public int WidthCache = -1;
		public int HeightCache = -1;
	}

	public static class VideoImpl
	{

		static readonly MethodInfo _copyPixelBufferMethod;

		static VideoImpl()
		{
			_copyPixelBufferMethod = typeof(AVPlayerItemVideoOutput).GetMethod("WeakCopyPixelBuffer", BindingFlags.NonPublic | BindingFlags.Instance);
		}

		static PixelBuffer CopyPixelBuffer(AVPlayerItemVideoOutput output, CMTime time, ref CMTime outItemTimeForDisplay)
		{
			var args = new object[] { time, outItemTimeForDisplay };
			var result = _copyPixelBufferMethod.Invoke(output, args);
			return new PixelBuffer((IntPtr)result);
		}

		public static VideoHandle Create(string uri, Action loaded, Action<string> error)
		{
			var handle = new VideoHandle();
			var url = new NSUrl(uri);
			handle.Asset = new AVUrlAsset(url, (AVUrlAssetOptions)null);
			handle.Asset.LoadValuesAsynchronously(new string[] { "tracks" }, new NSAction(
				() => DispatchQueue.MainQueue.DispatchAsync(new NSAction(
					() => {

						NSError e;
						var status = handle.Asset.StatusOfValue("tracks", out e);
						if (status == AVKeyValueStatus.Loaded)
						{
							handle.Output = new AVPlayerItemVideoOutput(
								new CVPixelBufferAttributes
								{
									PixelFormatType = CVPixelFormatType.CV32BGRA,
								});

							handle.PlayerItem = AVPlayerItem.FromAsset(handle.Asset);
							handle.PlayerItem.AddOutput(handle.Output);
							handle.Player = AVPlayer.FromPlayerItem(handle.PlayerItem);
							handle.AudioPlayer = new AVAudioPlayer(handle.Player.Handle);
							PollReadyState(handle, loaded, error);
						}
						else
						{
							error("Failed to load: " + status.ToString());
						}
					}))));

			return handle;
		}

		static void PollReadyState(VideoHandle handle, Action ready, Action<string> error)
		{
			switch (handle.PlayerItem.Status)
			{
			case AVPlayerItemStatus.ReadyToPlay:
				ready();
				break;
			case AVPlayerItemStatus.Failed:
				error("Failed to load: " + handle.PlayerItem.Status.ToString());
				break;
			default:
				DispatchQueue.MainQueue.DispatchAsync(
					new NSAction(() => PollReadyState(handle, ready, error)));
				break;
			}
		}

		public static void Play(VideoHandle handle)
		{
			handle.Player.Play();
		}

		public static void Pause(VideoHandle handle)
		{
			handle.Player.Pause();
		}

		public static double GetPosition(VideoHandle handle)
		{
			return handle.PlayerItem.CurrentTime.Seconds;
		}

		public static void SetPosition(VideoHandle handle, double position)
		{
			handle.PlayerItem.Seek(CMTime.FromSeconds(position, 1000));
		}

		public static int GetWidth(VideoHandle handle)
		{
			return handle.PlayerItem.PresentationSize.ToSize().Width;
		}

		public static int GetHeight(VideoHandle handle)
		{
			return handle.PlayerItem.PresentationSize.ToSize().Height;
		}

		public static double GetDuration(VideoHandle handle)
		{
			return handle.Asset.Duration.Seconds;
		}

		public static bool HasNewPixelBuffer(VideoHandle handle)
		{
			return handle.Output.HasNewPixelBufferForItemTime(handle.PlayerItem.CurrentTime);
		}

		public static void UpdateTexture(VideoHandle handle, System.Int32 textureHandle)
		{
			var pixelBufferSize = GetWidth (handle) * GetHeight (handle) * 4;

			if (handle.Pixels == null || handle.Pixels.Length != pixelBufferSize)
				handle.Pixels = new byte[pixelBufferSize];
			
			var rt = new CMTime();
			using (var buffer = CopyPixelBuffer (handle.Output, handle.PlayerItem.CurrentTime, ref rt))
				buffer.UpdateTexture (textureHandle, handle);
		}

		public static float GetVolume(VideoHandle handle)
		{
			return handle.AudioPlayer.Volume;	
		}

		public static void SetVolume(VideoHandle handle, float volume)
		{
			handle.AudioPlayer.Volume = volume;
		}

		public static void Stop(VideoHandle handle)
		{
			Pause(handle);
			SetPosition(handle, 0.0);
		}

		public static int GetRotation(VideoHandle handle)
		{
			var degrees = 0;
			var tracks = handle.Asset.Tracks;
			foreach (var track in tracks)
			{
				if (track.MediaType.Equals(AVMediaType.Video))
				{
					var transform = track.PreferredTransform;
					var angle = Math.Atan2(transform.yx, transform.xx);
					degrees = (int)(angle * (180.0 / Math.PI));
					break;
				}
			}
			return degrees;
		}
		
		public static void Dispose(VideoHandle handle)
		{
			if (handle.AudioPlayer != null)
				handle.AudioPlayer.Dispose();
			
			if (handle.Player != null)
				handle.Player.Dispose();
			
			if (handle.PlayerItem != null)
				handle.PlayerItem.Dispose();
			
			if (handle.Output != null)
				handle.Output.Dispose();
			
			if (handle.Asset != null)
				handle.Asset.Dispose();
		}

	}


}

