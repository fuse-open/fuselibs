using Uno;
using Uno.Graphics;
using Uno.Collections;

namespace Fuse.Elements
{
	internal class ElementBatchEntry
	{
		public ElementBatchEntry(Element elm)
		{
			_elm = elm;
			_opacity = GetEffectiveOpacity();
		}

		float GetEffectiveOpacity()
		{
			if (_elm.Visibility == Visibility.Visible)
			        return _elm.Opacity;
			return 0.0f;
		}

		public void InvalidateVisual()
		{
			_atlas.InvalidateElement(_elm);
		}

		public void InvalidateVisualComposition()
		{
			float opacity = GetEffectiveOpacity();

			if (_opacity != opacity)
			{
				if (_batch != null)
					_batch.InvalidateOpacity(_elm);

				_opacity = opacity;
			}
		}

		public void InvalidateRenderBounds()
		{
			if (_batch != null)
			{
				_batch._elementBatcher._reinsertCheckList.Add(this);
				_batch.InvalidateRenderBounds(_elm);
			}
		}

		public void InvalidateTransform()
		{
			if (_batch != null)
				_batch.InvalidateTransform(_elm);
		}

		public void OnRemoved()
		{
			if (_atlas != null)
				_atlas.RemoveElement(_elm);

			if (_batch != null)
				_batch.RemoveElement(_elm);
		}

		public ElementAtlas _atlas;
		public ElementBatch _batch;
		public readonly Element _elm;
		public Recti AtlasRect;
		public int2 DrawingOffset;
		public float _opacity;
		public bool IsValid;
	}

	internal class ElementBatch : IElementBatchDrawable
	{
		public readonly ElementBatcher _elementBatcher;
		public readonly ElementAtlas _elementAtlas;

		bool _indexBufferValid, _vertexPositionBufferValid, _vertexTexCoordBufferValid;
		IndexBuffer _indexBuffer;
		VertexAttributeInfo _positionInfo;
		VertexAttributeInfo _texCoordInfo;
		int _prevElementCount;

		public ElementBatch(ElementBatcher elementBatcher, ElementAtlas elementAtlas)
		{
			_elementBatcher = elementBatcher;
			_elementAtlas = elementAtlas;

			_positionInfo = new VertexAttributeInfo();
			_positionInfo.BufferOffset = 0;
			_positionInfo.BufferStride = sizeof(float3);
			_positionInfo.Type = VertexAttributeType.Float3;
			_positionInfo.Buffer = new VertexBuffer(BufferUsage.Dynamic);

			_texCoordInfo = new VertexAttributeInfo();
			_texCoordInfo.BufferOffset = 0;
			_texCoordInfo.BufferStride = sizeof(float2);
			_texCoordInfo.Type = VertexAttributeType.Float2;
			_texCoordInfo.Buffer = new VertexBuffer(BufferUsage.Immutable);
		}

		public void Dispose()
		{
			foreach (var elm in _elements)
				elm._batch = null;

			if (_positionInfo.Buffer != null)
				_positionInfo.Buffer.Dispose();

			if (_texCoordInfo.Buffer != null)
				_texCoordInfo.Buffer.Dispose();

			if (_indexBuffer != null)
				_indexBuffer.Dispose();
		}

		internal static Recti ConservativelySnapToCoveringIntegers(Rect r)
		{
			// To prevent translations from affecting the size, round off origin and size
			// separately. And because origin might be rounded down while size not, we need
			// to add one to the width to be sure.

			int2 origin = (int2)Math.Floor(r.Minimum);
			int2 size = (int2)Math.Ceil(r.Size + 0.01f);
			return new Recti(origin.X,
			                 origin.Y,
			                 origin.X + size.X + 1,
			                 origin.Y + size.Y + 1);
		}

		public static Recti GetCachingRect(Element elm)
		{
			var bounds = elm.RenderBoundsWithEffects;
			if (bounds.IsInfinite || bounds.IsEmpty)
				throw new Exception( "element has no caching rect" );

			const int CachingRectPadding = 1;
			
			return Recti.Inflate(ConservativelySnapToCoveringIntegers(Rect.Scale(bounds.FlatRect,
				elm.AbsoluteZoom)), CachingRectPadding);
		}

		Box GetRenderBounds(Element elm)
		{
			var t = elm.InternLocalTransformInternal;
			return VisualBounds.BoxTransform((Box)elm.LocalRenderBounds, t);
		}

