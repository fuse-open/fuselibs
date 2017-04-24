using Uno;
using Uno.UX;

namespace Fuse.Effects
{
	//only public for some demos
	public abstract class BasicEffect : Effect
	{
		protected BasicEffect(EffectType effectType)
			: base(effectType)
		{
		}
		
		public override void Render(DrawContext dc)
		{
			var rect = GetLocalElementRect();
			OnRender(dc, rect);
		}
		
		protected abstract void OnRender(DrawContext dc, Rect region);
		
		internal static Recti ConservativelySnapToCoveringIntegers(Rect r)
		{
			// To prevent translations from affecting the size, round off origin and size
			// separately. And because origin might be rounded down while size not, we need
			// to add one to the width to be sure.

			int2 origin = (int2)Math.Floor(r.LeftTop);
			int2 size = (int2)Math.Ceil(r.RightBottom - r.LeftTop + 0.01f);
			return new Recti(origin.X,	origin.Y,
				origin.X + size.X + 1, origin.Y + size.Y + 1);
		}

		protected Rect GetLocalElementRect()
		{
			var ir = ConservativelySnapToCoveringIntegers(
				Rect.Scale(Element.RenderBoundsWithoutEffects.FlatRect, Element.AbsoluteZoom)); 
			return new Rect(ir.Minimum.X/Element.AbsoluteZoom,
				ir.Minimum.Y/Element.AbsoluteZoom,
				ir.Maximum.X/Element.AbsoluteZoom,
				ir.Maximum.Y/Element.AbsoluteZoom);
		}
	}
}
