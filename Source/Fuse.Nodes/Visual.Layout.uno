using Uno;
using Uno.UX;


namespace Fuse
{
	/** Enumerates the layers of a @Visual. */
	public enum Layer
	{
		/** Drawn before/behind all other layers. Visuals in the underlay layer do not
			contribute to the size of the parent layer. */
		Underlay = 0,

		/** Drawn after Underlay and before Layout layer. Visuals in the background layer do not
			contribute to the size of the parent layer. */
		Background,

		/** Drawn after the background and before the overlay layer. Visuals in this layer
			contribute to the size of the parent layer in @LayoutControls. */
		Layout,

		/** Drawn after/on top all other layers. Visuals in the overlay layer do not
			contribute to the size of the parent layer. */
		Overlay,
	}

	/** 
		The influence this visual has on the layout and inside content controls, such as @PageControl or @ScrollView. 
	*/
	public enum LayoutRole
	{
		/** The Visual is part of the layout, being sized by it's parent and contributing to it's size. Only standard Visual's are considered logical content of higher level controls like Navigation. */
		Standard,
		/** This has the same layout role as Standard exception it is not logical content for higher level controls. */
		Placeholder,
		/** The Visual inherits the layout of the parent but does not influece the parent layour. This is the default for items not in the `Layout` layer. */
		Inert,
		/** The Visual takes it's layout from somewhere other than it's parent. A Visual that uses LayoutMaster will get this role. */
		Independent,
	}
	
	public enum InvalidateLayoutReason
	{
		//the ordering here is important, higher values are more extreme updates
		NothingChanged = 0,
		ChildChanged,
		MarginBoxChanged,
	}

	public enum LayoutDependent
	{
		//No returned is a definite no
		No = 0,
		//size is not, be requires rearrange
		NoArrange,
		Maybe,
		//size is not, but requires rearrange
		MaybeArrange,
		Yes,
	}
	
	public enum MarginBoxDependent
	{
		None,
		Layout,
		Size,
	}

	/**
		Successive events cancel each other out. Only one thing in the tree can be brought into
		view a time/per-frame. This also means that `Node` could be null, indicating this frame
		there is no more request (in case a request was sent and needs to be cancelled).
	*/
	public sealed class RequestBringIntoViewArgs: EventArgs
	{
		public Visual Visual { get; private set; }
		public RequestBringIntoViewArgs(Visual elm)
		{
			Visual = elm;
		}
	}

	public delegate void RequestBringIntoViewHandler(object sender, RequestBringIntoViewArgs args);

	public abstract partial class Visual
	{
		static readonly PropertyHandle _layerProperty = Fuse.Properties.CreateHandle();
		
		/** The layer this visual belongs to in the @Parent container. 
			@default Layout
		*/
		public Layer Layer
		{
			get
			{
				object v;
				if (Properties.TryGet(_layerProperty, out v))
					return (Layer)v;
				return Layer.Layout;
			}
			set 
			{
				if (Layer != value)
				{
					Properties.Set(_layerProperty, value);
					InvalidateLayout();
					if (Parent != null) Parent.InvalidateZOrder();
				}
			}
		}
		

		static readonly PropertyHandle _layoutRoleProperty = Fuse.Properties.CreateHandle();
		
		/** Describes how this visual participates in layout. 
			@default Standard
		*/
		public LayoutRole LayoutRole
		{
			get 
			{
				object v;
				if (Properties.TryGet(_layoutRoleProperty, out v))
					return (LayoutRole)v;
					
				//a convenience so that non-base layers have no layout role by default
				if (Layer != Layer.Layout)
					return LayoutRole.Inert;
					
				return LayoutRole.Standard;
			}
			set
			{
				Properties.Set(_layoutRoleProperty, value);
				InvalidateLayout();
			}
		}
	
		public virtual float2 GetMarginSize(LayoutParams lp)
 		{
 			return float2(0);
 		}

 		protected virtual void OnInvalidateLayout()
 		{
 		}

		InvalidateLayoutReason _layoutDirty;
		
		internal InvalidateLayoutReason LayoutDirty
		{
			get { return _layoutDirty; }
		}
		
		internal bool IsLayoutDirty
		{
			get { return _layoutDirty != InvalidateLayoutReason.NothingChanged; }
		}

		internal virtual bool IsLayoutRoot { get { return false; } }
		
