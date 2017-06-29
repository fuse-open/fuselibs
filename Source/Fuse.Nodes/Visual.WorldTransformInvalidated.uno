using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Matrix;

namespace Fuse
{
	/*
		This file implements the WorldTransformInvalidated event and calls the OnInvalidateWorldTransform method, 
		which due to optimizations can not be generated the intuitive way anymore. 

		The implementation is based on counting how many listeners there are in the subtree, at rooting time.
		This allows us to traverse the precise path down to the listeners instead of traversing the entire
		subtree, as well as early-out immedtiately if there are no listeners in the subtree.
	*/

	public partial class Visual
	{
		int _wtiListeners;
		void IncrementWTIListener()
		{
			_wtiListeners++;
			if (Parent != null) Parent.IncrementWTIListener();
		}

		void DecrementWTIListener()
		{
			_wtiListeners--;
			if (Parent != null) Parent.DecrementWTIListener();
		}

		void RaiseWTI()
		{
			if (_wtiListeners == 0) return;

			OnInvalidateWorldTransform();

			for (var i = 0; i < Children.Count; i++)
			{
				var v = Children[i] as Visual;
				if (v != null) v.RaiseWTI();
			}
		}

		event EventHandler _worldTransformInvalidated;
		/** @advanced
		*/
		public event EventHandler WorldTransformInvalidated
		{
			add 
			{ 
				if (_worldTransformInvalidated == null && IsRootingStarted)
					IncrementWTIListener();

				_worldTransformInvalidated += value;
			}
			remove 
			{ 
				_worldTransformInvalidated -= value;

				if (_worldTransformInvalidated == null && IsRootingStarted)
					DecrementWTIListener();
			}
		}

		void WTIRooted()
		{
			if (_worldTransformInvalidated != null)
				IncrementWTIListener();
		}

		void WTIUnrooted()
		{
			if (_worldTransformInvalidated != null)
				DecrementWTIListener();
		}
		
		protected virtual void OnInvalidateWorldTransform() 
		{ 
			if (_worldTransformInvalidated != null)
				_worldTransformInvalidated(this, EventArgs.Empty);
		}

	}
}