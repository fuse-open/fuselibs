using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using Fuse.Resources;

namespace Fuse
{
	public static class FramebufferPool
	{
		static FramebufferPoolImpl framebufferPool;

		static void EnsurePool() { if (framebufferPool == null) framebufferPool = new FramebufferPoolImpl(); }

		internal static void Register(CacheFramebuffer cfb)
		{
			EnsurePool();
			framebufferPool.Register(cfb);
		}

		internal static void UnRegister(CacheFramebuffer cfb)
		{
			EnsurePool();
			framebufferPool.UnRegister(cfb);
		}

		public static framebuffer Lock(int2 size, Format format, bool depth)
		{
			return Lock(size.X, size.Y, format, depth);
		}
		public static framebuffer Lock(int width, int height, Format format, bool depth)
		{
			EnsurePool();
			return framebufferPool.Lock(width, height, format, depth);
		}

		public static void Release(framebuffer fb)
		{
			EnsurePool();
			framebufferPool.Release(fb);
		}

		internal static int Frame
		{
			get
			{
				EnsurePool();
				return framebufferPool.frame;
			}
		}
		
		/** `true` if there are no framebuffers that still need to be released */
		internal static bool TestIsLockedClean
		{
			get { return framebufferPool == null ? true : framebufferPool.IsLockedClean; }
		}
	}

	[extern(ANDROID) Require("Source.Include", "Uno/Graphics/GLHelper.h")]
	internal class FramebufferPoolImpl : ISoftDisposable
	{
		public FramebufferPoolImpl()
		{
			UpdateManager.AddAction(Update);
			DisposalManager.Add(this);
		}

		internal int frame = 0;

		// Holds framebuffers not currently in use and tracks how long they've been unused
		List<framebuffer> framebufferPool = new List<framebuffer>();
		Dictionary<framebuffer, int> lastFrameUsed = new Dictionary<framebuffer, int>();

		// Holds framebuffers currenlty locked by Lock()
		HashSet<framebuffer> lockedFramebuffers = new HashSet<framebuffer>();

		List<CacheFramebuffer> cacheFramebuffers = new List<CacheFramebuffer>();

		internal bool IsLockedClean
		{
			get { return lockedFramebuffers.Count == 0; }
		}
		
		// Finds a free buffer from the framebuffer pool
		framebuffer FindBuffer(int width, int height, Uno.Graphics.Format format, FramebufferFlags flags)
		{
			width = Math.Max(1, width);
			height = Math.Max(1, height);
			for (int i = 0; i < framebufferPool.Count; i++)
			{
				var fb = framebufferPool[i];
				if (fb.Size.X != width) continue;
				if (fb.Size.Y != height) continue;
				if (fb.Format != format) continue;
				if (fb.HasDepth != flags.HasFlag(FramebufferFlags.DepthBuffer)) continue;
				if (fb.ColorBuffer.IsMipmap != flags.HasFlag(FramebufferFlags.Mipmap)) continue;

				framebufferPool.RemoveAt(i);
				lockedFramebuffers.Add(fb);
				lastFrameUsed[fb] = frame;

				return fb;
			}

			int maxSize = texture2D.MaxSize;
			if (width > maxSize || height > maxSize)
			{
				throw new Exception("Attempted to allocate " + width + "x" + height + " framebuffer, max is " + maxSize + "x" + maxSize);
			}

			extern double t = 0.0;
			if defined(FUSELIBS_PROFILING)
				t = Uno.Diagnostics.Clock.GetSeconds();

			var buffer = new framebuffer(int2(width, height), format, flags);

			if defined(FUSELIBS_PROFILING)
				Fuse.Profiling.NewFramebuffer(buffer, Uno.Diagnostics.Clock.GetSeconds() - t);

			return buffer;
		}

		int framebuffersProvidedSinceLastCollect = 0;
		int pixelsProvidedSinceLastCollect = 0;