		/**
			Indicates that this element requires a new layout as some layout parameters or content
			have changed.
			
			This does not directly change any sizes or invalidate any cached values. The actual changes done
			during a call to `ArrangeMarginBox` must invalidate those as appropriate.
		*/
		public void InvalidateLayout( InvalidateLayoutReason reason = 
			InvalidateLayoutReason.MarginBoxChanged )
		{
			if (_performingLayout) 
				throw new Exception("Layout was invalidated while performing layout");

			if ((int)reason <= (int)_layoutDirty)
				return;
			_layoutDirty = reason;
			OnInvalidateLayout();

			var child = this;
			var parent = this.Parent;
			Visual maybeChild = null;
			while (parent != null && !parent.IsLayoutRoot)
			{
				if ((int)reason <= (int)parent._layoutDirty)
					break;
		
				var useReason = reason;
				
				//without margin box we must propagate margin changed, otherwise Rearrange is not possible
				if (child.HasMarginBox && (int)reason > (int)InvalidateLayoutReason.ChildChanged)
				{
					var mb = parent.IsMarginBoxDependent(child);

					//resolve the Maybe's
					if (mb == LayoutDependent.Yes || mb == LayoutDependent.MaybeArrange)
					{
						while (maybeChild != null && maybeChild != parent)
						{
							maybeChild._layoutDirty = InvalidateLayoutReason.MarginBoxChanged;
							maybeChild = maybeChild.Parent;
						}
						maybeChild = null;
					}

					switch(mb)
					{
						case LayoutDependent.No:
							useReason = reason = InvalidateLayoutReason.ChildChanged;
							break;
							
						case LayoutDependent.NoArrange:
							useReason = InvalidateLayoutReason.MarginBoxChanged;
							reason = InvalidateLayoutReason.ChildChanged;
							break;
							
						case LayoutDependent.Maybe:
							useReason = InvalidateLayoutReason.ChildChanged;
							if (maybeChild == null)
								maybeChild = parent;
							break;
							
						case LayoutDependent.MaybeArrange:
							useReason = InvalidateLayoutReason.MarginBoxChanged;
							if (maybeChild == null)
								maybeChild = parent;
							break;
					
						case LayoutDependent.Yes:
							reason = useReason = InvalidateLayoutReason.MarginBoxChanged;
							break;
					}
				}
				
				//there might be an optimized way to avoid this sometimes, but let's be safe for now
				parent.OnInvalidateLayout();
				
				if ((int)useReason > (int)parent._layoutDirty)
					parent._layoutDirty = useReason;
			
				child = parent;
				parent = parent.Parent;
			}
		}

		/**	
			@return Yes if the child influences the results of ArrangeMarginBox (size or layout of this node),
				No if it cannot, and Maybe otherwise (in cases of stretching)
		*/
		protected virtual LayoutDependent IsMarginBoxDependent(Visual child)
		{
			return LayoutDependent.Maybe;
		}
		internal LayoutDependent InternIsMarginBoxDependent(Visual child) { return IsMarginBoxDependent(child); }

		internal float2 InternSnap(float2 p) { return Snap(p); }
		protected float2 Snap(float2 p)
		{
			var s = Math.Round(p * AbsoluteZoom) / AbsoluteZoom;
			return s;
		}
		
		protected float2 IfSnap(float2 p)
		{
			return SnapToPixels ? Snap(p) : p;
		}
		
		protected float2 IfSnapUp(float2 p)
		{
			return SnapToPixels ? SnapUp(p) : p;
		}

		const float pixelEpsilon = 0.005f;
		
		internal float2 InternSnapUp(float2 p) { return SnapUp(p); }
		protected float2 SnapUp(float2 p)
		{
			var s = Math.Ceil(p * AbsoluteZoom - pixelEpsilon) / AbsoluteZoom;
			return s;
		}

		protected float2 SnapDown(float2 p)
		{
			var s = Math.Floor(p * AbsoluteZoom + pixelEpsilon) / AbsoluteZoom;
			return s;
		}
		
		protected float2 IfSnapDown(float2 p)
		{
			return SnapToPixels ? SnapDown(p) : p;
		}

		 /*DEPRECATED*/
		public float AbsoluteZoom
		{
			get 
			{ 
				var v = Viewport;
				//somebody is calling this without being rooted, safety check
				if (v == null)
					return 1;
				return v.PixelsPerPoint; 
			}
		}
		
		/** Whether to snap the result of layout of this visual to physical device pixels.
			@default true */
		public bool SnapToPixels
		{
			get 
			{ 
				return HasBit(FastProperty1.ContextSnapToPixelsCache); 
			}
			set 
			{
				if (SnapToPixels != value || !HasBit(FastProperty1.HasSnapToPixels))
				{
					SetBit(FastProperty1.HasSnapToPixels);
					SetBit(FastProperty1.SnapToPixels, value);
					UpdateContextSnapToPixelsCache();
					InvalidateLayout();
				}
			}
		}

