

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
			var zOrder = GetCachedZOrder();
			for (var i = 0; i < zOrder.Length; i++) 
			{
				var v = zOrder[i];
				if (v.Layer != Layer.Underlay) return;
				v.Draw(dc);
			}
		}

		protected void DrawNonUnderlayChildren(DrawContext dc)
		{
			if (!HasChildren) return;

			var zOrder = GetCachedZOrder();
			if (!ShouldBatch())
			{
				// get rid of old element batcher
				if (_elementBatcher != null)
					_elementBatcher = null;

				for (var i = 0; i < zOrder.Length; i++) 
				{
					var v = zOrder[i];
					if (v.Layer == Layer.Underlay) continue;
					v.Draw(dc);
				}
			}
			else
			{
				if (_elementBatcher == null || !_elementBatchValid)
				{
					if (_elementBatcher == null)
						_elementBatcher = new ElementBatcher();
					else
						_elementBatcher.RemoveAllElements();

					for (var i = 0; i < zOrder.Length; i++) 
					{
						var v = zOrder[i];
						if (v.Layer == Layer.Underlay) continue;
						_elementBatcher.AddElement(v);
					}

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
