using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Matrix;

namespace Fuse
{

	/*
		Transforms work as follows:

		[
			Parent Visual

			[Layout Transform]

			[Explicit Transform]
			[Explicit Transform]
		]

	*/

	public abstract partial class Visual
	{
		protected virtual void PrependImplicitTransform(FastMatrix m) {}
		protected virtual void PrependTransformOrigin(FastMatrix m) {}
		protected virtual void PrependInverseTransformOrigin(FastMatrix m) {}

		int _transformCount;
		bool HasExplicitTransforms
		{
			get { return _transformCount > 0; }
		}

		void OnTransformAdded(Transform t)
		{
			_transformCount++;
			t.MatrixChanged += OnMatrixChanged;
			OnMatrixChanged(t);
		}

		void OnTransformRemoved(Transform t)
		{
			_transformCount--;
			t.MatrixChanged -= OnMatrixChanged;
			OnMatrixChanged(t);
		}

		void OnMatrixChanged(Transform t)
		{
			InvalidateLocalTransform();
		}

		protected virtual void InvalidateLocalTransform()
		{
			_localTransform = null;
			_localTransformInverse = null;
			InvalidateFlat();
			InvalidateHitTestBounds();
			InvalidateWorldTransform();
		}

		FastMatrix _worldTransformInverse;
		public float4x4 WorldTransformInverse
		{
			get
			{
				if (_worldTransformInverse != null)
					CheckWorldTransformVersion();

				if (_worldTransformInverse == null)
				{
					_worldTransformInverse = WorldTransformInternal.Copy();
					_worldTransformInverse.Invert();
				}
				return _worldTransformInverse.Matrix;
			}
		}

		public float4x4 WorldTransform
		{
			get
			{
				return WorldTransformInternal.Matrix;
			}
		}

		public float3 WorldPosition
		{
			get { return WorldTransformInternal.Matrix.M41M42M43; }
		}

		public virtual Box LocalBounds
		{
			get { return new Box(float3(0), float3(0)); }
		}

		int _worldTransformVersion;
		int _parentWorldTransformVersion;

		void CheckWorldTransformVersion()
		{
			if (_worldTransform != null || _worldTransformInverse != null)
				if (Parent != null)
				{
					Parent.CheckWorldTransformVersion();
				
					if (_parentWorldTransformVersion != Parent._worldTransformVersion)
					{
						_parentWorldTransformVersion = Parent._worldTransformVersion;
						_worldTransform = null;
						_worldTransformInverse = null;
						_worldTransformVersion++;
					}
				}
		}

		FastMatrix _worldTransform;
		FastMatrix WorldTransformInternal
		{
			get
			{
				if (_worldTransform != null)
					CheckWorldTransformVersion();
				
				if (_worldTransform == null)
					_worldTransform = CalcWorldTransform();
				return _worldTransform;
			}
		}

		virtual internal FastMatrix ParentWorldTransformInternal
		{
			get { return WorldTransformInternal; }
		}

		FastMatrix _localTransform;
		public float4x4 LocalTransform
		{
			get
			{
				return LocalTransformInternal.Matrix;
			}
		}

		internal FastMatrix InternLocalTransformInternal { get { return LocalTransformInternal; } } 
		
		protected FastMatrix LocalTransformInternal
		{
			get
			{
				if (_localTransform == null)
				{
					_localTransform = FastMatrix.Identity();
					PrependLocalTransform(_localTransform);
				}
				return _localTransform;
			}
		}

		FastMatrix _localTransformInverse;
		protected float4x4 LocalTransformInverse
		{
			get { return LocalTransformInverseInternal.Matrix; }
		}

		FastMatrix LocalTransformInverseInternal
		{
			get
			{
				if (_localTransformInverse == null)
				{
					_localTransformInverse = FastMatrix.FromFloat4x4(LocalTransform);
					_localTransformInverse.Invert();
				}
				return _localTransformInverse;
			}
		}

		FastMatrix CalcWorldTransform()
		{
			var m = LocalTransformInternal;

			if (Parent != null)
			{
				m = m.Mul(Parent.ParentWorldTransformInternal);
			}

			return m;
		}

		public float4x4 GetTransformTo(Visual other)
		{
			//undefined if no shared ancestor

			var parents = new HashSet<Visual>();
			var q = this;
			while (q != null)
			{
				parents.Add(q);
				q = q.Parent;
			}

			var c = other;
			while (c != null)
			{
				if (parents.Contains(c))
					break;
				c = c.Parent;
			}

			if (c == null)
				return float4x4.Identity;

			var thisTo = GetTransformToAncestor(c);
			var otherTo = other.GetTransformToAncestor(c);

			return Matrix.Mul( thisTo, Matrix.Invert(otherTo) );
		}

		float4x4 GetTransformToAncestor(Visual ancestor)
		{
			var m = FastMatrix.Identity();
			var n = this;
			while (n != null && n != ancestor)
			{
				m = m.Mul(n.LocalTransformInternal);
				n = n.Parent;
			}

			return m.Matrix;
		}

		void PrependLocalTransform(FastMatrix m)
		{
			PrependImplicitTransform(m);
			PrependExplicitTransforms(m);
		}

		void PrependExplicitTransforms(FastMatrix m)
		{
			if (HasExplicitTransforms)
			{
				PrependTransformOrigin(m);
				
				for (var t = FirstChild<Transform>(); t != null; t = t.NextSibling<Transform>())
					t.PrependTo(m);
					
				PrependInverseTransformOrigin(m);
			}
		}

		public float2 WindowToLocal(float2 windowCoord)
		{
			if (HitTestTransform == HitTestTransformMode.LocalPoint)
			{
				var parentCoord = (Parent == null) ? windowCoord : Parent.WindowToLocal(windowCoord);
				return LocalTransformInverseInternal.TransformVector(float3(parentCoord,0)).XY;
			}
			else
			{
				var world = Viewport.PointToWorldRay(windowCoord);
				var local = Viewport.WorldToLocalRay(Viewport, world, this);
				return ViewportHelpers.LocalPlaneIntersection(local);
			}
		}

		virtual public VisualBounds LocalRenderBounds
		{
			get
			{
				return VisualBounds.Infinite;
			}
		}

		/**
			Indicates the `RenderBounds` have changed and need to be recalculated.
			
			This implies `InvalidateVisual`.
		*/
		protected void InvalidateRenderBounds()
		{
			InvalidateVisual();
			
			var p = this;
			while (p != null)
			{
				if (p.OnInvalidateRenderBounds())
					break;

				p = p.Parent;
			}
		}

		protected virtual bool OnInvalidateRenderBounds()
		{
			//return true to stop invalidation propagation (indicating it is already invalid)
			return false;
		}

		//TODO: could be replaced with VisualBounds.MergeChild probably (to centralize this logic)
		internal VisualBounds CalcRenderBoundsInParentSpace()
		{
			return VisualBounds.Empty.MergeChild( this, LocalRenderBounds );
		}
	}
}
