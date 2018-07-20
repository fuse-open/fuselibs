using Uno;
using Uno.Graphics;

using Fuse;
using Fuse.Elements;
using Fuse.Drawing.Internal;
using Fuse.Nodes;

namespace Fuse.Drawing.Primitives
{
	block Common
	{
		public DrawContext DrawContext: undefined;
		public Visual Visual: null;
		public float2 Size: float2(1);
		public float2 CanvasSize: float2(1);
		public float2 LocalPosition: undefined;

		ClipPosition: req(LocalPosition as float2)
			Vector.Transform( LocalPosition, DrawContext.GetLocalToClipTransform(Visual));
		CullFace: DrawContext.CullFace;
		DepthTestEnabled: false;
		public float2 TexCoord: LocalPosition / CanvasSize;
	}
	
	block CommonBrush
	{
		public float Smoothness: 1f;
		public float Sharpness: (1f/Smoothness);
		public float Coverage: req(EdgeDistance as float) req(DrawContext as DrawContext)
			Math.Clamp(0.5f-pixel EdgeDistance*DrawContext.ViewportPixelsPerPoint*Sharpness, 0, 1);
		public float4 FinalColor: req(Coverage as float) req(FinalColor as float4)
			prev * Coverage;
	}

	abstract class Coverage
	{
	}

	class FillCoverage : Coverage
	{
		public float EdgeDistance: req(RawDistance as float)
			RawDistance;
	}

	class StrokeCoverage : Coverage
	{
		public float Radius = 1;
		public float Center = 0;

	    public float EdgeDistance: req(RawDistance as float)
			Math.Abs(RawDistance-Center) - Radius;
	}

	class Falloff
	{

	}

	class ShadowFalloff : Falloff
	{
		public float Coverage: req(Coverage as float)
			prev * prev * prev * (prev * (prev * 6 - 15) + 10);
	}


	public class Rectangle
	{
		static public Rectangle Singleton = new Rectangle();

		StrokeCoverage _strokeCoverage = new StrokeCoverage();
		public void Stroke(DrawContext dc, Visual visual, float2 Size, float4 CornerRadius, Stroke stroke,
			float2 Position = float2(0), float Smoothness = 1)
		{
			var r = stroke.GetDeviceAdjusted(dc.ViewportPixelsPerPoint);
			var sc = _strokeCoverage;
			sc.Radius = r[0]/2;
			sc.Center = r[1];

			//include outer region for stroke
			var extend = Math.Max(0,r[0]+r[1]) + Smoothness;
			
			Draw(dc ,visual, Size, CornerRadius, stroke.Brush, sc,
				float2(extend), Position, Smoothness );
		}

		FillCoverage _fillCoverage = new FillCoverage();
		public void Fill(DrawContext dc, Visual visual, float2 Size, float4 CornerRadius, Brush brush,
			float2 Position = float2(0), float Smoothness = 1 )
		{
			Draw(dc, visual, Size, CornerRadius, brush, _fillCoverage,
				float2(Smoothness), Position, Smoothness );
		}

		Falloff _shadowFalloff = new ShadowFalloff();
		public void Shadow(DrawContext dc, Visual visual, float2 Size, float4 CornerRadius, Brush brush,
			float2 Position = float2(0), float Smoothness = 1 )
		{
			Draw(dc, visual, Size, CornerRadius, brush, _fillCoverage,
				float2(Smoothness), Position, Smoothness, _shadowFalloff );
		}

		float[] add(float[] a, float[] b)
		{
			var r = new float[a.Length];
			for(int i=0; i < a.Length; i++)
				r[i] = a[i] + b[i];
			return r;
		}
		
		float[] sub(float[] a, float[] b)
		{
			var r = new float[a.Length];
			for(int i=0; i < a.Length; i++)
				r[i] = a[i] - b[i];
			return r;
		}
		
		float[] neg(float[] a)
		{
			var r = new float[a.Length];
			for(int i=0; i < a.Length; i++)
				r[i] = -a[i];
			return r;
		}
		
		float sum_mul(float[] a, float[] b)
		{
			var r = 0f;
			for(int i=0; i < a.Length; i++)
				r += a[i] * b[i];
			return r;
		}

		VertexAttributeInfo _vertexInfo, _edgeInfo;
		FloatBuffer _bufferDistance;
		
