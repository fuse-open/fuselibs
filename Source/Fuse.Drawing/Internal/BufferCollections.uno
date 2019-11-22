//em: taken from my game code initially (thus style difference)
using Uno; 
using Fuse;
using Uno.Graphics;
using Uno.Collections;

namespace Fuse.Drawing.Internal {

	/**
		Provides a type-friendly wrapper for buffers and device buffers.
		
		This also provides a logical collection on top of the buffer. The "Count", "Reset", and
		"Append" functions work on this logical set. The buffer will be dynamically resized as necessary.
		
		The "Set" operation is directly on the buffer and ignores the logical set.
		
		UNO: This is really ugly now. I can't figure out how to make this generic on the type.
		Thus each type needs its own derived class! (NOTE: I've just removed the generic for now)
	*/
	public class TypedBuffer {
		protected byte[] back;
		protected int typeSize;
		//how many items can be stored in back
		protected int capacity;
		//how many items are in the virtual list
		protected int size;
		
		protected TypedBuffer( int typeSize, int initSize = 32 ) {
			this.typeSize = typeSize;
			this.size = 0;
			Init( initSize );
		}
		
		protected void Init( int initSize ) {
			this.capacity = initSize;
			back = new byte[typeSize * initSize];
		}
		
		protected TypedBuffer() {
			this.typeSize = 0;
			this.capacity = 0;
			this.size = 0;
			back = new byte[0];
		}
		
		IndexBuffer deviceIndex = null;
		/**
			Creates a device index buffer for this buffer.
		*/
		public void InitDeviceIndex( BufferUsage bu = BufferUsage.Dynamic ) {
			deviceIndex = new IndexBuffer( back, bu );
		}
		public IndexBuffer GetDeviceIndex() {
			return deviceIndex;
		}
		
		VertexBuffer deviceVertex = null;
		public void InitDeviceVertex( BufferUsage bu = BufferUsage.Dynamic ) {
			deviceVertex = new VertexBuffer( back, bu );
		}
		public VertexBuffer GetDeviceVertex() {
			return deviceVertex;
		}
		
		public void UpdateDevice() {
			if( deviceIndex != null ) {
				deviceIndex.Update( back );
			} 
			if( deviceVertex != null ) {
				deviceVertex.Update( back );
			}
		}
		
		public int Count() {
			return size;
		}
		
		public byte[] GetBytes() {
			return back;
		}
		
		/**
			Copy an item to the underlying buffer. This does not do any 
			bounds checks, nor dynamic resizing. The bounds will be checked by
			the underlying Buffer.
			
			UNO: Uncertain how this can be done.
		*/
		/*void Set( int offset, T value ) {
			back.Set( offset * typeSize, value, true );
		}*/
		
		protected void CheckGrow() {
			if( size < capacity ) {
				return;
			}
			int newCap = capacity * 2;
			var newBuf = new byte[typeSize * newCap];
			for( int i=0; i < back.Length; ++i ) {
				newBuf.Set( i, back[i] );
			}
			back = newBuf;
			capacity = newCap;
		}
		
		public void Clear() {
			size = 0;
		}
		
	}
	
	public class Float3Buffer : TypedBuffer {
		public Float3Buffer() : base( 3 * 4 ) {
		}
		
		public void Set( int offset, float3 value ) {
			back.Set( offset * typeSize, value, true );
		}
		
		public void Append( float3 value ) {
			CheckGrow();
			Set( size++, value );
		}
		
		public void Append( double x, double y, double z ) {
			Append( float3( (float)x, (float)y, (float)z ) );
		}
	}
	
	public class FloatBuffer : TypedBuffer {
		public FloatBuffer() : base( 4 ) {
		}
		
		public void Set( int offset, float value ) {
			back.Set( offset * typeSize, value, true );
		}
		
		public void Append( float value ) {
			CheckGrow();
			Set( size++, value );
		}
		
		public void Append( double x ) {
			Append( (float)x );
		}
	}
	
	public class Float2Buffer : TypedBuffer {
		public Float2Buffer() : base( 2 * 4 ) {
		}
		
		public void Set( int offset, float2 value ) {
			back.Set( offset * typeSize, value, true );
		}
		
		public void Append( float2 value ) {
			CheckGrow();
			Set( size++, value );
		}
		
		public void Append( double x, double y ) {
			Append( float2( (float)x, (float)y ) );
		}
	}
	
	public class UShortBuffer : TypedBuffer {
		public UShortBuffer() : base( 2 ) {
		}
		
		public void Set( int offset, ushort value ) {
			back.Set( offset * typeSize, value, true );
		}
		
