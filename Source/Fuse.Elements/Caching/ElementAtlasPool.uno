using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using Fuse.Resources;

namespace Fuse.Elements
{
	internal class ElementAtlasFramebuffer
	{
		LinkedListNode<ElementAtlasFramebufferPoolEntry> _fb;
		internal bool Pinned { get; private set; }

		public void Dispose()
		{
			if (_fb != null)
				Collect();
		}

		internal framebuffer Pin()
		{
			if (Pinned)
				throw new Exception("ElementAtlasFramebuffer already pinned");

			Pinned = true;

			if (_fb == null)
			{
				var fb = ElementAtlasFramebufferPool.FindFramebuffer();

				// update owner
				if (fb.Value.Owner != null)
					fb.Value.Owner.Collect();
				fb.Value.Owner = this;
				_fb = fb;
			} else
				_fb.Value.Pool.UpdateUsage(_fb);

			return _fb.Value.Framebuffer;
		}

		internal void Unpin()
		{
			if (!Pinned)
				throw new Exception("ElementAtlasFramebuffer not already pinned");

			Pinned = false;
		}

		internal event EventHandler FramebufferCollected;

		internal void Collect()
		{
			if (Pinned)
				throw new Exception("Cannot Collect while pinned!");

			if (FramebufferCollected != null)
				FramebufferCollected(this, new EventArgs());

			_fb.Value.Owner = null;
			_fb = null;
		}

		public static int2 Size { get { return ElementAtlasFramebufferPool.ElementAtlasSize; } }
	}

	class ElementAtlasFramebufferPoolEntry
	{
		public ElementAtlasFramebufferPoolImpl Pool;
		public framebuffer Framebuffer;
		public ElementAtlasFramebuffer Owner;

		public void Collect()
		{
			if (Owner != null)
				Owner.Collect();
		}

		public void Dispose()
		{
			if (Framebuffer != null)
			{
				Framebuffer.Dispose();
				Framebuffer = null;
			}
		}
	}

	static class DisplayHelpers
	{
		public static int2 DisplaySizeHint
		{
			get
			{
				if defined(MOBILE)
					return (int2)Fuse.Platform.SystemUI.Frame.Size;
				else
					return int2(0);
			}
		}
	}

	static class ElementAtlasFramebufferPool
	{
		static bool _isInitialized;
		public static void Initialize()
		{
			if (_isInitialized)
				return;

			UpdateElementAtlasSize();

			if defined(MOBILE)
				Fuse.Platform.SystemUI.FrameChanged += OnResized;
			else
				Uno.Application.Current.Window.Resized += OnResized;

			_isInitialized = true;
		}

		public static event EventHandler AtlasSizeChanged;

		static void UpdateElementAtlasSize()
		{
			var maxTextureSize = Texture2D.MaxSize;
			if (maxTextureSize < 1)
				throw new Exception("zero-sized Texture2D.MaxSize");

			var displaySizeHint = DisplayHelpers.DisplaySizeHint;
			if (displaySizeHint.X < 1 ||
			    displaySizeHint.Y < 1)
			{
				displaySizeHint = int2(2048);
			}

			ElementAtlasSize = int2(Math.Min((displaySizeHint.X * 3) / 2, maxTextureSize),
			                        Math.Min(displaySizeHint.Y / 2, maxTextureSize));
		}

		static void OnResized(object sender, EventArgs args)
		{
			UpdateElementAtlasSize();
		}

		static int2 _elementAtlasSize;
		public static int2 ElementAtlasSize {
			get
			{
				Initialize();
				return _elementAtlasSize;
			}
			private set
			{
				if (_elementAtlasSize != value)
				{
					_elementAtlasSize = value;

					if (AtlasSizeChanged != null)
						AtlasSizeChanged(null, new EventArgs());
				}
			}
		}

		static ElementAtlasFramebufferPoolImpl _poolImpl;

		static void EnsurePool()
		{
			if (_poolImpl != null)
				return;

			Initialize();

			// create framebuffer pool
			_poolImpl = new ElementAtlasFramebufferPoolImpl();
		}

		public static LinkedListNode<ElementAtlasFramebufferPoolEntry> FindFramebuffer()
		{
			EnsurePool();
			return _poolImpl.FindFramebuffer();
		}
	}

	class ElementAtlasFramebufferPoolImpl : ISoftDisposable
	{
		LinkedList<ElementAtlasFramebufferPoolEntry> _framebufferPool;

		internal ElementAtlasFramebufferPoolImpl()
		{
			DisposalManager.Add(this);
			ElementAtlasFramebufferPool.AtlasSizeChanged += OnAtlasSizeChanged;
		}

		[Require("Source.Include", "Uno/Graphics/GLHelper.h")]
		extern(ANDROID)
		void DiscardPool()
		{
			extern "GLHelper::SwapBackToBackgroundSurface()";

			var pool = _framebufferPool;
			if (pool == null)
				return;

			var curr = pool.First;
			while (curr != null)
			{
				var fb = curr.Value;

				fb.Collect();
				fb.Dispose();

				curr = curr.Next;
			}

			pool.Clear();
			_framebufferPool = null;
		}

		extern(!ANDROID)
		void DiscardPool()
		{
			var pool = _framebufferPool;
			if (pool == null)
				return;

			var curr = pool.First;
			while (curr != null)
			{
				var fb = curr.Value;

				fb.Collect();
				fb.Dispose();

				curr = curr.Next;
			}

			pool.Clear();
			_framebufferPool = null;
		}

		void OnAtlasSizeChanged(object sender, EventArgs eventArgs)
		{
			DiscardPool();
		}

		void ISoftDisposable.SoftDispose()
		{
			DiscardPool();
		}

		void EnsurePool()
		{
			if (_framebufferPool != null)
				return;

			_framebufferPool = new LinkedList<ElementAtlasFramebufferPoolEntry>();
			for (int i = 0; i < 20; ++i)
				AddEntry();
		}

		LinkedListNode<ElementAtlasFramebufferPoolEntry> AddEntry()
		{
			var entry = new ElementAtlasFramebufferPoolEntry();
			entry.Pool = this;
			entry.Framebuffer = new framebuffer(ElementAtlasFramebufferPool.ElementAtlasSize, Format.RGBA8888, FramebufferFlags.None);
			return _framebufferPool.AddLast(entry);
		}

		internal LinkedListNode<ElementAtlasFramebufferPoolEntry> FindFramebuffer()
		{
			EnsurePool();

			// find most recently used
			var fb = _framebufferPool.Last;
			while (fb != null && (fb.Value.Owner != null && fb.Value.Owner.Pinned))
				fb = fb.Previous;

			if (fb == null)
				fb = AddEntry();

			UpdateUsage(fb);
			return fb;
		}

		internal void UpdateUsage(LinkedListNode<ElementAtlasFramebufferPoolEntry> fb)
		{
			_framebufferPool.Remove(fb);
			_framebufferPool.AddFirst(fb);
		}
	}
}
