using Uno;
using Uno.Collections;
using Uno.Graphics;
using Fuse.Resources;

namespace Fuse.Elements
{
	internal interface IElementBatchDrawable
	{
		void Draw(DrawContext dc, float4x4 localToClipTransform, Rect scissorRectInClipSpace);
	}

	internal class SingleVisualDrawable : IElementBatchDrawable
	{
		Visual _elm;
		public SingleVisualDrawable(Visual elm)
		{
			_elm = elm;
		}

		public void Draw(DrawContext dc, float4x4 localToClipTransform, Rect scissorRectInClipSpace)
		{
			_elm.Draw(dc);
		}
	}

	internal class ElementBatcher : ISoftDisposable, IDisposable
	{
		List<Visual> _elements = new List<Visual>();
		List<ElementAtlas> _atlasPool = new List<ElementAtlas>();
		List<ElementBatch> _batchPool = new List<ElementBatch>();
		List<IElementBatchDrawable> _drawList = new List<IElementBatchDrawable>();
		public List<ElementBatchEntry> _reinsertCheckList = new List<ElementBatchEntry>();

		public ElementBatcher()
		{
			DisposalManager.Add(this);
			ElementAtlasFramebufferPool.AtlasSizeChanged += OnAtlasSizeChanged;
		}

		void OnAtlasSizeChanged(object sender, EventArgs args)
		{
			DiscardAtlasing();
		}

		void ISoftDisposable.SoftDispose()
		{
			DiscardAtlasing();
		}

		public void Dispose()
		{
			DiscardAtlasing();
			DiscardBatching();
			_reinsertCheckList.Clear();
			_elements.Clear();
		}

		public void AddElement(Visual elm)
		{
			_elements.Add(elm);
			DrawListValid = false;
		}

		public void RemoveAllElements()
		{
			_elements.Clear();
			DrawListValid = false;
		}

		//See the note in `Element.Batching.uno` as to why this function exists
		public void Remove(Element elm)
		{
			_elements.Remove(elm);
			for (var i=_reinsertCheckList.Count-1; i>=0; --i)
			{
				if (_reinsertCheckList[i]._elm == elm)
					_reinsertCheckList.RemoveAt(i);
			}
			DrawListValid = false;
		}

		ElementAtlas allocAtlas()
		{
			var atlas = new ElementAtlas();
			_atlasPool.Add(atlas);
			return atlas;
		}

		ElementBatch allocBatch(ElementAtlas atlas)
		{
			var batch = new ElementBatch(this, atlas);
			_batchPool.Add(batch);
			return batch;
		}

		void DiscardAtlasing()
		{
			foreach (var atlas in _atlasPool)
				atlas.Dispose();
			_atlasPool.Clear();

			foreach (var node in _elements)
			{
				var elm = node as Element;
				if (elm != null)
					elm.ElementBatchEntry = null;
			}

			_drawList.Clear();
			DrawListValid = false;
		}

		void DiscardBatching()
		{
			foreach (var batch in _batchPool)
				batch.Dispose();
			_batchPool.Clear();
		}

		static int2 MaxElementSize { get { return ElementAtlasFramebuffer.Size; } }

		static int MaxElementPixels { get { return (MaxElementSize.X * MaxElementSize.Y) / 2; } }

		public static bool ShouldBatchElementWithSize(int2 size)
		{
			var maxSize = MaxElementSize;
			return size.X <= maxSize.X &&
			       size.Y <= maxSize.Y &&
			       size.X * size.Y <= MaxElementPixels;
		}

		public static bool ShouldBatchElementWithCachingMode(CachingMode mode)
		{
			return mode != CachingMode.Never;
		}

		public static bool ShouldBatchElement(Visual node)
		{
			if (!Fuse.Internal.FuseConfig.AllowElementDrawCache)
				return false;

			var elm = node as Element;
			if (elm == null)
				return false;

			var flat = elm.AreChildrenFlat && elm.IsLocalFlat;
			if (!flat)
				return false;

			if (!ShouldBatchElementWithCachingMode(elm.CachingMode))
				return false;

			Recti cacheRect;
			if (!ElementBatch.TryGetCachingRect(elm, out cacheRect))
				return false;
			return ShouldBatchElementWithSize(cacheRect.Size);
		}

		float MaxSpilledRatio;

