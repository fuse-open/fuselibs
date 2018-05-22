using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.UX;

using Fuse.Controls;
using Fuse.Drawing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class ElementTreeRendererTest : TestBase
	{
		[Test]
		[Ignore("Needs a Surface backend", "HOST_WINDOWS && NATIVE")]
		//https://github.com/fuse-open/fuselibs/issues/1005
		public void PathDataChanged()
		{
			var p = new global::UX.ElementTreeRenderer.PathRenderBounds();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				var q = p.a.RenderBoundsWithoutEffects; //grab them, otherwise a change won't trigger
				p.Reset();
				p.a.Data = "M0,0 L100,100";
				root.StepFrame(); //dispatch is done as part of layout, thus PumpDeferred is not enough
				
				Assert.IsTrue( p.RenderBoundsChangedElements.Contains( p.a ) );
			}
		}	
	}
	
	public class TreeRendererPanel : Panel, ITreeRenderer
	{
		public override ITreeRenderer TreeRenderer
		{
			get { return this; }
		}
		
		void ITreeRenderer.RootingStarted(Element e) { }
		void ITreeRenderer.Rooted(Element e) { }
		void ITreeRenderer.Unrooted(Element e) { }
		void ITreeRenderer.BackgroundChanged(Element e, Brush background) { }
		void ITreeRenderer.TransformChanged(Element e) { }
		void ITreeRenderer.Placed(Element e) { }
		void ITreeRenderer.IsVisibleChanged(Element e, bool isVisible) { }
		void ITreeRenderer.IsEnabledChanged(Element e, bool isEnabled) { }
		void ITreeRenderer.OpacityChanged(Element e, float opacity) { }
		void ITreeRenderer.ClipToBoundsChanged(Element e, bool clipToBounds) { }
		void ITreeRenderer.ZOrderChanged(Element e, Visual[] zorder) { }
		void ITreeRenderer.HitTestModeChanged(Element e, bool enabled) { }
		
		public HashSet<Element> RenderBoundsChangedElements = new HashSet<Element>();
		void ITreeRenderer.RenderBoundsChanged(Element e) 
		{ 
			RenderBoundsChangedElements.Add( e );
		}
		
		bool ITreeRenderer.Measure(Element e, LayoutParams lp, out float2 size) 
		{ 
			size = float2(0);
			return false;
		}
		
		public void Reset()
		{
			RenderBoundsChangedElements.Clear();
		}
	}
	
}

