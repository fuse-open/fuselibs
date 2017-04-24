using System;
using System.Runtime.InteropServices;

namespace OpenGL
{
	public class GL
	{
		[DllImport("opengl32.dll", EntryPoint = "glGenTextures", ExactSpelling = true)]
		public extern static void GenTextures(Int32 n, [OutAttribute] UInt32[] textures);

		[DllImport("opengl32.dll", EntryPoint = "glBindTexture", ExactSpelling = true)]
		public extern static void BindTexture(TextureTarget target, UInt32 texture);

		[DllImport("opengl32.dll", EntryPoint = "glTexImage2D", ExactSpelling = true)]
		public extern static void TexImage2D(TextureTarget target, Int32 level, PixelInternalFormat internalFormat, Int32 width, Int32 height, Int32 border, PixelFormat format, PixelType type, IntPtr data);

		[DllImport("opengl32.dll", EntryPoint = "glTexSubImage2D", ExactSpelling = true)]
		public extern static void TexSubImage2D(TextureTarget target, Int32 level, Int32 xoffset, Int32 yoffset, Int32 width, Int32 height, PixelFormat format, PixelType type, IntPtr pixels);

		[DllImport("opengl32.dll", EntryPoint = "glDeleteTextures", ExactSpelling = true)]
		public extern static void DeleteTextures(Int32 n, UInt32[] textures);
	}
}
