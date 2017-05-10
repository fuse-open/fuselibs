using Uno;
using Uno.Graphics;
using OpenGL;
using Fuse.Elements;
using Fuse.Controls.Graphics;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Android
{

	extern (Android) internal class TextUtils
	{
		public enum TruncateAt
		{
			End = 0,
			Marquee,
			Middle,
			Start,
		}
	}

}