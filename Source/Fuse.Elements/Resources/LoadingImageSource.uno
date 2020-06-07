using Uno;
using Uno.Graphics;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Resources
{
	abstract class LoadingImageSource : ImageSource, IMemoryResource
	{
		protected enum CleanupReason
		{
			Normal,
			Failed,
			Disposed,
		}

		MemoryPolicy IMemoryResource.MemoryPolicy { get { return Policy; } }
		bool IMemoryResource.IsPinned { get { return IsPinned; } }
		double _lastUsed;
		double IMemoryResource.LastUsed { get { return _lastUsed; } }
		void IMemoryResource.SoftDispose()
		{
			Cleanup( CleanupReason.Disposed );
		}

		protected void MarkUsed()
		{
			_lastUsed = Time.FrameTime;
		}

		MemoryPolicy _policy = MemoryPolicy.PreloadRetain;
		public MemoryPolicy Policy
		{
			get { return _policy; }
			set
			{
				if (value == null)
					throw new Exception( "value-cannot-be-null" );
				_policy = value;
			}
		}

		texture2D _texture;
		byte[] _bytes;
		//can retain size even if texture is unloaded
		int2 _textureSize;
		protected bool _loading;
		protected bool _failed;

		internal new bool TestIsClean
		{
			get { return _texture == null && !_loading; }
		}

		public override texture2D GetTexture()
		{
			if (_texture != null)
			{
				MarkUsed();
				return _texture;
			}

			LoadImage();
			return _texture;
		}

		public override byte[] GetBytes()
		{
			if (_bytes != null)
			{
				MarkUsed();
				return _bytes;
			}

			LoadImage();
			return _bytes;
		}

		void LoadImage()
		{
			if (_loading || _failed)
				return;

			AttemptLoad();
		}

		public override void Reload()
		{
			Cleanup( CleanupReason.Normal );
			LoadImage();
		}

		protected void ChangePrep()
		{
			Cleanup( CleanupReason.Normal );
		}

		bool _inDisposal;
		protected void Cleanup( CleanupReason reason )
		{
			if (_texture != null)
			{
				_texture.Dispose();
				_texture = null;
			}
			if (_bytes != null)
			{
				_bytes = null;
			}
			_textureSize = int2(0);
			_loading = false;
			_failed = reason == CleanupReason.Failed;

			if (_inDisposal)
				DisposalManager.Remove(this);
			_inDisposal = false;

			//disposed doesn't need to trigger a change, this lets disposed images stay on screen (they might
			//be cached, so allowing cleanup is sometimes helpful)
			if (reason != CleanupReason.Disposed)
				OnChanged();
		}

		protected bool IsLoaded { get { return _texture != null; } }

		protected void SetTexture( texture2D texture )
		{
			_texture = texture;
			_textureSize = texture.Size;

			if (!_inDisposal)
			{
				DisposalManager.Add( this );
				_inDisposal = true;
			}
			MarkUsed();
			OnChanged();
		}

		protected void SetBytes( byte[] bytes )
		{
			_bytes = bytes;
		}

		public override ImageSourceState State
		{
			get
			{
				if (_texture != null)
					return ImageSourceState.Ready;
				if (_failed)
					return ImageSourceState.Failed;
				if (_loading)
					return ImageSourceState.Loading;
				return ImageSourceState.Pending;
			}
		}

		protected float _density = 1;
		public override float SizeDensity
		{
			get { return _density; }
		}

		public override float2 Size
		{
			get
			{
				var ts = PixelSize;
				return float2(ts.X,ts.Y)/_density;
			}
		}

		public override int2 PixelSize
		{
			get
			{
				//must trigger load on Size request, since 0-layout size may result in GetTexture never being called
				if (_texture == null)
					LoadImage();
				MarkUsed();
				return _textureSize;
			}
		}

		protected override void OnPinChanged()
		{
			base.OnPinChanged();
			//disposal timeout should start after unpinning
			MarkUsed();
		}

		protected abstract void AttemptLoad();
	}
}
