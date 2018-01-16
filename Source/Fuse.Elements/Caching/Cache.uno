using Uno;
using Uno.Graphics;
using Uno.UX;
using Uno.Collections;

using Fuse.Common;
using Fuse.Nodes;

namespace Fuse.Elements
{
	internal struct CacheTile
	{
		public float4x4 _compositMatrix;
		public CacheFramebuffer _framebuffer;
		public Recti _rect;

		public texture2D Texture { get { return _framebuffer.Framebuffer.ColorBuffer; } }

		public void EnsureHasFramebuffer()
		{
			if (_framebuffer == null || _framebuffer.Width != _rect.Size.X || _framebuffer.Height != _rect.Size.Y)
			{
				if (_framebuffer != null)
					_framebuffer.Dispose();

				_framebuffer = new CacheFramebuffer(_rect.Size.X, _rect.Size.Y, Format.RGBA8888, FramebufferFlags.None);
			}
		}
	}

	internal partial class Cache
	{
		bool _isValid;

		[WeakReference]
		readonly Element _element;

		Recti _cacheRect;
		CacheTile[] _cacheTiles;

		public CacheTile[] CacheTiles { get { return _cacheTiles; } }

		public Cache(Element elm)
		{
			_element = elm;
			if (_element == null) throw new Exception();
		}

		internal void Invalidate()
		{
			_isValid = false;
		}

		internal bool DrawCached(DrawContext dc)
		{
			if (!PinAndValidate(dc))
				return false;

			bool validated = false;
			try
			{
				if defined(FUSELIBS_PROFILING)
					Profiling.LogEvent("Blitting out cache", 0);

				Blit(dc, _element.Opacity);
				validated = true;
			}
			finally
			{
				Unpin(validated);
			}
			return validated;
		}

		internal void DrawHeuristically(DrawContext dc)
		{
			if (GetCachePreference(dc))
			{
				DrawCached(dc);
			}
			else
			{
				_element.CompositEffects(dc);
			}
		}

		internal static Recti ConservativelySnapToCoveringIntegers(Rect r)
		{
			// To prevent translations from affecting the size, round off origin and size
			// separately. And because origin might be rounded down while size not, we need
			// to add one to the width to be sure.

			int2 origin = (int2)Math.Floor(r.LeftTop);
			int2 size = (int2)Math.Ceil(r.RightBottom - r.LeftTop + 0.01f);
			return new Recti(origin.X, origin.Y,
				origin.X + size.X + 1, origin.Y + size.Y + 1);
		}

		bool GetCachingRect(DrawContext dc, out Recti rect)
		{
			return GetCachingRect(_element, out rect);
		}

		static bool GetCachingRect(Element elm, out Recti rect)
		{
			var bounds = elm.RenderBoundsWithEffects;
			if (bounds.IsInfinite || bounds.IsEmpty)
			{
				rect = new Recti(0,0,0,0);
				return false;
			}

			rect = Recti.Inflate(ConservativelySnapToCoveringIntegers(Rect.Scale(bounds.FlatRect,
				elm.AbsoluteZoom)), 1);
			return true;
		}

		internal float4x4 CalculateCompositMatrix(DrawContext dc, Recti cachingRect)
		{
			float4x4 translation = Matrix.Translation(cachingRect.Left / _element.AbsoluteZoom, cachingRect.Top / _element.AbsoluteZoom, 0);
			return Matrix.Mul(translation, _element.WorldTransform);
		}

		internal int MaxTileSize { get { return Texture2D.MaxSize; } }

