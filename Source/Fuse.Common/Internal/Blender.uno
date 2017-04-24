using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;

namespace Fuse.Internal
{
	//Ugly class trying to deal with generics in the mixer
	class BlenderMap
	{
		static Dictionary<Type, object> _blenders = new Dictionary<Type, object>();

		static public Blender<T> Get<T>()
		{
			object blender;
			if (!_blenders.TryGetValue(typeof(T), out blender))
			{
				if (typeof(T) == typeof(float))
					blender = new FloatBlender();
				else if (typeof(T) == typeof(float2))
					blender = new Float2Blender();
				else if (typeof(T) == typeof(float3))
					blender = new Float3Blender();
				else if (typeof(T) == typeof(float4))
					blender = new Float4Blender();
				else if (typeof(T) == typeof(double))
					blender = new DoubleBlender();
				else if (typeof(T) == typeof(Size))
					blender = new SizeBlender();
				else if (typeof(T) == typeof(Size2))
					blender = new Size2Blender();
				else
					throw new Exception( "Unsupported blender type: " + typeof(T) );
					
				_blenders.Add(typeof(T),blender);
			}
			
			return (Blender<T>)blender;
		}
		
		static Dictionary<Type, object> _scalarBlenders = new Dictionary<Type, object>();

		static public ScalarBlender<T> GetScalar<T>()
		{
			object blender;
			if (!_scalarBlenders.TryGetValue(typeof(T), out blender))
			{
				if (typeof(T) == typeof(float))
					blender = new FloatBlender();
				else if (typeof(T) == typeof(double))
					blender = new DoubleBlender();
				else
					throw new Exception( "Unsupported blender type: " + typeof(T) );
					
				_scalarBlenders.Add(typeof(T),blender);
			}
			
			return (ScalarBlender<T>)blender;
		}
	}
	
	abstract class Blender<T>
	{
		abstract public T Weight( T v, double w );
		abstract public T Add( T a, T b );
		abstract public T Sub( T a, T b );
		abstract public T Lerp( T a, T b, double d );
		abstract public T Zero { get; }
		abstract public T One { get; }
		abstract public T ToUnit( T a, out double length );
		abstract public double Length( T a );
		
		public T UnitWeight( T v, double w )
		{
			double l;
			var unit = ToUnit(v,out l);
			return Weight(unit, w );
		}
		public double Distance( T a, T b )
		{
			return Length( Sub( a, b ) );
		}
		
		//cleaner name in some cases
		public T ScalarMult( T v, double s ) { return Weight(v,s); }
	}
	
	class SizeBlender : Blender<Size>
	{
		public override Size Weight( Size v, double w ) { return v * (float)w; }
		public override Size Add( Size a, Size b ) { return a + b; }
		public override Size Sub( Size a, Size b ) { return a - b; }
		public override Size Lerp( Size a, Size b, double d )   { return a + (b - a) * (float)d; }
		public override Size Zero { get { return 0; } }
		public override Size One { get { return 1; } }
		public override Size ToUnit( Size a, out double length ) 
		{ 
			length = a.Value;
			return a.Value < 0 ? new Size(-1, a.Unit) : new Size(1, a.Unit); 
		}
		public override double Length( Size a ) { return Math.Abs(a.Value); }
	}

	class Size2Blender : Blender<Size2>
	{
		public override Size2 Weight( Size2 v, double w ) { return v * (float)w; }
		public override Size2 Add( Size2 a, Size2 b ) { return a + b; }
		public override Size2 Sub( Size2 a, Size2 b ) { return a - b; }
		public override Size2 Lerp( Size2 a, Size2 b, double d )   { return a + (b - a) * (float)d; }
		public override Size2 Zero { get { return float2(0,0); } }
		public override Size2 One { get { return float2(1,1); } }
		public override Size2 ToUnit( Size2 a, out double length ) 
		{ 
			length = Vector.Length((float2)a);
			var v = Vector.Normalize((float2)a);
			var x = a.X;
			var y = a.Y;
			return new Size2(new Size(v.X, x.Unit), new Size(v.Y, y.Unit));
		}
		public override double Length( Size2 a ) { return Vector.Length((float2)a); }
	}

