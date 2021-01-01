using Uno.UX;

namespace Fuse.Elements
{
	public abstract partial class Element
	{
		Element AncestorElement
		{
			get
			{
				var n = Parent;
				while (n != null)
				{
					var elm = n as Element;
					if (elm != null)
						return elm;
					n = n.Parent;
				}
				return null;
			}
		}

		// --- Opacity ---
		public const float DefaultOpacity = 1.0f;
		static Selector _opacityName = "Opacity";

		[UXOriginSetter("SetOpacity")]
		/**
			The opacity of the element.

			When `0`, the element will be completely transparent, yet will still be considered for hit testing (it and it's children are still actually part of the UI). To make an element invisble without hit testing set `Visibility="Hidden"`

			@see @Element.Visibility
		*/
		public float Opacity
		{
			get { return Get(FastProperty1.Opacity, DefaultOpacity); }
			set { SetOpacity(value, this); }
		}

		public void SetOpacity(float value, IPropertyListener origin)
		{
			if (Opacity != value)
			{
				Set(FastProperty1.Opacity, value, DefaultOpacity);
				OnOpacityChanged(origin);
			}
		}
		void OnOpacityChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_opacityName, origin);
			InvalidateVisualComposition();
			NotifyTreeRedererOpacityChanged();
		}
	}
}
