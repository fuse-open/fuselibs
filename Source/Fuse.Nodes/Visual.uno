using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	public class RequiresRootedException : Exception {}

	public enum VisualContext
	{
		Unknown,
		Graphics,
		Native
	}

	/** Visuals are nodes with a visual representation.

		@topic Visual

		This is the base class of all visual objects within an app, both objects with actual
		visual appearance and invisible objects that contain other visuals. Examples of visuals
		are @Rectangle, @Panel, @Button and @WebView.

		Visuals manage pointer input for an area of the screen and respond accordingly. 
		The area for which the visual receives pointer input is determined by the @HitTest
		method. The area does not need to be a rectangular area, it can be any complex shape.

		Visuals can have many different types of children, including other visuals, @Behaviors,
		and @Transforms. The @Children has a certain order which is the order in which the children
		are laid out during layout. This order is by default is identical to the Z-order. However, 
		the Z-order can be manipulated separately from the child-order.

		Visuals can have input focus if the `Focus.IsFocusable` property is set to `true`. 
	*/
	public abstract partial class Visual : Node, IList<Node>, IPropertyListener
	{

		public virtual VisualContext VisualContext 
		{ 
			get 
			{ 
				if defined(!Mobile) return VisualContext.Graphics;
				if (Parent != null) return Parent.VisualContext; 
				else return VisualContext.Unknown;
			}
		}

		public Fuse.Controls.Native.ViewHandle ViewHandle { get; internal set; }

		// TODO: used by Input.Focus, pack these away somehow
		internal bool _isFocusable;
		internal Visual _focusDelegate;

		public virtual void OnPropertyChanged(PropertyObject sender, Selector property)
		{
			// Do nothing, meant for overriding
		}


		public virtual void OnIsSelectedChanged(bool isSelected)
		{
			
		}

		double _drawCost;

		public double DrawCost { get { return _drawCost; }}

		public void AddDrawCost(double cost)
		{
			var p = this;
			while (p != null)
			{
				p._drawCost += cost;
				p = p.Parent;
			}
		}

		public void RemoveDrawCost(double cost)
		{
			var p = this;
			while (p != null)
			{
				p._drawCost -= cost;
				p = p.Parent;
			}
		}

		IViewport _viewport;
		protected override void OnRooted()
		{
			base.OnRooted();

			UpdateIsContextEnabledCache();
			UpdateIsVisibleCache();
			UpdateContextSnapToPixelsCache();

			OnRootedPreChildren();

			if (HasChildren)
			{
				// iterate over a copy of the list to prevent problems when
				// behaviors add/remove childen during rooting
				using (var iter = _children.GetEnumeratorVersionedStruct())
				{
					while (iter.MoveNext())
						iter.Current.RootInternal(this);
				}
			}

			//this forces an invalidation now that we're rooted (ensures no old stale value is there)
			_layoutDirty = InvalidateLayoutReason.NothingChanged;
			_hasMarginBox = false;
			InvalidateLayout();
			_ambLayoutParams.Reset();

			_viewport = FindViewport();
			RootTemplates();
			RootResources();
		}

		internal protected virtual void OnRootedPreChildren() { }
		
		protected override void OnUnrooted()
		{
			base.OnUnrooted();

			UnrootResources();
			UnrootTemplates();
			_viewport = null;

			ResetParameterListeners();

			if (Input.Focus.FocusedVisual == this)
				Input.Focus.Release();

			ConcludePendingRemove();

			if (HasChildren)
			{
				// iterate over a copy of the list to prevent problems when
				// behaviors add/remove childen during rooting
				using (var iter = _children.GetEnumeratorVersionedStruct())
				{
					while (iter.MoveNext())
						iter.Current.UnrootInternal();
				}
			}

			ConcludePendingRemove();
		}

		public override void VisitSubtree(Action<Node> action)
		{
			action(this);
			for (int i = 0; i < Children.Count; i++) 
				Children[i].VisitSubtree(action);
		}

		public T FindByType<T>() where T : Visual
		{
			if (this is T) return this as T;
			return GetNearestAncestorOfType<T>();
		}

		public T GetNearestAncestorOfType<T>() where T : Visual
		{
			Visual current = Parent;
			while(current != null)
			{
				if(current is T) return current as T;
				current = current.Parent;
			}
			return null;
		}

		/**
			Converts a coordinate from the parent space into the local space.
			
			@param result The result will be stored here. It is undefined if the return is `false`
			@return true if the result is defined, false is the calculation could not be performed.
		*/
		public virtual bool TryParentToLocal(float2 parentPoint, out float2 result)
		{
			var t = LocalTransformInverseInternal;
			result = Vector.TransformCoordinate(parentPoint, t.Matrix);
			return t.IsValid;
		}

		/**
			Converts a coordinate from the local space into the parent space.
		*/
		public virtual float2 LocalToParent(float2 localPoint)
		{
			localPoint = Vector.TransformCoordinate(localPoint, LocalTransform);
			return localPoint;
		}

		public IViewport FindViewport()
		{
			var p = this;

			while (p != null)
			{
				var vp = p as IViewport;
				if (vp != null) return vp;
				p = p.Parent;
			}

			return null;
		}

		public IViewport Viewport
		{
			get { return _viewport ?? FindViewport(); }
		}
	}
}
