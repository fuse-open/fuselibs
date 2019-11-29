using Fuse.Text.Bidirectional;
using Uno.Collections;
using Uno.Graphics;
using Uno.Threading;
using Uno;

namespace Fuse.Text
{
	public struct GlyphTexture
	{
		public SubTexture SubTexture { get; private set; }
		public readonly float2 Offset;
		public readonly float Scale;

		internal GlyphTexture(SubTexture subTexture, float2 offset, float scale)
		{
			SubTexture = subTexture;
			Offset = offset;
			Scale = scale;
		}

		internal static GlyphTexture Invalid = new GlyphTexture();

		internal bool IsValid { get { return Scale != 0.0f; } }
	}

	public class PositionedRun
	{
		public readonly ShapedRun ShapedRun;
		public Run Run { get { return ShapedRun.Run; } }
		public readonly float2 Position;
		public readonly float2 Measurements;

		public PositionedRun(ShapedRun shapedRun, float2 position, float2 measurements)
		{
			ShapedRun = shapedRun;
			Position = position;
			Measurements = measurements;
		}

		public static PositionedRun Translate(PositionedRun positionedRun, float2 translation)
		{
			return new PositionedRun(
				positionedRun.ShapedRun,
				positionedRun.Position + translation,
				positionedRun.Measurements);
		}
	}

	struct Quad
	{
		public readonly float2 Position;
		public readonly Recti TexCoords;
		public readonly float Scale;
		public readonly Rect Rect;

		public Quad(float2 position, Recti texCoords, float scale)
		{
			Position = position;
			TexCoords = texCoords;
			Scale = scale;
			Rect = new Rect(Position, (float2)TexCoords.Size * Scale);
		}
	}

	struct Batch : IDisposable
	{
		public readonly int TextureIndex;
		public readonly VertexBuffer VertexBuffer;
		public readonly int QuadCount;

		public Batch(int textureIndex, VertexBuffer vbo, int quadCount)
		{
			TextureIndex = textureIndex;
			Renderer.SharedIndexBuffer.EnsureSize(quadCount);
			VertexBuffer = vbo;
			QuadCount = quadCount;
		}

		public void Dispose()
		{
			VertexBuffer.Dispose();
		}
	}

	public class Renderer : IDisposable
	{
		static int _glyphAtlasVersion;
		static readonly int2 _minimumGlyphAtlasSize = int2(512, 512); // Chosen by fair dice roll.
		static GlyphAtlas _glyphAtlas = new GlyphAtlas(_minimumGlyphAtlasSize);
		static object _glyphAtlasMutex = new object();

		internal static void RecreateGlyphAtlas(int version)
		{
			lock (_glyphAtlasMutex)
			{
				if (version == _glyphAtlasVersion) // otherwise it's already been done
				{
					++_glyphAtlasVersion;
					_glyphAtlas.Dispose();
					_glyphAtlas = new GlyphAtlas(_minimumGlyphAtlasSize);
				}
			}
		}

		readonly Font _font;
		readonly List<List<PositionedRun>> _positionedRuns;
		readonly int _approximateGlyphCount;
		int _version;

		List<List<Quad>> _texturedQuads;
		List<Batch> _batches;

		public Renderer(Font font, List<List<PositionedRun>> positionedRuns, int approximateGlyphCount)
		{
			_font = font;
			_positionedRuns = positionedRuns;
			_approximateGlyphCount = approximateGlyphCount;

			SharedIndexBuffer.Retain();
		}

		public void Dispose()
		{
			DisposeBatches();
			SharedIndexBuffer.Release();
			_texturedQuads = null;
		}

		void DisposeBatches()
		{
			if (_batches != null)
			{
				foreach (var batch in _batches)
					batch.Dispose();
				_batches = null;
			}
		}