		void UpdateContextSnapToPixelsCache()
		{
			var newValue = 
				HasBit(FastProperty1.HasSnapToPixels) ? HasBit(FastProperty1.SnapToPixels) : 
				Parent != null ? Parent.SnapToPixels :
				true;

			if (newValue != SnapToPixels)
			{
				SetBit(FastProperty1.ContextSnapToPixelsCache, newValue);

				for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
					v.UpdateContextSnapToPixelsCache();
			}
		}
	
		protected void PerformLayout()
		{
			PerformLayout(Viewport.Size);
		}

		static bool _performingLayout;
		float2 _cachedRenderTargetSize;

		protected void PerformLayout(float2 clientSize)
		{
			if (_cachedRenderTargetSize.X != clientSize.X ||
				_cachedRenderTargetSize.Y != clientSize.Y)
			{
				_cachedRenderTargetSize = clientSize;
				InvalidateLayout();
			}
			
			if (_layoutDirty != InvalidateLayoutReason.NothingChanged)
			{
				_performingLayout = true;
				try
				{
					//special case for root element
					if (_layoutDirty == InvalidateLayoutReason.MarginBoxChanged)
					{
						var availableSize = (float2)clientSize;
						var offset = float2(0);

						ArrangeMarginBox(offset, LayoutParams.Create(availableSize));
					}
					else
					{
						UpdateLayout();
					}
				}
				finally
				{
					_performingLayout = false;
				}
			}
		}
		
		void UpdateLayout()
		{
			switch (_layoutDirty)
			{
				case InvalidateLayoutReason.NothingChanged:
					break;
					
				case InvalidateLayoutReason.ChildChanged:
					for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
						v.UpdateLayout();
					break;
					
				case InvalidateLayoutReason.MarginBoxChanged:
					RearrangeMarginBox();
					break;
			}
			
			//since not all paths above set this
			_layoutDirty = InvalidateLayoutReason.NothingChanged;
		}

		float2 _ambPosition;
		float2 _ambMargin;
		LayoutParams _ambLayoutParams = LayoutParams.CreateEmpty();
		bool _hasMarginBox = false;
		
		internal bool HasMarginBox { get { return _hasMarginBox; } }
		
		void RearrangeMarginBox()
		{
			if (!HasMarginBox)
			{
				throw new Exception( "Invalid call to RearrangeMarginBox" );
			}
			ArrangeMarginBox( _ambPosition, _ambLayoutParams );
		}
		
		protected virtual float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
		{
			var sz = float2(0);
			for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
			{
				var msz = v.ArrangeMarginBox(position, lp);
				sz = Math.Max(sz,msz);
			}
			return sz;
		}

		public float2 ArrangeMarginBox(float2 position, LayoutParams lp)
		{
			var same = HasMarginBox && 
				(_layoutDirty == InvalidateLayoutReason.NothingChanged) &&
				_ambLayoutParams.IsCompatible(lp);

			const float zeroTolerance = 1e-05f;

			float2 marginBox;
			if (same && (Vector.Distance(position, _ambPosition) < zeroTolerance))
			{
				return _ambMargin;
			}
			else if(same && CanAdjustMarginBox)
			{
				marginBox = _ambMargin;
				OnAdjustMarginBoxPosition(position);
			}
			else
			{
				marginBox = OnArrangeMarginBox(position, lp);
			}
			
			_layoutDirty = InvalidateLayoutReason.NothingChanged;
			
			_ambMargin = marginBox;
			_ambPosition = position;
			_ambLayoutParams = lp.Clone();
			_hasMarginBox = true;
			
			return marginBox;
		}
		
		internal float2 MarginBoxPosition { get { return _ambPosition; } }
		
		internal void AdjustMarginBoxPosition( float2 position )
		{
			ArrangeMarginBox(position, _ambLayoutParams);
		}
		
		internal virtual bool CanAdjustMarginBox { get { return false; } }
		internal virtual void OnAdjustMarginBoxPosition( float2 position ) { }

		/**
			Returns the origin of this Visual in the viewport (world) space.
			
			This is used in layout to calculate pixel snapping.
		*/
		protected virtual float2 AbsoluteViewportOrigin
		{
			get 
			{
				if (Parent != null)
					return Parent.AbsoluteViewportOrigin;
				return float2(0);
			}
		}

		/** Used internally for implementing the BringIntoView feature.
			@advanced */
		public event RequestBringIntoViewHandler RequestBringIntoView;

        	internal protected virtual void OnBringIntoView(Visual elm)
        	{
	        	if (RequestBringIntoView != null) 
	        		RequestBringIntoView(this, new RequestBringIntoViewArgs(elm));

        		if (Parent != null) 
        			Parent.OnBringIntoView(elm);
        	}

        	public void BringIntoView()
        	{
	        	OnBringIntoView(this);
        	}
	}
}
