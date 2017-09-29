using Uno;

using Fuse;

namespace FuseTest
{
	/** Maintains a static count of how often this has been initialized. */
	public sealed class InstanceCounter : Behavior
	{
		static int _count = 0;
		public static int Count 
		{
			get { return _count; }
		}
		
		public static void Reset()
		{
			_count = 0;
		}
		
		public InstanceCounter()
		{
			_count++;
		}
	}
}