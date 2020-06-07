using Uno;
using Uno.UX;
using Fuse.Elements;


namespace Fuse.Effects
{
	public enum EffectType
	{
		Underlay,
		Composition,
		Overlay
	}

	public abstract class Effect: Node
	{
		readonly EffectType _effectType;
		public EffectType Type { get { return _effectType; } }

		protected Effect(EffectType effectType)
		{
			_effectType = effectType;
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			var elm = Parent as Element;
			if (elm == null)
				throw new Exception("Effects can only be parented to Elements");

			Element = elm;
			Element.AddDrawCost(3);
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();

			Element.RemoveDrawCost(3);
			Element = null;
		}

		public Element Element { get; private set; }


		public event Action<Effect> RenderingChanged;

		protected void OnRenderingChanged()
		{
			if (RenderingChanged != null) RenderingChanged(this);
		}


		public event Action<Effect> RenderBoundsChanged;

		protected void OnRenderBoundsChanged()
		{
			if (RenderBoundsChanged != null) RenderBoundsChanged(this);
		}

		public abstract void Render(DrawContext dc);

		public virtual bool Active { get { return true; } }

		//given the input RenderBounds return the new bounds
		public virtual VisualBounds ModifyRenderBounds( VisualBounds inBounds )
		{
			return inBounds;
		}
	}
}
