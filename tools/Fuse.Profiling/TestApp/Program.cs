using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Fuse.Profiling;

namespace TestApp
{
	class Program
	{
		static void Main(string[] args)
		{
			var host = new Host();
			var profiler = new Profiler();

			while (true)
			{
				host.AcceptProfileClient(profiler);
			}

			Console.ReadKey(true);
		}

		

	}
}
