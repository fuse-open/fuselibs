using Uno;

using Fuse;

namespace FuseTest
{
	public sealed class Invoke : Behavior
	{
		public event VisualEventHandler Handler;
		
		public void Perform()
		{
			if (Handler != null)
				Handler(this, new VisualEventArgs(Parent) );
		}
	}
}