		internal void Register(CacheFramebuffer cfb)
		{
			framebuffersProvidedSinceLastCollect += 1;
			pixelsProvidedSinceLastCollect += cfb.Width * cfb.Height;

			cacheFramebuffers.Add(cfb);

			if (pixelsProvidedSinceLastCollect > 1000000)
			{
				CollectCacheFramebuffers();
			}
			else if (framebuffersProvidedSinceLastCollect > 50)
			{
				CollectCacheFramebuffers();
			}
		}

		internal void UnRegister(CacheFramebuffer cfb)
		{
			framebuffersProvidedSinceLastCollect = 0;
			//pixelsProvidedSinceLastCollect -= cfb.Width * cfb.Height;
			cacheFramebuffers.Remove(cfb);
		}

		void CollectCacheFramebuffers()
		{
			if (cacheFramebuffers.Count < 3) return;

			// Calculate average time since last use
			int sum = 0;
			foreach (var cfb in cacheFramebuffers)
			{
				sum += cfb.FramesSinceLastUse;
			}

			int avg = sum / cacheFramebuffers.Count;

			// Collect all buffers older than 3 frames more than the average
			int limit = avg + 3;

			for (int i = 0; i < cacheFramebuffers.Count; i++)
			{
				var c = cacheFramebuffers[i];

				if (!c.IsPinned && c.FramesSinceLastUse >= limit)
				{
					c.Collect();
					cacheFramebuffers.RemoveAt(i--);
				}
			}

			framebuffersProvidedSinceLastCollect = 0;
			pixelsProvidedSinceLastCollect = 0;
		}

		void ISoftDisposable.SoftDispose()
		{
			for (int i = 0; i < cacheFramebuffers.Count; i++)
			{
				var c = cacheFramebuffers[i];
				if (c.IsPinned)
					throw new Exception("framebuffer pinned while app going into the background");

				c.Collect();
				cacheFramebuffers.RemoveAt(i--);
			}

			for (int i = 0; i < framebufferPool.Count; i++)
			{
				var fb = framebufferPool[i];

				fb.Dispose();
				framebufferPool.RemoveAt(i--);
				lastFrameUsed.Remove(fb);
			}
		}

		internal framebuffer Lock(int width, int height, Uno.Graphics.Format format, bool depth)
		{
			var fb = FindBuffer(width, height, format, depth ? FramebufferFlags.DepthBuffer : FramebufferFlags.None);
			lastFrameUsed[fb] = frame;
			lockedFramebuffers.Add(fb);
			return fb;
		}

		internal void Release(framebuffer fb)
		{
			if (lockedFramebuffers.Contains(fb))
			{
				lockedFramebuffers.Remove(fb);
				lastFrameUsed[fb] = frame;
				framebufferPool.Add(fb);
			}
		}

		public void Update()
		{
			extern bool contextBound = false;
			frame++;

			for (int i = 0; i < framebufferPool.Count; i++)
			{
				var fb = framebufferPool[i];

				//var framesSinceUse = frame - lastFrameUsed[fb];

				// Note: Workaround for mobile rotation bug
				int framesSinceUse;
				lastFrameUsed.TryGetValue(fb, out framesSinceUse);
				framesSinceUse = frame - framesSinceUse;

				if (framesSinceUse < 0)
					throw new Exception("Pool is leaking");
				if (framesSinceUse > 1)
				{
					// We've had issues on Android with getting here without an OpenGL ES context bound,
					// so let's make sure we have a context bound before calling fb.Dispose, which is
					// releasing textures.
					//
					// This is still not quite correct, though. Because framebuffer objects are not shared
					// on all devices, the FBO should have been released from the context that was used
					// to create it. And that's not the background-surface.

					if defined(Android)
					{
						if (!contextBound)
						{
							extern "GLHelper::SwapBackToBackgroundSurface()";
							contextBound = true;
						}
					}

					//debug_log "disposing buffer " + fb.Size.X + "x" + fb.Size.Y;
					fb.Dispose();

					framebufferPool.RemoveAt(i--);
					lastFrameUsed.Remove(fb);
				}
			}
		}
	}
}