		public void Append( ushort value ) {
			CheckGrow();
			Set( size++, value );
		}
		
		public void Append( int value ) {
			CheckGrow();
			Set( size++, (ushort)value );
		}
		
		public void AppendTri( int a, int b, int c ) {
			Append( (ushort)a );
			Append( (ushort)b );
			Append( (ushort)c );
		}
	}
	
	public class MultiBuffer : TypedBuffer {
		public class Field {
			public Uno.Graphics.VertexAttributeType Type;
			public int Offset;
			
			public MultiBuffer _owner;
			
			public VertexBuffer Buffer {
				get { 
					return _owner.GetDeviceVertex();
				}
			}
			public int Stride {
				get {
					return _owner.Stride;
				}
			}
		}
	
		public MultiBuffer() {
		}

		public int Stride {
			get {
				return typeSize;
			}
		}
	
		List<Field> fields = new List<Field>();
		Field Alloc( Uno.Graphics.VertexAttributeType type, int size ) {
			Field f = new Field{
				Type = type,
				Offset = typeSize,
				_owner = this,
			};
			typeSize += size;
			fields.Add( f );
			return f;
		}
		
		public Field AllocFloat() {
			return Alloc( Uno.Graphics.VertexAttributeType.Float, 4 );
		}
		public Field AllocFloat2() {
			return Alloc( Uno.Graphics.VertexAttributeType.Float2, 8 );
		}
		public Field AllocFloat3() {
			return Alloc( Uno.Graphics.VertexAttributeType.Float3, 12 );
		}
		public Field AllocFloat4() {
			return Alloc( Uno.Graphics.VertexAttributeType.Float4, 16 );
		}
		public Field AllocUShort() {
			return Alloc( Uno.Graphics.VertexAttributeType.UShort, 2 );
		}
		//UNO: no VertexAttributeType.Byte
		//public Field AllocByte() {
		//	return Alloc( Uno.Graphics.VertexAttributeType.Byte, 1 );
		//}
		
		public void EndAlloc() {
			Init( 32 );
		}
		
		int offset;
		
		public void AppendOpen() {
			CheckGrow();
			offset = 0;
		}
		public void AppendEnd() {
			size++;
		}
		
		public void AppendUShort( ushort value ) {
			back.Set( size * typeSize + offset, value, true );
			offset += 2;
		}
		public void AppendUShort( int value ) {
			AppendUShort( (ushort)value );
		}
		public void AppendUShortNF( float value ) {
			AppendUShort( (ushort)( Math.Clamp( value, 0, 1 ) * UShort.MaxValue ) );
		}
		
		public void AppendFloat( double value ) {
			back.Set( size * typeSize + offset, (float)value, true );
			offset += 4;
		}
		
		public void AppendFloat2( float2 value ) {
			back.Set( size * typeSize + offset, value, true );
			offset += 8;
		}
		public void AppendFloat2( double x, double y ) {
			AppendFloat2( float2( (float)x, (float)y ) );
		}
		
		public void AppendFloat3( float3 value ) {
			back.Set( size * typeSize + offset, value, true );
			offset += 12;
		}
		public void AppendFloat3( double x, double y, double z ) {
			AppendFloat3( float3( (float)x, (float)y, (float)z ) );
		}
		
		public void AppendFloat4( float4 value ) {
			back.Set( size * typeSize + offset, value, true );
			offset += 16;
		}
		
		public void AppendByte( byte value ) {
			back.Set( size * typeSize + offset, value, true );
			offset += 1;
		}
		//normalized floating point stored in byte
		public void AppendByteNF( float value ) {
			AppendByte( (byte)( Math.Clamp( value * 255, 0, 255 ) ) );
		}

		//allows chain setting of the fields (safely, the Append nonsense is deperecated)
		public class Setter {
			MultiBuffer owner;
			int index, baseP;
			
			public Setter( MultiBuffer owner, int index ) {
				this.owner = owner;
				this.index = index;
				this.baseP = index * owner.typeSize;
			}
			
			public Setter SetFloat3( Field f, float3 v ) {
				owner.back.Set( baseP + f.Offset, v, true );
				return this;
			}
			public Setter SetFloat2( Field f, float2 v ) {
				owner.back.Set( baseP + f.Offset, v, true );
				return this;
			}
			public Setter SetFloat( Field f, float v ) {
				owner.back.Set( baseP + f.Offset, v, true );
				return this;
			}
		}
		public Setter Add() {
			CheckGrow();
			var s = new Setter( this, size );
			size++;
			return s;
		}
	}
}
