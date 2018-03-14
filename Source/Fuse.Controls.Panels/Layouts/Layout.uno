using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.Layouts
{
	public abstract class Layout : PropertyObject, ISourceLocation
	{
		/**
			Don't allow user layout's yet as the API here is not completely stable, nor easy to use.
		*/
		internal Layout() { }
		
		static readonly PropertyHandle _fillPaddingProperty = Fuse.Properties.CreateHandle();
		
		[UXAttachedPropertySetter("Layout.FillPadding")]
		public static void SetFillPadding(Visual n, bool f)
		{
			n.Properties.Set(_fillPaddingProperty, f);
			InvalidateLayout(n);
		}
		
		[UXAttachedPropertyGetter("Layout.FillPadding")]
		public static bool GetFillPadding(Visual n)
		{
			object v;
			if (n.Properties.TryGet(_fillPaddingProperty, out v))
				return (bool)v;
				
			return n.Layer == Layer.Background ||
			       n.Layer == Layer.Underlay;
		}
		
		[UXAttachedPropertyResetter("Layout.FillPadding")]
		public static void ResetFillPadding(Visual n)
		{
			n.Properties.Clear(_fillPaddingProperty);
			InvalidateLayout(n);
		}
		
		protected LayoutControl Container;

		internal void Rooted(LayoutControl element)
		{
			if (Container != null)
				throw new Exception( "Only a single container is supported for Layout" );
			Container = element;
			OnRooted();
		}
		
		virtual protected void OnRooted() 
		{ 
		}

		internal void Unrooted(LayoutControl element)
		{
			if (element != Container)
				throw new Exception( "Removing an invalid container from Layout" );
			OnUnrooted();
			Container = null;
		}
		
		virtual protected void OnUnrooted()
		{
		}

		//true at the start of rooting, prior to OnRooted call
		internal bool IsRootingStarted { get { return Container != null; } }
	
		internal abstract float2 GetContentSize(Visual elementOwner, LayoutParams lp);
		internal abstract void ArrangePaddingBox(Visual elementOwner, float4 padding, LayoutParams lp);
		
		protected bool AffectsLayout(Node n)
		{
			var v = n as Visual;
			return v != null && (v.LayoutRole == LayoutRole.Standard ||	
				v.LayoutRole == LayoutRole.Placeholder);
		}
		
		protected bool ShouldArrange(Node n)
		{
			var v = n as Visual;
			return v != null && v.LayoutRole != LayoutRole.Independent;
		}
		
		protected bool ArrangeMarginBoxSpecial(Node n, float4 padding, LayoutParams lp)
		{
			var e = n as Visual;
			if (e == null)
				return false;

			var lr = e.LayoutRole;
			if (lr == LayoutRole.Independent)
			{
				//give boxsizing a chance to know it's parent has changed
				var elm = e as Element;
				if (e != null)
					elm.RequestLayout();
				return true;
			}
				
			if (lr == LayoutRole.Inert)
			{
				var b = GetFillPadding(e);
				var p = b ? float2(0) : padding.XY;
				var s = b ? lp.Size : lp.Size - padding.XY - padding.ZW;
				var nlp = lp.CloneAndDerive();
				nlp.SetSize(s);
				e.ArrangeMarginBox( p, nlp );
				return true;
			}
			
			return false;
		}
		
		/**
			Some properties attached to children are actually properties of the parent layout, thus
			need to invlaidate at that level.
		*/
		protected static void InvalidateAncestorLayout(Visual child)
		{
			//just assume Parent for now
			if (child.Parent != null)
				child.Parent.InvalidateLayout();
		}
		
		internal virtual LayoutDependent IsMarginBoxDependent( Visual child )
		{
			//conservative Yes
			return LayoutDependent.Yes;
		}
		
		protected void InvalidateLayout()
		{
			if (Container != null)
				Container.InvalidateLayout();
		}
		
		protected bool SnapToPixels
		{
			get
			{
				return Container != null && Container.SnapToPixels;
			}
		}
		
		protected float2 SnapUp( float2 p )
		{
			if (SnapToPixels)
				return Container.InternSnapUp(p);
			return p;
		}
		
		protected float SnapUp( float p )
		{
			return SnapUp(float2(p)).X;
		}
		
		protected float2 Snap( float2 p )
		{
			if (SnapToPixels)
				return Container.InternSnap(p);
			return p;
		}
		
		protected float Snap( float p )
		{
			return Snap(float2(p)).X;
		}
		
		static LayoutControl GetLayoutControl(Visual elm)
		{
			while(elm != null)
			{
				if (elm is LayoutControl)
					return elm as LayoutControl;
				elm = elm.Parent;
			}
			
			return null;
		}
		
		static void InvalidateLayout(Visual elm)
		{
			var p = GetLayoutControl(elm);
			if (p != null)
				p.InvalidateLayout();
		}
		
		/**
			Adjusts the alignment of an item inside the box (in parent-space).
			
			This can only be called once after the margin box of the `node` is first
			arranged as it offsets that position.
			
			TODO: this probably doesn't support `Element.Anchor`
		*/
		internal static void AdjustAlignBox(Visual node, float2 sz, float4 box, Alignment align)
		{
			var pos = node.MarginBoxPosition;
			var ha = AlignmentHelpers.GetHorizontalSimpleAlign(align);
			if (ha != Alignment.Default)
				pos.X = SimpleOff( sz.X, box.XZ, ha);
			var va = AlignmentHelpers.GetVerticalSimpleAlign(align);
			if (va != Alignment.Default)
				pos.Y = SimpleOff( sz.Y, box.YW, va);
				
			node.AdjustMarginBoxPosition( pos );
		}
		
		static float SimpleOff(float sz, float2 range, SimpleAlignment align)
		{
			if (align == SimpleAlignment.Center)
				return (range[1] + range[0])/2 - sz/2;
			else if(align == SimpleAlignment.End)
				return range[1] - sz;
			else
				return range[0];
		}
		
		[UXLineNumber]
		/** @hide */
		public int SourceLineNumber { get; set; }
		[UXSourceFileName]
		/** @hide */
		public string SourceFileName { get; set; }
		
		ISourceLocation ISourceLocation.SourceNearest
		{
			get
			{
				if (SourceFileName != null)
					return this;
				if (Container != null)
					return ((ISourceLocation)Container).SourceNearest;
				return null;
			}
		}
	}

	public static class Layouts
	{
		public static readonly Layout Default = new DefaultLayout();
	}

}