		void InitBuffers()
		{
			_bufferDistance = new FloatBuffer();
			
			var CornerRadius0 = new float[]{1,0,0,0, 0,0, 0,0, 0 };
			var CornerRadius1 = new float[]{0,1,0,0, 0,0, 0,0, 0 };
			var CornerRadius2 = new float[]{0,0,1,0, 0,0, 0,0, 0 };
			var CornerRadius3 = new float[]{0,0,0,1, 0,0, 0,0, 0 };
			var SizeX = new float[]{0,0,0,0, 1,0, 0,0, 0 };
			var SizeY = new float[]{0,0,0,0, 0,1, 0,0, 0 };
			var ExtendX = new float[]{0,0,0,0, 0,0, 1,0, 0 };
			var ExtendY = new float[]{0,0,0,0, 0,0, 0,1, 0 };
			var Mn = new float[]{0,0,0,0, 0,0, 0,0, 1 };
				
			var vr = new []{
				CornerRadius0, add(SizeY,ExtendY),
				sub(SizeX,CornerRadius1), add(SizeY,ExtendY),

				neg(ExtendX), sub(SizeY, CornerRadius0),
				CornerRadius0, sub(SizeY, CornerRadius0 ),
				sub( SizeX, CornerRadius1), sub(SizeY, CornerRadius1 ),
				add( SizeX, ExtendX), sub(SizeY, CornerRadius1 ),

				Mn, sub(SizeY,Mn),
				sub( SizeX, Mn), sub(SizeY, Mn),
				Mn, Mn,
				sub( SizeX, Mn), Mn,

				neg(ExtendX), CornerRadius3,
				CornerRadius3, CornerRadius3,
				sub(SizeX, CornerRadius2), CornerRadius2,
				add(SizeX, ExtendX), CornerRadius2,

				CornerRadius3, neg(ExtendY),
				sub(SizeX, CornerRadius2), neg(ExtendY),

				//
				neg(ExtendX), add(SizeY, ExtendY),
				add(SizeX,ExtendX), add(SizeY,ExtendY),
				neg(ExtendX), neg(ExtendY),
				add(SizeX, ExtendX), neg(ExtendY),

				//
				Mn, sub(SizeY,CornerRadius0),
				sub(SizeX,Mn), sub(SizeY,CornerRadius1),
				Mn,CornerRadius3,
				sub(SizeX,Mn),CornerRadius2,

				CornerRadius0, sub(SizeY,Mn),
				sub(SizeX,CornerRadius1), sub(SizeY,Mn),
				CornerRadius3,Mn,
				sub(SizeX,CornerRadius2), Mn,
			};
			
			var offsets = new float2[vr.Length];
			for (int i = 0 ; i < vr.Length; ++i)
			{
				var offset = int2(0, 0);
				var v = vr[i];
				for (int j = 0 ; j < v.Length; ++j)
				{
					float f = v[j];
					if (f != 0.0f) {
						if (offset.Y != 0)
							throw new Exception("more than two non-zero values!");
						var o = 1 + j;
						offset = int2(f < 0 ? -o : o, offset.X);
					}
				}
				offsets[i] = (float2)offset;
			}

			var vsr = new[]{
				//left
				10,8,11,
				10,6,8,
				10,2,6,
				2,3,6,
				//bottom
				14,11,8,
				14,8,15,
				8,9,15,
				9,12,15,
				//top
				3,0,6,
				0,1,6,
				6,1,4,
				6,4,7,
				//right
				7,4,5,
				7,5,9,
				9,5,13,
				9,13,12,

				//corner[0]
				2,16,3,
				3,16,0,
				//corner[1]
				1,17,4,
				4,17,5,
				//corner[2]
				15,12,19,
				12,13,19,
				//corner[3]
				11,18,10,
				14,18,11,
			};
			
			var ptr = new[]{
				//left
				22,8,22,
				22,6,8,
				22,20,6,
				20,20,6,
				//bottom
				26,26,8,
				26,8,27,
				8,9,27,
				9,27,27,
				//top
				24,24,6,
				24,25,6,
				6,25,25,
				6,25,7,
				//right
				7,21,21,
				7,21,9,
				9,21,23,
				9,23,23,
				
				//corners
				3,3,3,3,3,3,
				4,4,4,4,4,4,
				12,12,12,12,12,12,
				11,11,11,11,11,11,
			};
			
			var bufferVertex = new byte[vsr.Length * sizeof(float4)];
			var bufferEdge = new byte[vsr.Length * sizeof(float4)];

			_vertexInfo = new VertexAttributeInfo();
			_vertexInfo.BufferOffset = 0;
			_vertexInfo.BufferStride = sizeof(float4);
			_vertexInfo.Type = VertexAttributeType.Float4;
			_vertexInfo.Buffer = new VertexBuffer(BufferUsage.Immutable);

			_edgeInfo = new VertexAttributeInfo();
			_edgeInfo.BufferOffset = 0;
			_edgeInfo.BufferStride = sizeof(float4);
			_edgeInfo.Type = VertexAttributeType.Float4;
			_edgeInfo.Buffer = new VertexBuffer(BufferUsage.Immutable);

			for(int i=0; i < vsr.Length; ++i)
			{
				bufferVertex.Set( i * _vertexInfo.BufferStride, float4(offsets[vsr[i]*2], offsets[vsr[i]*2+1]) );
				bufferEdge.Set( i * _edgeInfo.BufferStride, float4(offsets[ptr[i]*2], offsets[ptr[i]*2+1]) );

				_bufferDistance.Append( (ushort)(1 + (i < (4*3*4) ? 8 /*mn*/ :
					i < (4*3*4+6) ? 0 /*CornerRadius[0]*/ :
					i < (4*3*4+12) ? 1 /*CornerRadius[1]*/ :
					i < (4*3*4+18) ? 2 /*CornerRadius[2]*/ : 3 /*CornerRadius[3]*/)) );
			}

			_vertexInfo.Buffer.Update(bufferVertex);
			_edgeInfo.Buffer.Update(bufferEdge);
			_bufferDistance.InitDeviceVertex(BufferUsage.Immutable);
		}