		VisualBounds CalcRenderBounds()
		{
			if (_elements.Count == 0) return VisualBounds.Empty;

			var box = GetRenderBounds(_elements[0]._elm);
			for (int i = 1; i < _elements.Count; i++)
			{
				var b = GetRenderBounds(_elements[i]._elm);
				if (b.Minimum.X < box.Minimum.X) box.Minimum.X = b.Minimum.X;
				if (b.Minimum.Y < box.Minimum.Y) box.Minimum.Y = b.Minimum.Y;
				if (b.Minimum.Z < box.Minimum.Z) box.Minimum.Z = b.Minimum.Z;
				if (b.Maximum.X > box.Maximum.X) box.Maximum.X = b.Maximum.X;
				if (b.Maximum.Y > box.Maximum.Y) box.Maximum.Y = b.Maximum.Y;
				if (b.Maximum.Z > box.Maximum.Z) box.Maximum.Z = b.Maximum.Z;
			}
			return VisualBounds.Box(box);
		}

		VisualBounds _renderBounds;
		public VisualBounds RenderBounds
		{
			get
			{
				if (_renderBounds == null)
				{
					_renderBounds = CalcRenderBounds();
				}
				return _renderBounds;
			}
		}

		List<ElementBatchEntry> _elements = new List<ElementBatchEntry>();
		public void AddElement(Element elm)
		{
			if (elm.ElementBatchEntry._atlas != _elementAtlas)
				throw new Exception("wrong atlas, stupid!");

			var entry = elm.ElementBatchEntry;
			entry._batch = this;
			_elements.Add(entry);
			_indexBufferValid = false;
			_vertexPositionBufferValid = false;
			_vertexTexCoordBufferValid = false;
			_renderBounds = null;
		}

		public void RemoveElement(Element elm)
		{
			if (elm.ElementBatchEntry._batch != this)
				throw new Exception("wrong batch, stupid!");

			var entry = elm.ElementBatchEntry;
			entry._batch = null;
			_elements.Remove(entry);
			_indexBufferValid = false;
			_vertexPositionBufferValid = false;
			_vertexTexCoordBufferValid = false;
		}

		public void InvalidateRenderBounds(Element elm)
		{
			_vertexPositionBufferValid = false;
			_vertexTexCoordBufferValid = false;
			_renderBounds = null;
		}

		internal void InvalidateTransform(Element elm)
		{
			_vertexPositionBufferValid = false;
			_renderBounds = null;
		}

		internal void InvalidateOpacity(Element elm)
		{
			_vertexPositionBufferValid = false;
		}

		Buffer _tempBuffer;

		public void Draw(DrawContext dc, float4x4 localToClipTransform, Rect scissorRectInClipSpace)
		{
			Rect visibleRect = Rect.Transform(RenderBounds.FlatRect, localToClipTransform);
			if (!scissorRectInClipSpace.Intersects(visibleRect))
				return;

			var fb = _elementAtlas.PinAndValidateFramebuffer(dc);

			if (_prevElementCount != _elements.Count)
			{
				_indexBufferValid = false;
				_vertexPositionBufferValid = false;
				_vertexTexCoordBufferValid = false;

				_tempBuffer = new Buffer(_elements.Count * 4 * sizeof(float3));
			}

			if (!_indexBufferValid)
			{
				FillIndexBuffer();
				_indexBufferValid = true;
			}

			if (!_vertexPositionBufferValid)
			{
				FillVertexPositionBuffer(dc);
				_vertexPositionBufferValid = true;
			}

			if (!_vertexTexCoordBufferValid)
			{
				FillVertexTexCoordBuffer();
				_vertexTexCoordBufferValid = true;
			}

			Texture2D tex = fb.ColorBuffer;
			float4x4 transform = dc.GetLocalToClipTransform(_elements[0]._elm.Parent);
			draw
			{
				VertexCount: _elements.Count * 6;
				CullFace: dc.CullFace;
				DepthTestEnabled: false;
				apply Fuse.Drawing.PreMultipliedAlphaCompositing;

				float3 Data: vertex_attrib<float3>(_positionInfo.Type, _positionInfo.Buffer, _positionInfo.BufferStride, _positionInfo.BufferOffset, IndexType.UShort, _indexBuffer);

				float2 Coord: Data.XY;
				float Opacity: Data.Z;
				float2 TexCoord: vertex_attrib<float2>(_texCoordInfo.Type, _texCoordInfo.Buffer, _texCoordInfo.BufferStride, _texCoordInfo.BufferOffset, IndexType.UShort, _indexBuffer);
				TexCoord: float2(prev TexCoord.X, 1.0f - prev TexCoord.Y);
				ClipPosition: Vector.Transform(float4(Coord, 0, 1), transform);
				ClipPosition: Opacity > 0 ? prev : float4(0, 0, 0, -1);
				PixelColor: sample(tex, TexCoord, SamplerState.LinearClamp) * Opacity;
			};
			_elementAtlas.Unpin();
			_prevElementCount = _elements.Count;
		}

