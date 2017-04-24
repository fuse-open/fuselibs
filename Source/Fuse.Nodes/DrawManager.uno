using Uno;

namespace Fuse.Internal
{
	static class DrawManager
	{
		static public event Action<DrawContext> Prepared;
		
		static public void PrepareDraw(DrawContext dc)
		{
			dc.CaptureRootbuffer();
			
			var p = Prepared;
			if (p != null)	
				p(dc);
		}
		
		static public void EndDraw(DrawContext dc)
		{
			dc.OnRenderTargetChange();
			dc.ReleaseRootbuffer();
		}
	}
}
