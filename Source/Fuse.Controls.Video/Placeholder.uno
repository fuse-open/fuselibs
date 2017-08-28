using Uno;
using Uno.IO;
using Uno.UX;

namespace Fuse.Controls.VideoImpl
{

	extern(!Mobile) static class Placeholder
	{
		static readonly BundleFile _placeHolder = import("placeholder.png");

		public static FileSource File
		{
			get { return  (FileSource)_placeHolder; }
		}
	}
}
