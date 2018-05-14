using Uno;
using Uno.Threading;

namespace Fuse.Controls
{
	internal static class FutureExtensions
	{
		class InterceptClosure<T>
		{
			Action _callback;

			public InterceptClosure(Action callback) { _callback = callback; }
			public void OnResolve(T result) { _callback(); }
			public void OnReject(Exception e) { _callback(); }
		}

		public static Future<T> Intercept<T>(this Future<T> future, Action callback)
		{
			var i = new InterceptClosure<T>(callback);
			future.Then(i.OnResolve, i.OnReject);
			return future;
		}

		class OnRejectedClosure
		{
			Action _callback;
			public OnRejectedClosure(Action callback) { _callback = callback; }
			public void OnReject(Exception e) { _callback(); }
		}

		public static Future<T> InvokeOnRejected<T>(this Future<T> future, Action callback)
		{
			var o = new OnRejectedClosure(callback);
			future.Catch(o.OnReject);
			return future;
		}
	}
}
