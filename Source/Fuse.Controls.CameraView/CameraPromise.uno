using Uno;
using Uno.Threading;

namespace Fuse.Controls
{
	/*
		Most camera methods are async. Consumers
		of the CameraView API should not need to
		care about threading. Use CameraPromse
		to enusre all futures are resolved or
		rejected on the UI thread
	*/
	internal class CameraPromise<T> : Promise<T>
	{
		public CameraPromise() : base(UpdateManager.Dispatcher) {}
	}
}
