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

		void InvalidateWorldTransform()
		{
			_worldTransformVersion++;
			if (_worldTransform != null || _worldTransformInverse != null)
			{
				_worldTransform = null;
				_worldTransformInverse = null;
			}
			
			if (_worldTransformInvalidated != null)
				_worldTransformInvalidated(this, EventArgs.Empty);

			if (_wtiListeners > 0) 
			{
				for (var i = 0; i < Children.Count; i++)
				{
					var v = Children[i] as Visual;
					if (v != null) v.InvalidateWorldTransform();
				}
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

				if (_worldTransformInvalidated == null && Parent != null)
					DecrementWTIListener();
			}
		}

		void WTIRooted()
		{
			if (_wtiListeners != 0) throw new Exception(); // should never happen
			
			if (_worldTransformInvalidated != null)
				IncrementWTIListener();
		}

		void WTIUnrooted()
		{
			if (_worldTransformInvalidated != null)
				DecrementWTIListener();

			if (_wtiListeners != 0) throw new Exception(); // should never happen
		}
	}
}