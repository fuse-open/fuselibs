namespace Fuse.Drawing.Primitives
{
	public block Quad
	{
		public float3 Position: float3(-1, -1, 0);
		public float2 Size: float2(2, 2);

		float2[] Vertices : new [] {float2(0,0),float2( 1,0),float2( 1, 1),float2(0, 1)};
		ushort[] Indices : new ushort[] { 0,1,2,2,3,0 };
		VertexCount : 6;
		float2 VertexData : vertex_attrib(Vertices, Indices);

		public float3 VertexPosition: float3(VertexData.XY * Size + Position.XY, 0);
		public float3 VertexNormal: float3(0, 0, 1);

		ClipPosition : prev, float4(VertexPosition, 1);

		public float2 TexCoord : float2(VertexData.X, 1.0f - VertexData.Y);
	}

	public block WireQuad
	{
		public float3 Position: float3(-1, -1, 0);
		public float2 Size: float2(2, 2);

		float2[] Vertices : new [] {float2(0,0),float2( 1,0),float2( 1, 1),float2(0, 1)};
		ushort[] Indices : new ushort[] { 0,1,2,3,0 };
		VertexCount : 6;
		float2 VertexData : vertex_attrib(Vertices, Indices);

		public float3 VertexPosition: float3(VertexData.XY * Size + Position.XY, 0);
		public float3 VertexNormal: float3(0, 0, 1);

		ClipPosition : prev, float4(VertexPosition, 1);

		PrimitiveType: Uno.Graphics.PrimitiveType.LineStrip;

		public float2 TexCoord : float2(VertexData.X, 1.0f - VertexData.Y);
	}
}