		float[] _uniforms = new float[10];
		void Draw(DrawContext dc, Visual visual, float2 Size, float4 CornerRadius, Brush brush,
			Coverage cover, float2 extend, float2 position, float smoothness, Falloff falloff = new Falloff() )
		{
			if (_bufferDistance == null)
				InitBuffers();

			var mn = Math.Min(Size.X/2, Size.Y/2);
			for (int i=0; i < 4; ++i)
				CornerRadius[i] = Math.Clamp(CornerRadius[i],0,mn);

			//adjust order of corners to be visually TopLeft, TopRight, BottomRight, BottomLeft
			_uniforms[0] = 0;
			_uniforms[1] = CornerRadius[3];
			_uniforms[2] = CornerRadius[2];
			_uniforms[3] = CornerRadius[1];
			_uniforms[4] = CornerRadius[0];
			_uniforms[5] = Size.X;
			_uniforms[6] = Size.Y;
			_uniforms[7] = extend.X;
			_uniforms[8] = extend.Y;
			_uniforms[9] = mn;

			// Mali-400 has FP16 max precision, which doesn't have big enough range to square
			// the biggest on-screen coordinates without overflowing. So let's just reduce the
			// range before squaring.
			float float16MaxValue = 65504;
			float distanceScale = Math.Max(1.0f, Math.Max(Size.X + extend.X, Size.Y + extend.Y) / Math.Sqrt(float16MaxValue * 0.5f));
			distanceScale = Math.Exp2(Math.Ceil(Math.Log2(distanceScale)));
			float distanceScaleRcp = 1.0f / distanceScale;

			var elm = visual as Element;
			var csz = elm == null ? float2(1) : elm.ActualSize;
			draw
			{
				apply Common;
				apply virtual cover;
				
				DrawContext: dc;
				Visual: visual;
				Size: local::Size;
				CanvasSize: csz;
				
				float[] Uniforms: _uniforms;

				float4 V : vertex_attrib<float4>(_vertexInfo.Type, _vertexInfo.Buffer, _vertexInfo.BufferStride, _vertexInfo.BufferOffset);
				float4 E : vertex_attrib<float4>(_edgeInfo.Type, _edgeInfo.Buffer, _edgeInfo.BufferStride, _edgeInfo.BufferOffset);
				float ED : vertex_attrib<float>(VertexAttributeType.Float, _bufferDistance.GetDeviceVertex(),4,0);

				VertexCount: _bufferDistance.Count();

				float2 VertexPosition: float2(
					Math.Sign(V.X) * Uniforms[(int)Math.Abs(V.X)] +
					Math.Sign(V.Y) * Uniforms[(int)Math.Abs(V.Y)],
					Math.Sign(V.Z) * Uniforms[(int)Math.Abs(V.Z)] +
					Math.Sign(V.W) * Uniforms[(int)Math.Abs(V.W)]);

				float2 VertexEdge: float2(
					Math.Sign(E.X) * Uniforms[(int)Math.Abs(E.X)] +
					Math.Sign(E.Y) * Uniforms[(int)Math.Abs(E.Y)],
					Math.Sign(E.Z) * Uniforms[(int)Math.Abs(E.Z)] +
					Math.Sign(E.W) * Uniforms[(int)Math.Abs(E.W)]);

				float2 Edge: VertexEdge + position;
				float EdgeBase: Uniforms[(int)ED];
				LocalPosition: VertexPosition + position;

				float2 EdgeScaled: Edge * distanceScaleRcp;
				float2 LocalPositionScaled: LocalPosition * distanceScaleRcp;

				float RawDistance: Vector.Distance(pixel LocalPositionScaled, EdgeScaled) * distanceScale - EdgeBase;
				float2 EdgeNormal: Vector.Normalize(pixel LocalPosition - Edge);
				
				apply virtual brush;
				apply CommonBrush;
				apply virtual falloff;
				Smoothness: smoothness;
			};

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(float2(0), local::Size, visual.WorldTransform, dc);
		}
	}
}
