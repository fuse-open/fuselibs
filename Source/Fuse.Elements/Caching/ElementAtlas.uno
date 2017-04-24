using Fuse.Internal;
using Uno;
using Uno.Collections;
using Uno.Graphics;

namespace Fuse.Elements
{
	internal class ElementAtlas
	{
		public readonly RectPacker _rectPacker;
		public readonly ElementAtlasFramebuffer _framebuffer;

		public int _invalidElements;
		int _spilledPixels;

		public float SpilledRatio { get { return (float)_spilledPixels / (_rectPacker.Size.X * _rectPacker.Size.Y); } }

		readonly List<Element> _elements = new List<Element>();

		public ElementAtlas()
		{
			_framebuffer = new ElementAtlasFramebuffer();
			_framebuffer.FramebufferCollected += OnFramebufferCollected;
			_rectPacker = new RectPacker(ElementAtlasFramebuffer.Size);
		}

		public void Dispose()
		{
			_framebuffer.FramebufferCollected -= OnFramebufferCollected;
			_framebuffer.Dispose();
		}

		void OnFramebufferCollected(object sender, EventArgs eventArgs)
		{
			foreach (var elm in _elements)
				InvalidateElement(elm);
		}

		internal void InvalidateElement(Element elm)
		{
			var entry = elm.ElementBatchEntry;
			if (entry == null)
				return;

			if (entry.IsValid)
			{
				_invalidElements++;
				entry.IsValid = false;
			}
		}

		public bool AddElement(Element elm)
		{
			Recti cacheRect;
			if (!Cache.GetCachingRect(elm, out cacheRect))
				return false;
			Recti rect;
			if (!_rectPacker.TryAdd(cacheRect.Size, out rect))
				return false;

			if (elm.ElementBatchEntry == null)
				elm.ElementBatchEntry = new ElementBatchEntry(elm);

			var entry = elm.ElementBatchEntry;
			if (entry._atlas != null)
				entry._atlas.RemoveElement(elm);
			entry._atlas = this;
			entry._rect = rect;
			_elements.Add(elm);

			_invalidElements++;
			entry.IsValid = false;
			return true;
		}

		public void RemoveElement(Element elm)
		{
			var entry = elm.ElementBatchEntry;

			if (entry._atlas != this)
				throw new Exception("Removing from wrong atlas");

			_spilledPixels += entry._rect.Area;

			if (!entry.IsValid)
			{
				_invalidElements--;
			}

			_elements.Remove(elm);
			entry._atlas = null;
		}

		public bool ReinsertElement(Element elm)
		{
			if (elm.ElementBatchEntry == null)
				throw new Exception("element not already inserted anywhere!");

			var entry = elm.ElementBatchEntry;

			if (entry._atlas != this)
				throw new Exception("wrong atlas again, dummy!");

			Recti cacheRect;
			if (!Cache.GetCachingRect(elm, out cacheRect))
				return false;
			Recti rect;
			if (!_rectPacker.TryAdd(cacheRect.Size, out rect))
				return false;

			_spilledPixels += entry._rect.Area;
			entry._rect = rect;
			if (entry.IsValid)
			{
				_invalidElements++;
				entry.IsValid = false;
			}

			return true;
		}

		static float2 WindowCoordToClipSpace(float2 input, int2 viewportSize)
		{
			return (input / viewportSize) * 2 - 1;
		}

		static Rect WindowRectToClipSpace(Rect input, int2 viewportSize)
		{
			float2 leftTop = WindowCoordToClipSpace(input.LeftTop, viewportSize);
			float2 rightBottom = WindowCoordToClipSpace(input.RightBottom, viewportSize);
			// TODO: figure out why we need to negate these!
			return Rect.ContainingPoints(float2(leftTop.X, -leftTop.Y),
			                             float2(rightBottom.X, -rightBottom.Y));
		}

		public static Rect GetScissorRectInClipSpace(DrawContext dc)
		{
			return WindowRectToClipSpace(dc.Scissor, dc.GLViewportPixelSize);
		}

		public framebuffer PinAndValidateFramebuffer(DrawContext dc)
		{
			var fb = _framebuffer.Pin();

			if (_invalidElements > 0)
			{
				Rect scissorRectInClipSpace = GetScissorRectInClipSpace(dc);
				dc.PushRenderTarget(fb);

				bool drawAll = _invalidElements == _elements.Count;
				if (drawAll)
				{
					dc.Clear(float4(0), 1);
					FillFramebuffer(dc, true, scissorRectInClipSpace);
				} else
					FillFramebuffer(dc, false, scissorRectInClipSpace);

				dc.PopRenderTarget();
			}
			return fb;
		}

		public void Unpin()
		{
			_framebuffer.Unpin();
		}

		void FillFramebuffer(DrawContext dc, bool drawAll, Rect scissorRectInClipSpace)
		{
			var density = dc.ViewportPixelsPerPoint;
			var viewport = (float2)_rectPacker.Size / density;
			foreach (var elm in _elements)
			{
				var entry = elm.ElementBatchEntry;
				if (!entry.IsValid || drawAll)
				{
					var localToClipTransform = dc.GetLocalToClipTransform(elm);
					Rect visibleRect = Rect.Transform(elm.RenderBoundsWithEffects.FlatRect, localToClipTransform);
					if (!scissorRectInClipSpace.Intersects(visibleRect))
						continue;

					var cachingRect =ElementBatch.GetCachingRect(elm);
					var offset = (float2)(entry._rect.Minimum - cachingRect.Minimum) / density;
					var translation = Matrix.Translation(offset.X, offset.Y, 0);
					var cc = new OrthographicFrustum{
						Origin = float2(0, 0), Size = viewport,
						LocalFromWorld = Matrix.Mul(elm.WorldTransformInverse, translation) };

					dc.PushViewport( new FixedViewport(_rectPacker.Size, density, cc));

					dc.PushScissor(entry._rect);

					if (!drawAll)
						dc.Clear(float4(0), 1);

					elm.CompositEffects(dc);

					dc.PopScissor();
					dc.PopViewport();

					if (!entry.IsValid)
						_invalidElements--;
					entry.IsValid = true;
				}
			}
		}
	}
}
