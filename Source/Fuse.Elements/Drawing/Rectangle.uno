using Uno;
using Fuse.Drawing;

namespace Fuse.Elements.Internal
{
	class ElementDraw
	{
		static public ElementDraw Impl = new ElementDraw();
		
		public void Rectangle(DrawContext dc, Element element, float2 offset, float2 size, float4 color)
		{
			draw Fuse.Drawing.Planar.Rectangle
			{
				DrawContext: dc;
				Visual: element;
				Size: size;
				Position: offset;
				PixelColor: color;
			};
		}
	}
}