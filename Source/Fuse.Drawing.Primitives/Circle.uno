using Uno;
using Uno.Graphics;

using Fuse;
using Fuse.Elements;
using Fuse.Drawing.Internal;
using Fuse.Nodes;

namespace Fuse.Drawing.Primitives
{
	abstract class LimitCoverage
	{
	}
	
	class OneLimitCoverage : LimitCoverage
	{
		public float LimitCoverage: 1;
	}
	
	public class Circle 
	{
		static public Circle Singleton = new Circle();
		
		LimitCoverage _oneLimitCoverage = new OneLimitCoverage();
		StrokeCoverage _strokeCoverage = new StrokeCoverage();
		public void Stroke(DrawContext dc, Element visual, float radius, Stroke stroke, float2 center,
			float smoothness)
		{
			var r = stroke.GetDeviceAdjusted(dc.ViewportPixelsPerPoint);
			var sc = _strokeCoverage;
			sc.Radius = r[0]/2;
			sc.Center = r[1];

			//include outer region for stroke
			var extend = Math.Max(0,r[0]+r[1]) + smoothness;
			
			Draw(dc ,visual, radius, stroke.Brush, sc, _oneLimitCoverage,
				extend, center, smoothness );
		}
		
		FillCoverage _fillCoverage = new FillCoverage();
		public void Fill(DrawContext dc, Element visual, float radius, Brush brush, float2 center,
			float smoothness)
		{
			Draw(dc, visual, radius, brush, _fillCoverage, _oneLimitCoverage, smoothness,
				center, smoothness );
		}
		
		Float2Buffer _bufferVertex;
		UShortBuffer _bufferIndex;
		
		void InitBuffers()
		{
			_bufferVertex = new Float2Buffer();
			_bufferIndex = new UShortBuffer();
			
			var numSegments = 16;
			
			//need to go beyond unit segments to include rounded portion
			var theta = Math.PIf/2 - Math.PIf*2/numSegments;
			var len = 1 / Math.Sin(theta);
			
			_bufferVertex.Append(0,0);
			for( int i=0; i < numSegments; ++i )
			{
				var r = i / (float)numSegments * Math.PIf * 2;
				_bufferVertex.Append( Math.Cos(r) * len, Math.Sin(r) * len);
				
				_bufferIndex.Append(0);
				_bufferIndex.Append(i == (numSegments-1) ? 1 : i+2);
				_bufferIndex.Append(i+1);
			}
			
			_bufferVertex.InitDeviceVertex(BufferUsage.Immutable);
			_bufferIndex.InitDeviceIndex(BufferUsage.Immutable);
		}
		
		internal void Draw(DrawContext dc, Element visual, float radius, Brush brush,
			Coverage cover, LimitCoverage limit, float extend, float2 center, float smoothness )
		{
			if (radius <= 0)
				return;

			if (_bufferVertex == null)
				InitBuffers();

			float radiusRcp = 1.0f / radius;
			draw
			{
				apply Common;
				apply virtual cover;
				
				DrawContext: dc;
				Visual: visual;
				Size: float2(radius*2);
				CanvasSize: visual.ActualSize;
				
				float2 V0: vertex_attrib<float2>(VertexAttributeType.Float2, _bufferVertex.GetDeviceVertex(),
					2*4,0, IndexType.UShort, _bufferIndex.GetDeviceIndex() );
				VertexCount: _bufferIndex.Count();
				
				float2 VertexPosition: V0 * (radius + extend*2);
				LocalPosition: VertexPosition + center;
				// Mali-400 has FP16 max precision, which cannot square big numbers without overflowing.
				// So let's make sure the vector we do Length() always has a result in the 0..1 range, to
				// avoid overflowing.
				float2 VertexPositionScaled: VertexPosition * radiusRcp;
				float RawDistance: (Vector.Length(pixel VertexPositionScaled) - 1.0f) * radius;
				float2 EdgeNormal: Vector.Normalize(pixel V0);
				
				apply virtual brush;
				apply CommonBrush;
				Smoothness: smoothness;
				
				apply virtual limit;
				Coverage: prev * LimitCoverage;
			};

			// Circles don't actually draw as rectangles, but this is a good-enough-to-be-useful(-and-testable) approximation.
			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
			{
				float2 elementPos = float2(0);
				float2 elementSize = visual.ActualSize;
				float minSize = Math.Min(elementSize.X, elementSize.Y);
				float2 offset = elementPos + elementSize / 2.0f - minSize / 2.0f;
				float2 size = float2(minSize);
				DrawRectVisualizer.Capture(offset, size, visual.WorldTransform, dc);
			}
		}
	}
}
