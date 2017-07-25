

namespace Fuse.Elements
{
	public partial class Element
	{
		ElementBatcher _elementBatcher;
		bool _elementBatchValid;

		bool ShouldBatch()
		{
			if (VisualChildCount < 10)
				return false;

			int batchable = 0;
			for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
			{
				if (ElementBatcher.ShouldBatchElement(v))
					batchable++;
			}

			return batchable > Children.Count / 2;
		}

		protected override void OnZOrderInvalidated()
		{
			NotifyTreeRendererZOrderChanged();
			_elementBatchValid = false;
		}

		void RemoveChildElementFromBatching(Element elm)
		{
			if (elm.ElementBatchEntry != null)
			{
				elm.ElementBatchEntry.OnRemoved();
				elm.ElementBatchEntry = null;
				_elementBatchValid = false;
			}
			
			//TODO: The `OnRemoved` should probably be sufficient, but it wasn't clear how to
			//properly restructure the memory in the batcher to make it work. So this is a kind of workaround.
			if (_elementBatcher != null)
				_elementBatcher.Remove(elm);
		}

		protected void DrawUnderlayChildren(DrawContext dc)
		{
			for (int i = 0; i < _firstNonUnderlay; i++)
				ZOrder[i].Draw(dc);
		}

		protected void DrawNonUnderlayChildren(DrawContext dc)
		{
			if (!HasChildren) return;

			EnsureSortedZOrder();

			if (!ShouldBatch())
			{
				// get rid of old element batcher
				if (_elementBatcher != null)
					_elementBatcher = null;

				for (int i = _firstNonUnderlay; i < ZOrder.Count; ++i)
					ZOrder[i].Draw(dc);
			}
			else
			{
				if (_elementBatcher == null || !_elementBatchValid)
				{
					if (_elementBatcher == null)
						_elementBatcher = new ElementBatcher();
					else
						_elementBatcher.RemoveAllElements();

					for (int i = _firstNonUnderlay; i < ZOrder.Count; ++i)
						_elementBatcher.AddElement(ZOrder[i]);

					_elementBatchValid = true;
				}
				_elementBatcher.Draw(dc);
			}
		}

		void CleanupBatching()
		{
			if (_elementBatcher != null)
			{
				_elementBatcher.Dispose();
				_elementBatcher = null;
			}
		}
		
		protected virtual void DrawWithChildren(DrawContext dc)
		{
			DrawUnderlayChildren(dc);
			OnDraw(dc);
			DrawNonUnderlayChildren(dc);
		}

		protected virtual void OnDraw(DrawContext dc)
		{
			// TODO: make abstract and rip out!
		}
	}
}
