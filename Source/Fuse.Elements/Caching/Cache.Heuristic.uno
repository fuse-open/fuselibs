using Uno;
using Uno.Graphics;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Elements
{
	internal partial class Cache
	{
		//NOTE: ElementBatcher.ShouldBatchElement does about the same logic. Any change here should
		//probably be made there as well.
		bool GetCachePreference(DrawContext dc)
		{
			if (!Fuse.Internal.FuseConfig.AllowElementDrawCache)
				return false;

			Recti cachingRect;
			if (!GetCachingRect(dc, out cachingRect))
				return false;
				
			switch (_element.CachingMode)
			{
				case CachingMode.Never:
					if defined(FUSELIBS_PROFILING)
						Profiling.LogEvent("Not caching: CachingMode.Never", 0);
					return false;
				case CachingMode.Always:
					if defined(FUSELIBS_PROFILING)
						Profiling.LogEvent("caching: CachingMode.Always", 0);
					return true;
			}

			if (cachingRect.Size.X > dc.RenderTarget.Size.X * 1.2 ||
			    cachingRect.Size.Y > dc.RenderTarget.Size.Y * 1.2)
			{
				if defined(FUSELIBS_PROFILING)
					Profiling.LogEvent("Not caching: Too big caching rect", 0);
				return false;
			}

			if (_element.Parent is RootViewport)
			{
				// Ultimate root - should never cache, because this is handled by the fact that the render loop
				// is disabled when the root node is not dirty

				// TODO: When caret/text selection etc is moved to an overlay layer, the ultimate root should
				// cache when the caret is active
			}
			else if (_element.Parent == null)
			{
				// Inner UI root - should cache if it has valid frames

				return GetCachePreferenceCore(dc);
			}
			else
			{
				if (_element.DrawCost > 1)
					return GetCachePreferenceCore(dc);
				else if defined(FUSELIBS_PROFILING)
					Profiling.LogEvent("Not caching: Redraw cheap", 0);
			}

			return false;
		}

		bool GetCachePreferenceCore(DrawContext dc)
		{
			if (_element.ValidFrameCount > 0)
			{
				if (!dc.IsCaching)
				{
					if defined(FUSELIBS_PROFILING)
						Profiling.LogEvent("caching: Nothing prevented caching", 0);
					return true;
				}
				else if defined(FUSELIBS_PROFILING)
					Profiling.LogEvent("Not caching: Already caching", 0);
			} else if defined(FUSELIBS_PROFILING)
				Profiling.LogEvent("Not caching: Visual invalid", 0);
			return false;
		}
	}
}
