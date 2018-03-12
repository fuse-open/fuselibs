using System;

namespace Fuse.Video.CILInterface
{
	public interface IGL
	{
		void BindTexture(int target, int texture);

		void TexImage2D(int target, int level, int internalFormat, int width, int height, int border, int format, int type, IntPtr data);

		void TexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, IntPtr pixels);
	}
}
