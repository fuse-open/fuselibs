using Uno;
using Uno.Compiler;
using Uno.Testing;

using OpenGL;

using Fuse;

namespace FuseTest
{
	public class TestFramebuffer : IDisposable
	{
		internal TestFramebuffer(int2 size)
		{
			Framebuffer = FramebufferPool.Lock(size, Uno.Graphics.Format.RGBA8888, true);
		}

		public void Dispose()
		{
			FramebufferPool.Release(Framebuffer);
		}

		/**
			Reads a pixel form the captured framebuffer.

			0, 0 is in the top-left corner, like in the rest of Fuselibs.
		*/
		public float4 ReadDrawPixel(int2 pos)
		{
			var prevFramebuffer = GL.GetFramebufferBinding();
			GL.BindFramebuffer(GLFramebufferTarget.Framebuffer, Framebuffer.RenderTarget.GLFramebufferHandle);

			try
			{
				var temp = new byte[4];
				GL.ReadPixels(pos.X, Framebuffer.Size.Y - 1 - pos.Y, 1, 1, GLPixelFormat.Rgba, GLPixelType.UnsignedByte, temp);
				return float4(temp[0] / 255.0f,
					temp[1] / 255.0f,
					temp[2] / 255.0f,
					temp[3] / 255.0f);
			}
			finally
			{
				GL.BindFramebuffer(GLFramebufferTarget.Framebuffer, prevFramebuffer);
			}
		}
		public float4 ReadDrawPixel(int x, int y) { return ReadDrawPixel( int2(x,y) ); }

		public void AssertSolidRectangle(Recti rect, float4 expectedColor, float tolerace = float.ZeroTolerance, [CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			for (int y = rect.Minimum.Y; y < rect.Maximum.Y; ++y)
			{
				for (int x = rect.Minimum.X; x < rect.Maximum.X; ++x)
				{
					var pos = int2(x, y);
					var color = ReadDrawPixel(pos);
					var diff = Math.Abs(color - expectedColor);
					if (Vector.Length(diff) > tolerace)
						Assert.Fail(string.Format("Unexpected color at [{0}]. Got [{1}], expected [{2}].", pos, color, expectedColor), filePath, lineNumber, memberName);
				}
			}
		}

		public readonly framebuffer Framebuffer;
	}
}