		public void Draw(float4 color, float4x4 pixelToClipSpaceMatrix)
		{
			color = float4(color.XYZ * color.W, color.W);
			lock (_glyphAtlasMutex)
			{
				var batches = GetBatches();

				_glyphAtlas.Commit();

				var textures = _glyphAtlas.Textures;
				foreach (var batch in batches)
				{
					var texture = textures[batch.TextureIndex];
					bool grayScale = texture.Format == Format.L8;
					var indexBuffer = SharedIndexBuffer.IndexBuffer;

					draw
					{
						apply Fuse.Drawing.PreMultipliedAlphaCompositing;

						CullFace: PolygonFace.None;
						VertexCount: batch.QuadCount * 6;

						public float2 Position: vertex_attrib<float2>(
							VertexAttributeType.Float2,
							batch.VertexBuffer,
							sizeof(float2) + sizeof(ushort2),
							0,
							IndexType.UShort,
							indexBuffer);
						public float2 TexCoord: vertex_attrib<float2>(
							VertexAttributeType.UShort2Normalized,
							batch.VertexBuffer,
							sizeof(float2) + sizeof(ushort2),
							sizeof(float2),
							IndexType.UShort,
							indexBuffer);

						ClipPosition: Vector.Transform(float4(Position, 0, 1), pixelToClipSpaceMatrix);
						float4 sampleColor: sample(texture, TexCoord, SamplerState.LinearClamp);
						PixelColor: grayScale ? color * float4(sampleColor.X) : sampleColor * color.W;
					};
				}
			}
		}

		List<Batch> GetBatches()
		{
			var texturedQuads = GetTexturedQuads();

			if (_batches != null)
				return _batches;

			var len = texturedQuads.Count;
			_batches = new List<Batch>(len);
			var textures = _glyphAtlas.Textures;
			for (int i = 0; i < len; ++i)
			{
				var quads = texturedQuads[i];
				var quadCount = quads.Count;
				if (quadCount > 0)
				{
					var vertexBuffer = new VertexBuffer(BufferUsage.Stream);
					vertexBuffer.Update(CreateVertexBufferData(quads, textures[i].Size));

					_batches.Add(new Batch(i, vertexBuffer, quadCount));
				}
			}
			return _batches;
		}

		List<List<Quad>> GetTexturedQuads()
		{
			if (_texturedQuads == null || _version != _glyphAtlasVersion)
			{
				DisposeBatches();
				_version = _glyphAtlasVersion;
				_texturedQuads = TexturedQuads(_font, _positionedRuns, _approximateGlyphCount);
			}
			return _texturedQuads;
		}

		static List<List<Quad>> TexturedQuads(Font font, List<List<PositionedRun>> positionedRuns, int approximateGlyphCount)
		{
			lock (_glyphAtlasMutex)
			{
				var textures = _glyphAtlas.Textures;
				var textureCount = textures.Count;
				var textureBatches = new List<List<Quad>>(textureCount + 1);
				for (int i = 0; i < textureCount; ++i)
					textureBatches.Add(new List<Quad>(approximateGlyphCount));

				foreach (var line in positionedRuns)
				{
					foreach (var positionedRun in line)
					{
						float2 position = positionedRun.Position;
						var shapedRun = positionedRun.ShapedRun;
						var positionedGlyphs = shapedRun._parent;
						var end = shapedRun._start + shapedRun.Count;
						// This is faster as a for than a foreach loop
						for (int i = shapedRun._start; i < end; ++i)
						{
							var positionedGlyph = positionedGlyphs[i];
							var glyph = positionedGlyph.Glyph;
							var glyphTexture = font.GetCachedGlyphTexture(glyph, _glyphAtlas, _glyphAtlasVersion);
							if (glyphTexture.IsValid)
							{
								var textureIndex = glyphTexture.SubTexture.TextureIndex;
								// The number of textures can grow as we fill the atlas
								while (textureIndex >= textureBatches.Count)
									textureBatches.Add(new List<Quad>(approximateGlyphCount));

								textureBatches[glyphTexture.SubTexture.TextureIndex].Add(
									new Quad(
										position + positionedGlyph.Offset + glyphTexture.Offset,
										glyphTexture.SubTexture.Rect,
										glyphTexture.Scale));
							}
							position += positionedGlyph.Advance;
						}
					}
				}

				return textureBatches;
			}
		}

		internal static class SharedIndexBuffer
		{
			static int _length = 0;
			static int _refCount = 0;
			public static IndexBuffer IndexBuffer = null;

			public static void Retain()
			{
				++_refCount;
				if (IndexBuffer == null)
					IndexBuffer = new IndexBuffer(BufferUsage.Stream);
			}