		private bool PinAndValidate(DrawContext dc)
		{
			Recti cacheRect;
			if (!GetCachingRect(dc, out cacheRect))
				return false;

			if (!Recti.Equals(cacheRect, _cacheRect))
			{
				// new cacheRect, re-create tiling pattern
				int numTilesX = (cacheRect.Size.X + MaxTileSize - 1) / MaxTileSize;
				int numTilesY = (cacheRect.Size.Y + MaxTileSize - 1) / MaxTileSize;
				int numTiles = numTilesX * numTilesY;

				if (_cacheTiles == null || numTiles != _cacheTiles.Length)
					_cacheTiles = new CacheTile[numTiles];

				for (int y = 0; y < numTilesY; ++y)
				{
					for (int x = 0; x < numTilesX; ++x)
					{
						int tile = x + y * numTilesX;
						int2 Position = int2(x * MaxTileSize, y * MaxTileSize);
						_cacheTiles[tile]._rect = new Recti(
							cacheRect.Left + Position.X,
							cacheRect.Top + Position.Y,
							cacheRect.Left + Position.X + Math.Min(cacheRect.Size.X - Position.X, MaxTileSize),
							cacheRect.Top + Position.Y + Math.Min(cacheRect.Size.Y - Position.Y, MaxTileSize));
					}
				}
			}

			try
			{
				for (int i = 0; i < _cacheTiles.Length; ++i)
				{
					_cacheTiles[i].EnsureHasFramebuffer();
					_cacheTiles[i]._compositMatrix = CalculateCompositMatrix(dc, _cacheTiles[i]._rect);

					_cacheTiles[i]._framebuffer.Pin();
					if (!_cacheTiles[i]._framebuffer.IsContentValid || !_isValid)
					{
						Repaint(dc, _cacheTiles[i]);
					}
				}
			}
			catch (Exception e)
			{
				// manually unpin all CacheFramebuffers
				for (int i = 0; i < _cacheTiles.Length; ++i)
				{
					if (_cacheTiles[i]._framebuffer.IsPinned)
						_cacheTiles[i]._framebuffer.Unpin(false);
				}

				throw;
			}

			_isValid = true;
			return true;
		}


		private void Unpin(bool validate)
		{
			foreach (CacheTile tile in _cacheTiles)
			{
				tile._framebuffer.Unpin(validate);
			}
		}

		void Repaint(DrawContext dc, CacheTile tile)
		{
			if defined(FUSELIBS_PROFILING)
				Profiling.LogEvent("Repainting cache", 0);

			//undo our transform and apply new camera
			var cc = new OrthographicFrustum{
				Origin = float2(tile._rect.Minimum.X, tile._rect.Minimum.Y) / _element.AbsoluteZoom,
				Size = float2(tile._rect.Size.X, tile._rect.Size.Y) / _element.AbsoluteZoom,
				LocalFromWorld = _element.WorldTransformInverse };

			var oldIsCaching = dc.IsCaching;
			dc.IsCaching = true;

			// Push
			dc.PushRenderTargetFrustum(tile._framebuffer.Framebuffer, cc);

			try
			{
				dc.Clear(float4(0), 1);

				// Render
				_element.CompositEffects(dc);
			}
			finally
			{
				// Pop
				dc.PopRenderTargetFrustum();
				dc.IsCaching = oldIsCaching;
			}
		}

		static CacheHelper cacheHelper = new CacheHelper();
		private void Blit(DrawContext dc, float opacity)
		{
			cacheHelper.Blit(dc, this, opacity);
		}
	}

	internal class CacheHelper
	{
		public void Blit(DrawContext dc, Cache cache, float opacity)
		{
			foreach (CacheTile tile in cache.CacheTiles)
			{
				var size = float2(tile.Texture.Size.X, tile.Texture.Size.Y) / dc.ViewportPixelsPerPoint;
				var localToClipTransform = Matrix.Mul(tile._compositMatrix, dc.Viewport.ViewProjectionTransform);
				Blitter.Singleton.Blit(tile.Texture, new Rect(float2(0), size), localToClipTransform, opacity, true, dc.CullFace);

				if defined(FUSELIBS_DEBUG_DRAW_RECTS)
					DrawRectVisualizer.Capture(float2(0), float2(tile.Texture.Size.X, tile.Texture.Size.Y), tile._compositMatrix, dc);
			}
		}
	}

}
