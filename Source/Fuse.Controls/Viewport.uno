using Uno;
using Uno.Graphics;
using Uno.UX;

using Fuse.Common;
using Fuse.Nodes;

namespace Fuse.Elements
{
	/** Specifies how the viewport behaves */
	public enum ViewportMode
	{
		/** Renders normally within the current UI */
		Enabled,
		/** Acts are though the viewport were not there, the children render as if in a normal Element parent */
		Disabled,
		/** The viewport renders to a texture. This also has the effect of clipping to the Viewport size. */
		RenderToTexture,
	}
	
	public enum PerspectiveRelativeToMode
	{
		/** Local units, not relative to the size of the viewport */
		Local,
		/** A factor of the width of the viewport */
		Width,
		/** A factor of the height of the viewport */
		Height,
	}

	/** The Viewport element allows you to perform 3D transformations with perspective projection. 

		The Perspective property controls how far away the camera is from the Z = 0 plane (where everything is drawn by default), in points.

			<App>
				<Viewport Perspective="400">
					<Panel>
						<Rectangle Width="200" Height="200" Background="#2ecc71">
							<Clicked>
								<Rotate DegreesX="360" Duration="1.5" Easing="QuadraticInOut" DurationBack="0" />
							</Clicked>
						</Rectangle>
					</Panel>
				</Viewport>
			</App>
	*/
	public class Viewport : Element, IViewport, IRenderViewport
	{
		ViewportMode _mode = ViewportMode.Enabled;
		/** Specifies how the `Viewport` behaves with respect to rendering */
		public ViewportMode Mode
		{
			get { return _mode; }
			set
			{
				if ( value == _mode)
					return;

				_mode = value;

				InvalidateFrustum();
			}
		}

		PolygonFace _cullFace = PolygonFace.None;
		bool _hasCullFace;
		/** 
			Specifies which objects will not be drawn based on their orientation. By default an object
			facing away from the screen will still be drawn. 
			
			To hide back-facing objects use `CullFace="Back"`. Be aware this does not change their 
			hit status: the user can still interact with these invisible objects. You'll need a high-level
			mechanism to set `IsDisabled="false"` on them as well.
		*/
		public PolygonFace CullFace
		{
			get { return _cullFace; }
			set
			{
				_cullFace = value;
				_hasCullFace = true;
				InvalidateVisual();
			}
		}
		
		bool HasCullFace { get { return _hasCullFace; } }

		//When IsRoot==true we assume this fills up the main viewport and does not require
		//embedded root handling
		bool IsRoot { get { return Parent == null || Parent is RootViewport; } }
		
		void InvalidateFrustum()
		{
			_frustumDirty = true;
			InvalidateLocalTransform();
		}
		
		bool _frustumDirty = true;
		FrustumViewport _frustumViewport = new FrustumViewport();
		void UpdateFrustum()
		{
			if (IsRoot)
				_frustumViewport.Update(this, Frustum);
			else
				_frustumViewport.Update(this, Frustum, this);
		}
		
		FrustumViewport FrustumViewport
		{
			get
			{
				if (_frustumDirty)
				{
					UpdateFrustum();
					_frustumDirty= false;
				}
				return _frustumViewport;
			}
		}
		
		[UXContent]
		public Visual RootVisual
		{
			get 
			{ 
				if (!HasVisualChildren) return null;
				return FirstChild<Visual>();
			}
			set 
			{ 
				if (RootVisual != value)
				{
					while (HasVisualChildren)
						Children.Remove(FirstChild<Visual>());
					Children.Add(value);
					InvalidateLayout();
				}
			}
		}
		
		IFrustum _frustum = new OrthographicFrustum();
		IFrustum Frustum
		{
			get { return _frustum; }
			set 
			{ 
				_frustum = value; 
				InvalidateFrustum();
			}
		}
		
