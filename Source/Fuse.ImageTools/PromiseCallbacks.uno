using Uno.Threading;
using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Scripting;
namespace Fuse.ImageTools
{
	internal sealed class ImagePromiseCallback
	{
		Promise<Image> _p;
		public ImagePromiseCallback(Promise<Image> p)
		{
			_p = p;
		}

		public void Resolve(string path)
		{
			_p.Resolve(new Image(path));
		}

		public void Reject(string reason)
		{
			_p.Reject(new Exception(reason));
		}
	}

	internal sealed class BoolPromiseCallback
	{
		Promise<bool> _p;
		public BoolPromiseCallback(Promise<bool> p)
		{
			_p = p;
		}

		public void Resolve()
		{
			_p.Resolve(true);
		}

		public void Reject(string reason)
		{
			_p.Reject(new Exception(reason));
		}
	}

	internal sealed class PromiseCallback<T>
	{
		Promise<T> _p;
		public PromiseCallback(Promise<T> p)
		{
			_p = p;
		}

		public void Resolve(T v)
		{
			_p.Resolve(v);
		}

		public void Reject(string reason)
		{
			_p.Reject(new Exception(reason));
		}
	}
}
