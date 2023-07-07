using System.Windows;
using Fuse.Profiling;

namespace TestApp
{
	class Program
	{
		static void Main(string[] args)
		{
			var host = new Host();
			var profiler = new Profiler(Application.Current.Dispatcher.Invoke);

			while (true)
			{
				host.AcceptProfileClient(profiler);
			}
		}
	}
}
