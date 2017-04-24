using Uno;
using Uno.Collections;

namespace Fuse
{
	public delegate void HitTestCallback(HitTestResult result);

	/** Represents the computed results of a particular intersection found during
		hit testing. */
	public class HitTestResult
	{
		public bool HasHitDistance { get; internal set; }
		public float HitDistance { get; internal set; }
		public Visual HitObject { get; internal set; }
	}

	/** Holds common information needed while traversing a visual tree to perform
		hit testing. */
	public class HitTestContext
	{
		public float2 WindowPoint { get; private set; }

        float2 _localPoint;
        public float2 LocalPoint { get { return _localPoint; } }

        public float2 PushLocalPoint(float2 lp)
        {
			var r = _localPoint;
            _localPoint = lp;
            return r;
        }

        public void PopLocalPoint(float2 lp)
        {
			_localPoint = lp;
        }

        Ray _worldRay;
        public Ray WorldRay { get { return _worldRay; } }
        
        public Ray PushWorldRay(Ray n)
        {
			var r = _worldRay;
			_worldRay = n;
			return r;
        }
        
        public void PopWorldRay(Ray o)
        {
			_worldRay = o;
        }

        HitTestCallback _callback;
        public HitTestCallback Callback
        {
            get { return _callback; }
        }

		public void Hit(Visual obj)
        {
			if (Callback != null)
				Callback(new HitTestResult
					{
                		HitObject = obj
            		}
				);
        }

        public void Hit(Visual obj, float hitDistance)
        {
			if (Callback != null)
				Callback(new HitTestResult
					{
	                	HitObject = obj,
	                	HasHitDistance = true,
	                	HitDistance = hitDistance
	                }
				);
        }

		public HitTestContext(float2 windowPoint, HitTestCallback callback)
		{
			WindowPoint = windowPoint;
			_localPoint = windowPoint;
			_callback = callback;
		}

        public void Dispose()
        {
            _callback = null;
        }
    }

}