		bool _usePerspective;
		float _perspective;
		/**
			Places a simple perspective camera this far (in points) away from the surface plane of the UI.
			The further away the camera is the less visual difference objects have when translated in the
			Z dimension.
		*/
		public float Perspective
		{
			get { return _perspective; }
			set
			{
				if (value != _perspective)
				{
					_usePerspective = true;
					_perspective = value;
					UpdatePerspective();
				}
			}
		}
		
		PerspectiveRelativeToMode _perspectiveRelativeTo = PerspectiveRelativeToMode.Local;
		/**
			Specifies how to interpret the `Perspective` value. By default it is in point units, but can
			instead be interpreted relative to the size of the viewport.
			
			Using a relative distance is important for a responsive display. If the elements inside the
			viewport are responsive, then the viewport typically should be as well.
		*/
		public PerspectiveRelativeToMode PerspectiveRelativeTo
		{
			get { return _perspectiveRelativeTo; }
			set
			{
				if (value != _perspectiveRelativeTo)
				{
					_perspectiveRelativeTo = value;
					UpdatePerspective();
				}
			}
		}
		
		void UpdatePerspective()
		{
			if (!_usePerspective)
				return;
				
			var pf = Frustum as PerspectiveFrustum;
			if (pf == null)
			{
				pf = new PerspectiveFrustum();
				Frustum = pf;
			}
			
			float distance = 0;
			switch (PerspectiveRelativeTo)
			{
				case PerspectiveRelativeToMode.Local: distance = _perspective; break;
				case PerspectiveRelativeToMode.Width: distance = _perspective * ActualSize.X; break;
				case PerspectiveRelativeToMode.Height: distance = _perspective * ActualSize.Y; break;
			}
			pf.Distance = distance;
			InvalidateFrustum();
		}
		
		protected override void ArrangePaddingBox(LayoutParams lp)
		{
			if (RootVisual == null)
				return;

			RootVisual.ArrangeMarginBox(float2(0),lp);
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			Placed += OnPlaced;
		}
		
		protected override void OnUnrooted()
		{
			Placed -= OnPlaced;
			base.OnUnrooted();
		}
		
		protected void OnPlaced(object s, object a)
		{
			UpdatePerspective();
			InvalidateFrustum(); //in case not done in UpdatePerspective
		}

		protected override void DrawWithChildren(DrawContext dc)
		{
			if (RootVisual == null)
				return;

			if (Mode == ViewportMode.Disabled)
			{
				RootVisual.Draw(dc);
				return;
			}

			if (HasCullFace)
				dc.PushCullFace(CullFace);

			if (Mode == ViewportMode.RenderToTexture) {
				var pxSize = ((ICommonViewport)this).PixelSize;
				var fb = FramebufferPool.Lock( int2((int)pxSize.X,(int)pxSize.Y), Format.RGBA8888, true );
				dc.PushRenderTargetViewport(fb, this);

				dc.Clear(float4(0),1);
				RootVisual.Draw(dc);

				dc.PopRenderTargetViewport();

				Blitter.Singleton.Blit(
					fb.ColorBuffer,
					new Rect(float2(0, 0), ActualSize),
					dc.GetLocalToClipTransform(this),
					1.0f, true);

				if defined(FUSELIBS_DEBUG_DRAW_RECTS)
					DrawRectVisualizer.Capture(float2(0), ActualSize, WorldTransform, dc);

				FramebufferPool.Release(fb);

			} else {
				if (IsRoot)
				{
					dc.PushViewport( this );
				}
				else
				{
					var local = new InheritViewport(dc.Viewport, FrustumViewport, this);
					dc.PushViewport( local );
				}
				RootVisual.Draw(dc);
				dc.PopViewport();
			}

			if (HasCullFace)
				dc.PopCullFace();
		}
		
