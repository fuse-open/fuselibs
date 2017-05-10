using Uno;
using Uno.Graphics;
using OpenGL;
using Fuse.Elements;
using Fuse.Controls.Graphics;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Android
{

	extern (Android) internal class GLUtils
	{
		public static void TexImage2D(GLTextureTarget target, int level, Bitmap bitmap, int border)
		{
			TexImage2D((int)target, level, bitmap.Handle, border);
		}

		[Foreign(Language.Java)]
		static void TexImage2D(int target, int level, Java.Object bitmap, int border)
		@{
			android.opengl.GLUtils.texImage2D(target, level, ((android.graphics.Bitmap)bitmap), border);
		@}
	}

}