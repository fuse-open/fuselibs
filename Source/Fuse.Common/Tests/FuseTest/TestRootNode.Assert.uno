using Uno;
using Uno.Compiler;

using Uno.Testing;

namespace FuseTest
{
	public partial class TestRootPanel
	{
		public void AssertSolidRectangle(Recti rect, float4 expectedColor, [CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			if (_captureFB == null)
				throw new Exception("TestRootPanel.CaptureDraw() must be called before TestRootPanel.AssertSolidRectangle");

			for (int y = rect.Minimum.Y; y < rect.Maximum.Y; ++y)
			{
				for (int x = rect.Minimum.X; x < rect.Maximum.X; ++x)
				{
					var color = ReadDrawPixel(int2(x, y));
					var diff = Math.Abs(color - expectedColor);
					if (Vector.Length(diff) > float.ZeroTolerance)
						Assert.Fail(string.Format("Unexpected color at [{0}, {1}]. Got [{2}], expected [{3}].", x, y, color, expectedColor), filePath, lineNumber, memberName);
				}
			}
		}
	}
}
