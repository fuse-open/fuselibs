using Uno;
using Uno.PerformanceTesting;
using Fuse;
using Fuse.Elements;
using Fuse.Controls;

namespace Caching
{
	public partial class Performance : App
	{
		int _frames = -2; // the first few frames warm up caches etc
		double _minFrameDuration = Double.MaxValue;
		double _maxFrameDuration = Double.MinValue;
		double _avgFrameDuration = 0;
		float2 _wantedScrollPos, _prevScrollPos;

		protected override void OnUpdate()
		{
			if (_scrollView.ScrollPosition.Equals(_wantedScrollPos))
			{
				var mid = _scrollView.MinScroll + (_scrollView.MaxScroll - _scrollView.MinScroll) * 0.5f;
				if (_scrollView.ScrollPosition.Y > mid.Y)
					_wantedScrollPos = float2(0, _scrollView.MinScroll.Y);
				else
					_wantedScrollPos = float2(0, _scrollView.MaxScroll.Y);
				_scrollView.Goto(_wantedScrollPos);
			}

			if (_frames == 0)
				_scrollView.Goto(float2(0, _scrollView.MaxScroll.Y));

			if (_frames++ < 0)
				return;

			var frameDuration = PreviousDrawDuration;
			_minFrameDuration = Math.Min(_minFrameDuration, frameDuration);
			_maxFrameDuration = Math.Max(_maxFrameDuration, frameDuration);
			_avgFrameDuration += frameDuration;

			if (_frames == 100)
			{
				PerformanceTester.LogAppStarted();
				PerformanceTester.LogTestDescription("scrolling huge list");
				PerformanceTester.LogTimeInterval("min-duration", "minimum frame duration", _minFrameDuration);
				PerformanceTester.LogTimeInterval("max-duration", "maximum frame duration", _maxFrameDuration);
				PerformanceTester.LogTimeInterval("avg-duration", "avarage frame duration", _avgFrameDuration / _frames);
				PerformanceTester.CompleteTest();
			}
		}
	}
}
