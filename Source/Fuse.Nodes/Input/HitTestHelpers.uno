using Uno;
using Uno.Collections;

namespace Fuse.Input
{
	class SelectionQuery
	{
		HitTestResult _result;

		public HitTestResult Select(Visual root, float2 point)
		{
			var args = new HitTestContext(point, Select);
			root.HitTest(args);
			args.Dispose();
			return _result;
		}

		int count =0;
		void Select(HitTestResult result)
        {
			count++;
			if (_result == null || 
				(_result.HasHitDistance && result.HasHitDistance && result.HitDistance < _result.HitDistance) )
				_result = result;
        }
	}
	

	public static class HitTestHelpers
	{
		public static HitTestResult HitTestNearest(Visual root, float2 point)
		{
			var sq = new SelectionQuery();
			return sq.Select(root, point);
		}
	}
}