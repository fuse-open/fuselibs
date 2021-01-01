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
			Recti cacheRect = ElementBatch.GetCachingRect(elm);

			Recti rect;
			if (!_rectPacker.TryAdd(cacheRect.Size, out rect))
				return false;

			if (elm.ElementBatchEntry == null)
				elm.ElementBatchEntry = new ElementBatchEntry(elm);

			var entry = elm.ElementBatchEntry;
			if (entry._atlas != null)
				entry._atlas.RemoveElement(elm);
			entry._atlas = this;
			entry.AtlasRect = rect;
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

			_spilledPixels += entry.AtlasRect.Area;

			if (!entry.IsValid)
			{
				_invalidElements--;
			}

			_elements.Remove(elm);
			entry._atlas = null;
		}

		public bool ReinsertElement(Element elm, Recti cacheRect)
		{
			if (elm.ElementBatchEntry == null)
				throw new Exception("element not already inserted anywhere!");

			var entry = elm.ElementBatchEntry;

			if (entry._atlas != this)
				throw new Exception("wrong atlas again, dummy!");

			Recti rect;
			if (!_rectPacker.TryAdd(cacheRect.Size, out rect))
				return false;

			_spilledPixels += entry.AtlasRect.Area;
			entry.AtlasRect = rect;
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
			try
			{
				if (_invalidElements > 0)
				{
					Rect scissorRectInClipSpace = GetScissorRectInClipSpace(dc);
					bool drawAll = _invalidElements == _elements.Count;
					FillFramebuffer(dc, fb, drawAll, scissorRectInClipSpace);
				}

				return fb;
			}
			catch (Exception e)
			{
				_framebuffer.Unpin();
				throw;
			}
		}

		public void Unpin()
		{
			_framebuffer.Unpin();
		}

		void FillFramebuffer(DrawContext dc, framebuffer fb, bool drawAll, Rect scissorRectInClipSpace)
		{
			// Changing the framebuffer is expensive. This loop actually doesn't draw anything in
			// common case. Don't push the render target unless we actually have to render something.
			// Note: _invalidElements may also be >0 after FillFramebuffer is called
			// because we only repaint elements that are visible in the scissor rectangle
			// This means that (_invalidElements > 0) doesn't imply that any painting is actually
			// going to happen this frame
			var framebufferPushed = false;

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

					var cachingRect = ElementBatch.GetCachingRect(elm);
					var offset = (float2)(entry.AtlasRect.Minimum - cachingRect.Minimum) / density;
					var translation = Matrix.Translation(offset.X, offset.Y, 0);
					var cc = new OrthographicFrustum{
						Origin = float2(0, 0), Size = viewport,
						LocalFromWorld = Matrix.Mul(elm.WorldTransformInverse, translation) };

					if (!framebufferPushed)
					{
						dc.PushRenderTarget(fb);
						if (drawAll) dc.Clear(float4(0), 1);
						framebufferPushed = true;
					}

					dc.PushViewport( new FixedViewport(_rectPacker.Size, density, cc));

					var scissor = entry.AtlasRect;
					if (elm.ClipToBounds)
						scissor = elm.GetVisibleViewportInvertPixelRect(dc, elm.RenderBoundsWithEffects);

					dc.PushScissor(scissor);

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

			if (framebufferPushed)
				dc.PopRenderTarget();
		}
	}
}
