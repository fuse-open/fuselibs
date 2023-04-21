using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Controls.Internal
{
	internal struct Line
	{
		public readonly float2 From;
		public readonly float2 To;
		public readonly float Width;
		public readonly float4 Color;

		public Line(float2 from, float2 to, float width, float4 color)
		{
			From = from;
			To = to;
			Width = width;
			Color = color;
		}

		public Line Scale(float scale)
		{
			return new Line(From * scale, To * scale, Width * scale, Color);
		}
	}

	internal struct Circle
	{
		public readonly float2 Center;
		public readonly float Radius;
		public readonly float4 Color;

		public Circle(float2 center, float radius, float4 color)
		{
			Center = center;
			Radius = radius;
			Color = color;
		}

		public Circle Scale(float scale)
		{
			return new Circle(Center * scale, Radius * scale, Color);
		}
	}

	internal class Stroke
	{
		public readonly List<Line> Lines = new List<Line>();
		public readonly List<Circle> Circles = new List<Circle>();

		public Stroke Scale(float scale)
		{
			var stroke = new Stroke();
			foreach (var line in Lines)
				stroke.Lines.Add(line.Scale(scale));
			foreach (var circle in Circles)
				stroke.Circles.Add(circle.Scale(scale));
			return stroke;
		}
	}
}