		void UpdateDrawList()
		{
			_drawList.Clear();
			DiscardBatching();

			int2 maxBatchRenderBounds = (int2)(DisplayHelpers.DisplaySizeHint * 2);

			ElementBatch batch = null;
			foreach (var node in _elements)
			{
				if (!ShouldBatchElement(node))
				{
					_drawList.Add(new SingleVisualDrawable(node));
					batch = null;
					continue;
				}

				var elm = (Element)node;

				bool emitNewBatch = false;
				ElementAtlas atlas = null;

				if (batch == null)
				{
					// need a new batch, check if we can reuse atlas

					emitNewBatch = true;
					if (elm.ElementBatchEntry != null)
						atlas = elm.ElementBatchEntry._atlas;
				}
				else
				{
					// check if we can reuse batch

					if (elm.ElementBatchEntry == null || elm.ElementBatchEntry._atlas == null)
					{
						atlas = batch._elementAtlas;
						if (!atlas.AddElement(elm))
							atlas = null;
					}
					else
					{
						// verify if batch is for the right atlas
						if (elm.ElementBatchEntry._atlas != batch._elementAtlas)
							emitNewBatch = true;

						atlas = elm.ElementBatchEntry._atlas;
					}
				}

				// check if batch will become too large
				if (batch != null && !emitNewBatch)
				{
					var batchRenderBounds = batch.RenderBounds;
					var elmRenderBounds = elm.CalcRenderBoundsInParentSpace();
					var newRenderBounds = batchRenderBounds.Merge(elmRenderBounds);

					if (newRenderBounds.Size.X > maxBatchRenderBounds.X ||
					    newRenderBounds.Size.Y > maxBatchRenderBounds.Y ||
					    batch.IsFull())
						emitNewBatch = true;
				}

				if (emitNewBatch || atlas == null)
				{
					// start a new batch

					// emit a new atlas if needed
					if (atlas == null)
					{
						// search for an atlas that can be used
						foreach (var a in _atlasPool)
						{
							if (a.AddElement(elm))
							{
								atlas = a;
								break;
							}
						}

						// fallback to creating a new atlas
						if (atlas == null)
							atlas = allocAtlas();
					}

					// create a new batch for the atlas, and insert element
					batch = allocBatch(atlas);
					if ((elm.ElementBatchEntry == null || elm.ElementBatchEntry._atlas != atlas) &&
					    !atlas.AddElement(elm))
					{
						// insert failed, fall back to single elements (this should never happen in reality)
						debug_log "BUG: atlas-insertion failed, but should not!";
						_drawList.Add(new SingleVisualDrawable(elm));
						batch = null;
						continue;
					}

					_drawList.Add(batch);
				}

				// add to batch
				batch.AddElement(elm);
			}

			MaxSpilledRatio = 0;
			foreach (var a in _atlasPool)
				MaxSpilledRatio = Math.Max(MaxSpilledRatio, a.SpilledRatio);
		}

		public bool DrawListValid;

		public void Draw(DrawContext dc)
		{
			if (_elements.Count < 1)
				throw new Exception("Trying to batch nothing!");

			if (MaxSpilledRatio > 0.5)
			{
				List<ElementAtlas> removeList = new List<ElementAtlas>();
				foreach (var a in _atlasPool)
					if (a.SpilledRatio > 0.5)
						removeList.Add(a);

				foreach (var node in _elements)
				{
					var elm = node as Element;
					if (elm == null)
						continue;

					foreach (var a in removeList)
						if (elm.ElementBatchEntry != null && elm.ElementBatchEntry._atlas == a)
							elm.ElementBatchEntry = null;
				}

				foreach (var a in removeList)
				{
					_atlasPool.Remove(a);
					a.Dispose();
				}

				DrawListValid = false;
			}

			foreach (var e in _reinsertCheckList)
			{
				var elm = e._elm;
				var atlas = e._atlas;

				if (elm == null || elm.ElementBatchEntry == null || atlas == null)
					continue;

				Recti cachingRect;
				if (ElementBatch.TryGetCachingRect(elm, out cachingRect))
				{
					if ((cachingRect.Size.X <= e.AtlasRect.Size.X &&
					     cachingRect.Size.Y <= e.AtlasRect.Size.Y) ||
					    atlas.ReinsertElement(elm, cachingRect))
						continue;
				}

				// remove element and force rebuild of draw-list
				atlas.RemoveElement(elm);
				elm.ElementBatchEntry = null;
				DrawListValid = false;
			}
			_reinsertCheckList.Clear();

			if (!DrawListValid)
			{
				UpdateDrawList();
				DrawListValid = true;
			}

			var parent = _elements[0].Parent;
			var localToClipTransform = dc.GetLocalToClipTransform(parent);
			var scissorRectInClipSpace = ElementAtlas.GetScissorRectInClipSpace(dc);

			foreach (var d in _drawList)
				d.Draw(dc, localToClipTransform, scissorRectInClipSpace);
		}
	}
}
