using Uno;
using Uno.Threading;

namespace Fuse.Controls
{
	internal static class PromiseExtensions
	{
		public static Future<T> RejectWithMessage<T>(this Promise<T> promise, string message)
		{
			promise.Reject(new Exception(message));
			return promise;
		}
	}
}