	abstract class ScalarBlender<T> : Blender<T>
	{
		abstract public double ToDouble( T a );
		abstract public T FromDouble( double a );
	}
	
	class FloatBlender : ScalarBlender<float>
	{
		public override float Weight( float v, double w ) { return v * (float)w; }
		public override float Add( float a, float b ) { return a + b; }
		public override float Sub( float a, float b ) { return a - b; }
		public override float Lerp( float a, float b, double d )   { return a + (b - a) * (float)d; }
		public override float Zero { get { return 0; } }
		public override float One { get { return 1; } }
		public override float ToUnit( float a, out double length ) 
		{ 
			length = Math.Abs(a);
			return a < 0 ? -1 : 1; 
		}
		public override double Length( float a ) { return Math.Abs(a); }
		public override double ToDouble( float a ) { return a; }
		public override float FromDouble( double a) { return (float)a; }
	}
	
	class DoubleBlender : ScalarBlender<double>
	{
		public override double Weight( double v, double w ) { return v * w; }
		public override double Add( double a, double b ) { return a + b; }
		public override double Sub( double a, double b ) { return a - b; }
		public override double Lerp( double a, double b, double d )   { return a + (b - a) * d; }
		public override double Zero { get { return 0; } }
		public override double One { get { return 1; } }
		public override double ToUnit( double a, out double length ) 
		{ 
			length = Math.Abs(a);
			return a < 0 ? -1 : 1; 
		}
		public override double Length( double a ) { return Math.Abs(a); }
		public override double ToDouble( double a ) { return a; }
		public override double FromDouble( double a) { return a; }
	}
	
	class Float2Blender : Blender<float2>
	{
		public override float2 Weight( float2 v, double w ) { return v * (float)w; }
		public override float2 Add( float2 a, float2 b ) { return a + b; }
		public override float2 Sub( float2 a, float2 b ) { return a - b; }
		public override float2 Lerp( float2 a, float2 b, double d )   { return Math.Lerp(a,b,(float)d); }
		public override float2 Zero { get { return float2(0); } }
		public override float2 One { get { return float2(1); } }
		public override float2 ToUnit( float2 a, out double length ) 
		{
			length = Vector.Length(a);
			return Vector.Normalize(a);
		}
		public override double Length( float2 a ) { return Vector.Length(a); }
	}
	
	class Float3Blender : Blender<float3>
	{
		public override float3 Weight( float3 v, double w ) { return v * (float)w; }
		public override float3 Add( float3 a, float3 b ) { return a + b; }
		public override float3 Sub( float3 a, float3 b ) { return a - b; }
		public override float3 Lerp( float3 a, float3 b, double d )   { return Math.Lerp(a,b,(float)d); }
		public override float3 Zero { get { return float3(0); } }
		public override float3 One { get { return float3(1); } }
		public override float3 ToUnit( float3 a, out double length ) 
		{
			length = Vector.Length(a);
			return Vector.Normalize(a);
		}
		public override double Length( float3 a ) { return Vector.Length(a); }
	}
	
	class Float4Blender : Blender<float4>
	{
		public override float4 Weight( float4 v, double w ) { return v * (float)w; }
		public override float4 Add( float4 a, float4 b ) { return a + b; }
		public override float4 Sub( float4 a, float4 b ) { return a - b; }
		public override float4 Lerp( float4 a, float4 b, double d )   { return Math.Lerp(a,b,(float)d); }
		public override float4 Zero { get { return float4(0); } }
		public override float4 One { get { return float4(1); } }
		public override float4 ToUnit( float4 a, out double length ) 
		{
			length = Vector.Length(a);
			return Vector.Normalize(a);
		}
		public override double Length( float4 a ) { return Vector.Length(a); }
	}
}