		public bool IsFull()
		{
			return _elements.Count * 6 >= UShort.MaxValue;
		}

		void FillIndexBuffer()
		{
			var indices = new Buffer(_elements.Count * 6 * sizeof(ushort));
			for (int i = 0; i < _elements.Count; ++i)
			{
				indices.Set((i * 6 + 0) * sizeof(ushort), (ushort)(i * 4 + 0));
				indices.Set((i * 6 + 1) * sizeof(ushort), (ushort)(i * 4 + 2));
				indices.Set((i * 6 + 2) * sizeof(ushort), (ushort)(i * 4 + 1));
				indices.Set((i * 6 + 3) * sizeof(ushort), (ushort)(i * 4 + 0));
				indices.Set((i * 6 + 4) * sizeof(ushort), (ushort)(i * 4 + 3));
				indices.Set((i * 6 + 5) * sizeof(ushort), (ushort)(i * 4 + 2));
			}

			if (_indexBuffer != null)
				_indexBuffer.Dispose();

			_indexBuffer = new IndexBuffer(indices, BufferUsage.Immutable);
		}

		const float CachingRectPaddingAdjustment = 0.5f;

		void FillVertexTexCoordBuffer()
		{
			var elementCount = _elements.Count;
			var vertexTexCoords = _tempBuffer;

			for (int i = 0; i < elementCount; ++i)
			{
				var entry = _elements[i];

				float2 texCoordOrigin = ((float2)entry.AtlasRect.Minimum + CachingRectPaddingAdjustment) / _elementAtlas._rectPacker.Size;
				float2 size = ((float2)entry.AtlasRect.Size - CachingRectPaddingAdjustment * 2) / _elementAtlas._rectPacker.Size;
				vertexTexCoords.Set((i * 4 + 0) * _texCoordInfo.BufferStride + _texCoordInfo.BufferOffset, texCoordOrigin);
				vertexTexCoords.Set((i * 4 + 1) * _texCoordInfo.BufferStride + _texCoordInfo.BufferOffset, texCoordOrigin + float2(size.X, 0));
				vertexTexCoords.Set((i * 4 + 2) * _texCoordInfo.BufferStride + _texCoordInfo.BufferOffset, texCoordOrigin + size);
				vertexTexCoords.Set((i * 4 + 3) * _texCoordInfo.BufferStride + _texCoordInfo.BufferOffset, texCoordOrigin + float2(0, size.Y));
			}
			_texCoordInfo.Buffer.Update(vertexTexCoords);
		}

		void FillVertexPositionBuffer(DrawContext dc)
		{
			var elementCount = _elements.Count;
			var vertexPositions = _tempBuffer;

			float densityScale = 1.0f / dc.ViewportPixelsPerPoint;
			for (int i = 0; i < elementCount; ++i)
			{
				var entry = _elements[i];
				var opacity = entry._opacity;

				var transform = entry._elm.LocalTransform;
				//this calculation assumes the transform is flat (a precondition to caching the element)
				float2 localOrigin = ((float2)entry.DrawingOffset + CachingRectPaddingAdjustment) * densityScale;
				float2 positionOrigin = transform[3].XY + localOrigin.X * transform[0].XY + localOrigin.Y * transform[1].XY;
				float2 size = ((float2)entry.AtlasRect.Size - CachingRectPaddingAdjustment * 2) * densityScale;
				float2 right = transform[0].XY * size.X;
				float2 up = transform[1].XY * size.Y;
				vertexPositions.Set((i * 4 + 0) * _positionInfo.BufferStride + _positionInfo.BufferOffset, float3(positionOrigin, opacity));
				vertexPositions.Set((i * 4 + 1) * _positionInfo.BufferStride + _positionInfo.BufferOffset, float3(positionOrigin + right, opacity));
				vertexPositions.Set((i * 4 + 2) * _positionInfo.BufferStride + _positionInfo.BufferOffset, float3(positionOrigin + right + up, opacity));
				vertexPositions.Set((i * 4 + 3) * _positionInfo.BufferStride + _positionInfo.BufferOffset, float3(positionOrigin + up, opacity));
			}
			_positionInfo.Buffer.Update(vertexPositions);
		}
	}
}