			public static void EnsureSize(int length)
			{
				if (length > _length)
				{
					_length = Math.Max(length, _length * 2);
					IndexBuffer.Update(CreateIndexBufferData(_length));
				}
			}

			public static void Release()
			{
				--_refCount;
				if (_refCount == 0 && IndexBuffer != null)
				{
					IndexBuffer.Dispose();
					IndexBuffer = null;
					_length = 0;
				}
			}
		}

		static byte[] CreateIndexBufferData(int length)
		{
			var stride = sizeof(ushort) * 6;
			var buffer = new byte[stride * length];
			for (int i = 0; i < length; ++i)
			{
				var bufferPos = i * stride;
				var index = i * 4;
				buffer.Set(bufferPos + sizeof(ushort) * 0, (ushort)(index + 0));
				buffer.Set(bufferPos + sizeof(ushort) * 1, (ushort)(index + 1));
				buffer.Set(bufferPos + sizeof(ushort) * 2, (ushort)(index + 2));
				buffer.Set(bufferPos + sizeof(ushort) * 3, (ushort)(index + 2));
				buffer.Set(bufferPos + sizeof(ushort) * 4, (ushort)(index + 3));
				buffer.Set(bufferPos + sizeof(ushort) * 5, (ushort)(index + 0));
			}
			return buffer;
		}

		static byte[] CreateVertexBufferData(List<Quad> quads, int2 texSize)
		{
			var stride = sizeof(float2) + sizeof(ushort2);
			var quadStride = 4 * stride;
			var length = quads.Count;
			var buffer = new byte[quadStride * length];

			for (int i = 0; i < length; ++i)
			{
				var quad = quads[i];
				var bufferPos = i * quadStride;

				var rect = quad.Rect;
				var rectLeft = rect.Left;
				var rectTop = rect.Top;
				var rectRight = rect.Right;
				var rectBottom = rect.Bottom;

				var texCoord = quad.TexCoords.Position * ushort2(ushort.MaxValue, ushort.MaxValue) / texSize;
				var texCoordSize = quad.TexCoords.Size * ushort2(ushort.MaxValue, ushort.MaxValue) / texSize;
				var texLeft = (ushort)texCoord.X;
				var texTop = (ushort)texCoord.Y;
				var texRight = (ushort)(texCoord.X + texCoordSize.X);
				var texBottom = (ushort)(texCoord.Y + texCoordSize.Y);

				var littleEndian = true;

				buffer.Set(bufferPos, rectLeft, littleEndian);
				bufferPos += sizeof(float);
				buffer.Set(bufferPos, rectTop, littleEndian);
				bufferPos += sizeof(float);

				buffer.Set(bufferPos, texLeft, littleEndian);
				bufferPos += sizeof(ushort);
				buffer.Set(bufferPos, texTop, littleEndian);
				bufferPos += sizeof(ushort);

				buffer.Set(bufferPos, rectRight, littleEndian);
				bufferPos += sizeof(float);
				buffer.Set(bufferPos, rectTop, littleEndian);
				bufferPos += sizeof(float);

				buffer.Set(bufferPos, texRight, littleEndian);
				bufferPos += sizeof(ushort);
				buffer.Set(bufferPos, texTop, littleEndian);
				bufferPos += sizeof(ushort);

				buffer.Set(bufferPos, rectRight, littleEndian);
				bufferPos += sizeof(float);
				buffer.Set(bufferPos, rectBottom, littleEndian);
				bufferPos += sizeof(float);

				buffer.Set(bufferPos, texRight, littleEndian);
				bufferPos += sizeof(ushort);
				buffer.Set(bufferPos, texBottom, littleEndian);
				bufferPos += sizeof(ushort);

				buffer.Set(bufferPos, rectLeft, littleEndian);
				bufferPos += sizeof(float);
				buffer.Set(bufferPos, rectBottom, littleEndian);
				bufferPos += sizeof(float);

				buffer.Set(bufferPos, texLeft, littleEndian);
				bufferPos += sizeof(ushort);
				buffer.Set(bufferPos, texBottom, littleEndian);
				bufferPos += sizeof(ushort);
			}
			return buffer;
		}
	}
}
