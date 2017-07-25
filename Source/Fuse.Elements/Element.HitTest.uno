using Uno;
using Uno.UX;

using Fuse.Internal;

namespace Fuse.Elements
{
	[Flags]
	/** Specifies how hit testing should be performed on an @Element */
	public enum HitTestMode
	{
		/** Neither this element nor its children will be hit tested. */
		None = 0,
		/** The element will be hit tested based on its appearance. */
		LocalVisual = 1<<0,
		/** The element will be hit tested based on its size. */
		LocalBounds = 1<<1,
		/** Only the cildren of this element will be hit tested. */
		Children = 1 <<2,
			
		//TODO: temporary workaround for https://github.com/fusetools/fuselibs/issues/213
		/** Hit testing will include the appearance of the element and its children. */
		LocalVisualAndChildren = LocalVisual | Children,
		/** Hit testing will include the size of the element and its children. */
		LocalBoundsAndChildren = LocalBounds | Children,
	}

	public abstract partial class Element
	{
		public bool IsPointInside(float2 localPoint)
		{
			return !(localPoint.X < 0 || localPoint.Y < 0 || localPoint.X > ActualSize.X || localPoint.Y > ActualSize.Y);
		}

		public const HitTestMode DefaultHitTestMode = HitTestMode.Children | HitTestMode.LocalVisual;

		static readonly Selector _hitTestModeName = "HitTestMode";

		[UXOriginSetter("SetHitTestMode")]
		/** Specifies how hit tests should be performed on this element. */
		public HitTestMode HitTestMode
		{
			get { return Get(FastProperty1.HitTestMode, DefaultHitTestMode); }
			set { SetHitTestMode(value, this); }
		}

		public void SetHitTestMode(HitTestMode value, IPropertyListener origin)
		{
			Set(FastProperty1.HitTestMode, value, DefaultHitTestMode);
			InvalidateHitTestBounds();
			OnPropertyChanged(_hitTestModeName, origin);
			NotifyTreeRendererHitTestModeChanged();
		}

		sealed protected override void OnHitTest(HitTestContext htc)
		{
			if (ClipToBounds && !IsPointInside(htc.LocalPoint))
				return;
				
			if (HitTestMode.HasFlag(HitTestMode.Children))
				OnHitTestChildren(htc);
			if (HitTestMode.HasFlag(HitTestMode.LocalVisual))
				OnHitTestLocalVisual(htc);
			if (HitTestMode.HasFlag(HitTestMode.LocalBounds))
			{
				if (IsPointInside(htc.LocalPoint)) 
					htc.Hit(this);
			}
		}

		void OnHitTestChildren(HitTestContext htc)
		{
			if (HasVisualChildren)
			{
				var zOrder = GetCachedZOrder();
				for (var i = zOrder.Length; i --> 0; )
					zOrder[i].HitTest(htc);
			}
		}

		protected virtual void OnHitTestLocalVisual(HitTestContext htc) { }
		
		/**
			Derived classes should overried HitTestLocalVisualBounds if they draw a local visual.
		*/
		protected sealed override VisualBounds HitTestLocalBounds
		{
			get
			{
				var n = VisualBounds.Empty;
				
				if (HitTestMode.HasFlag(HitTestMode.LocalBounds))
					n = n.AddRect( float2(0), ActualSize );
				if (HitTestMode.HasFlag(HitTestMode.LocalVisual))
					n = n.Merge( HitTestLocalVisualBounds );
				return n;
			}
		}
		
		protected virtual VisualBounds HitTestLocalVisualBounds
		{
			get
			{
				return VisualBounds.Empty;
			}
		}

		protected override VisualBounds HitTestChildrenBounds
		{	
			get
			{
				if (HitTestMode.HasFlag(HitTestMode.Children))
					return base.HitTestChildrenBounds;
				return VisualBounds.Empty;
			}
		}
	}
}