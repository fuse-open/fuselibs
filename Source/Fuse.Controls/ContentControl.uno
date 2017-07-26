using Uno;
using Uno.Platform;
using Uno.UX;
using Fuse.Input;
using Fuse.Animations;
using Fuse.Drawing;
using Fuse.Elements;

namespace Fuse.Controls
{
	/** Content controls display a single visual child.

		@topic Content controls

		## Available content controls
		[subclass Fuse.Controls.ContentControl]
	*/
	public class ContentControl : Control
	{
		public Element Content
		{
			get 
			{ 
				return FirstVisualChild as Element;
			}
			set
			{
				if (Content != value)
				{
					if (Content != null) Children.Remove(Content);
					if (value != null) Children.Add(value);
				}
			}
		}

		protected virtual void OnContentChanged()
		{
			InvalidateLayout();
		}

		protected override void OnChildAdded(Node n)
		{
			base.OnChildAdded(n);
			if (n is Visual)
			{	
				if (VisualChildCount > 1)
				{
					throw new Exception(this + " (ContentControl) can only have one visual child");
				}
				OnContentChanged();
			}
		}

		protected override void OnChildRemoved(Node n)
		{
			base.OnChildRemoved(n);
			if (n is Visual) OnContentChanged();
		}
		
		protected override float2 GetContentSize(LayoutParams lp)
		{
			if (Content != null)
				return Content.GetMarginSize( lp );
			return float2(0);
		}

		protected override void ArrangePaddingBox(LayoutParams lp)
		{
			if (Content != null)
			{
				var nlp = lp.CloneAndDerive();
				nlp.RemoveSize(Padding.XY + Padding.ZW);
				Content.ArrangeMarginBox(Padding.XY, nlp);
			}
		}
		
	}
}