using Uno;

using Fuse.Input;
using Fuse.Internal;

namespace Fuse
{
	public abstract partial class Visual
	{
		internal enum HitTestTransformMode
		{
			LocalPoint,
			WorldRay,
		}
		
		internal virtual HitTestTransformMode HitTestTransform
		{
			get
			{
				if (IsLocalFlat)
					return HitTestTransformMode.LocalPoint;
				return HitTestTransformMode.WorldRay;
			}
		}
		
		public void HitTest(HitTestContext htc)
		{
			if (!IsVisible) 
				return;

			var bounds = HitTestBounds;
			
			float2 localPoint;
			bool hit;
			if (bounds.IsFlat && HitTestTransform == HitTestTransformMode.LocalPoint)
			{
				if (!TryParentToLocal(htc.LocalPoint, out localPoint))
					return;
				hit = bounds.ContainsPoint(localPoint);
			}
			else
			{
				//find intersection of ray with Z=0 plane
				var world = Viewport.PointToWorldRay(htc.WindowPoint);
				var local = Viewport.WorldToLocalRay(Viewport, world, this);
				localPoint = ViewportHelpers.LocalPlaneIntersection(local);

				hit = bounds.IsFlat ? bounds.ContainsPoint(localPoint) : bounds.IntersectsRay(local);
			} 

			if (FuseConfig.VisualHitTestClipping && !hit)
				return;
			
			var old = htc.PushLocalPoint(localPoint);
			OnHitTest(htc);
			htc.PopLocalPoint(old);
		}

		protected virtual void OnHitTest(HitTestContext htc)
		{
			if (HasVisualChildren)
			{
				var zOrder = GetCachedZOrder();
				for (var i = zOrder.Length; i --> 0;)
					zOrder[i].HitTest(htc);
			}
		}
		
		public Visual GetHitWindowPoint(float2 windowPoint)
		{
			var htr = new HitTestRecord();
			var htc = new HitTestContext(windowPoint,htr.HitTestCallback);
			if (Parent != null)
				htc.PushLocalPoint( Parent.WindowToLocal(windowPoint) );
			htc.PushWorldRay( Viewport.PointToWorldRay(windowPoint) );
			HitTest(htc);
			return htr.Visual;
		}
		
		class HitTestRecord
		{
			public Visual Visual;
			public void HitTestCallback(HitTestResult result)
			{
				if (Visual == null)
					Visual = result.HitObject;
			}
		}
		
		protected  void InvalidateHitTestBounds()
		{
			var p = this;
			while (p != null && p._isHitTestBoundsCacheValid)
			{
				p._isHitTestBoundsCacheValid = false;
				p = p.Parent;
			}
		}
		
		VisualBounds _hitTestBoundsCache;
		bool _isHitTestBoundsCacheValid;
		
		public virtual VisualBounds HitTestBounds
		{
			get
			{
				if (_isHitTestBoundsCacheValid)
					return _hitTestBoundsCache;

				var nb = VisualBounds.Empty;
				
				if (IsContextEnabled && IsVisible)
				{
					nb = nb.Merge( HitTestLocalBounds );
					nb = nb.Merge( HitTestChildrenBounds );
				}
				
				_hitTestBoundsCache = nb;
				_isHitTestBoundsCacheValid = true;
				return nb;
			}
		}
		
		protected virtual VisualBounds HitTestLocalBounds
		{
			get
			{
				return VisualBounds.Empty;
			}
		}
		
		protected virtual VisualBounds HitTestChildrenBounds
		{
			get
			{
				return VisualBounds.Merge(VisualChildren, VisualBounds.Type.HitTest);
			}
		}
	}
}