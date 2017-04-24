using Uno;
using Uno.Graphics;

namespace Fuse
{
	/** Represents a framebuffer managed by @FramebufferPool.
		@experimental */
	class CacheFramebuffer
	{
		bool _isPinned = false;

		public bool IsPinned
		{
			get
			{
				return _isPinned;
			}
		}

		void EnsurePinned()
		{
			if (!IsPinned) throw new Exception("Cannot access unpinned CacheFramebuffer");
		}

		framebuffer _fb;

		internal void Collect()
		{
			if (_fb != null) FramebufferPool.Release(_fb);
			_fb = null;
			_isContentValid = false;
		}

		public void Dispose()
		{
			Collect();
			FramebufferPool.UnRegister(this);
		}

		internal void Provide(framebuffer fb)
		{
			if (_fb != fb) _isContentValid = false;
			_fb = fb;
		}

		public framebuffer Framebuffer
		{
			get
			{
				EnsurePinned();
				return _fb;
			}
		}

		bool _isContentValid = false;
		public bool IsContentValid
		{
			get
			{
				EnsurePinned();
				return _isContentValid;
			}
		}

		public bool HasValidContentIfPinned
		{
			get
			{
				return _fb != null && _isContentValid;
			}
		}

		int _lastFrameUsed;
		internal int FramesSinceLastUse
		{
			get
			{
				return FramebufferPool.Frame - _lastFrameUsed;
			}
		}

		public void Pin()
		{
			_isPinned = true;
			_lastFrameUsed = FramebufferPool.Frame;

			if (_fb == null)
			{
				_fb = FramebufferPool.Lock(Width, Height, Format, Flags.HasFlag(FramebufferFlags.DepthBuffer));
				FramebufferPool.Register(this);
			}
		}

		public void Unpin(bool validate)
		{
			EnsurePinned();
			_isPinned = false;
			if (validate) _isContentValid = true;
			_lastFrameUsed = FramebufferPool.Frame;
		}

		public int Width { get; private set; }
		public int Height { get; private set; }
		public Format Format { get; private set; }
		public FramebufferFlags Flags { get; private set ;}

		public CacheFramebuffer(int width, int height, Format format, FramebufferFlags flags)
		{
			Width = width;
			Height = height;
			Format = format;
			Flags = flags;
		}
	}
}