		VisualBounds ModifyBounds(VisualBounds vb)
		{
			var root = RootVisual;
			if (IsDisabled || root == null || root.IsFlat)
				return vb;
				
			//this mode clips
			if (Mode == ViewportMode.RenderToTexture)
				return vb.AddRect(float2(0), ActualSize); //TODO: should be an Intersection
				
			//assume bounds are fine when the root (an optimization)
			if (IsRoot)
				return vb.AddRect(float2(0), ActualSize); //TODO: should be an intersetion?

			var mx = FrustumViewport.GetFlatWorldToVisualTransform(ActualSize);
			//the result should be flat, so force it to smooth out floating point precision issues
			//having it flat enables optimizations elsehwere in rendering/hit testing
			var q = vb.TransformFlatten(FastMatrix.FromFloat4x4(mx));
			return q;
		}
		
		protected override VisualBounds CalcRenderBounds()
		{
			var bb = base.CalcRenderBounds();
			var q = ModifyBounds(bb);
			return q;
		}
		
 		protected override VisualBounds HitTestChildrenBounds
 		{
 			get 
 			{ 
				var bb = base.HitTestChildrenBounds;
				var q = ModifyBounds(bb);
				return q; 
			}
 		}
		
		/* viewports flatten the view space, thus they are flat (and can be cached, the major consequence) */
 		internal override bool CalcAreChildrenFlat()
 		{
 			return IsDisabled ? base.CalcAreChildrenFlat() : true;
 		}
		
		internal override HitTestTransformMode HitTestTransform
		{
			get { return IsDisabled ? base.HitTestTransform : HitTestTransformMode.WorldRay; }
		}
		
		/**
			This viewport is the world for the children
		*/
		override internal FastMatrix ParentWorldTransformInternal
		{
			get { return IsDisabled ? base.ParentWorldTransformInternal : FastMatrix.Identity(); }
		}

		bool IsDisabled { get { return Mode == ViewportMode.Disabled; } }

		//ICommonViewport
		public float ICommonViewport.PixelsPerPoint
		{
			get { return Parent.Viewport.PixelsPerPoint; }
		}
		public float2 ICommonViewport.Size
		{
			get { return IsDisabled ? Parent.Viewport.Size : ActualSize; }
		}
		public float2 ICommonViewport.PixelSize
		{
			get { return IsDisabled ? Parent.Viewport.PixelSize : ActualSize * ((ICommonViewport)this).PixelsPerPoint; }
		}
		public float4x4 ICommonViewport.ViewTransform 
		{
			get { return IsDisabled ? Parent.Viewport.ViewTransform : FrustumViewport.ViewTransform; }
		}
		
		//IRenderViewport
		public float4x4 IRenderViewport.ProjectionTransform 
		{
			get { return FrustumViewport.ProjectionTransform; }
		}
		public float4x4 IRenderViewport.ViewProjectionTransform 
		{
			get { return FrustumViewport.ViewProjectionTransform; }
		}
		
		public float3 IRenderViewport.ViewOrigin { get { return this.Frustum.GetWorldPosition(this); } }
		public float2 IRenderViewport.ViewRange { get { return this.Frustum.GetDepthRange(this); } }
		
		//IViewport
		public Ray PointToWorldRay(float2 pointPos)
        {
			if (IsDisabled)
				return Parent.Viewport.PointToWorldRay(pointPos);

			if (!IsRoot)
			{
				var pr = Parent.Viewport.PointToWorldRay(pointPos);
				var local = Parent.Viewport.WorldToLocalRay(Parent.Viewport, pr, this);
				pointPos = ViewportHelpers.LocalPlaneIntersection(local);
			}

			var r = ViewportHelpers.PointToWorldRay(this, FrustumViewport.ViewProjectionTransformInverse, pointPos);
			return r;
        }

		public Ray WorldToLocalRay(IViewport world, Ray worldRay, Visual where)
		{
			if (IsDisabled)
			{
				if (world == this)
					world = Parent.Viewport;
				return Parent.Viewport.WorldToLocalRay(world, worldRay, where);
			}

			return ViewportHelpers.WorldToLocalRay(this, world, worldRay, where);
		}
	}
}
