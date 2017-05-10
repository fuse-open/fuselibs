using Uno.Collections;

namespace Fuse
{
	public class Toast
	{
		static List<Toast> _queue = new List<Toast>();
		static Toast _ongoing;

		Visual _visual;
		double _duration;

		Toast(Visual visual, double duration)
		{
			_visual = visual;
			_duration = duration;
		}

		static void DispatchNext(Node ignoreNode)
		{
			if (_ongoing != null)
			{
				//in case it's been short-circuited somehow, force the cleanup
				AppBase.Current.ChildrenVisual.BeginRemoveVisual(_ongoing._visual);
				_ongoing = null;
			}

			if (_queue.Count == 0) return;

			_ongoing = _queue[0];
			_queue.RemoveAt(0);

			AppBase.Current.Children.Insert(0, _ongoing._visual);

			if (_ongoing._duration > 0) Timer.Wait(_ongoing._duration, _ongoing.Dismiss);
		}

		public static void OnUnrooted(Visual toast)
		{
			_ongoing = null;
			DispatchNext(null);
		}

		public void Dismiss()
		{
			if (_queue.Contains(this))
				_queue.Remove(this);

			if (_ongoing == this)
			{
				if (AppBase.Current.Children.Contains(_visual))
				{
					//there may be multiple calls to Dismiss prior to DispatchNext resolving
					_ongoing = null;
					AppBase.Current.ChildrenVisual.BeginRemoveVisual(_visual, DispatchNext);
				}
				else
					DispatchNext(null);
			}
			else
			{
				AppBase.Current.ChildrenVisual.BeginRemoveVisual(_visual);
			}
		}

		public static Toast Post(Visual visual, double duration = -1)
		{
			var t = new Toast(visual, duration);
			_queue.Add(t);
			if (_ongoing == null) DispatchNext(null);

			return t;
		}
	}
}
