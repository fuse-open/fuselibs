using Uno;
using Uno.UX;

using Fuse;
using Fuse.Reactive;

namespace FuseTest
{
	public class Value : Behavior
	{
		static Selector ObjectName = "Object";
		
		object _object;
		public object Object
		{
			get { return _object; }
			set
			{
				if (_object == value)	
					return;
					
				_object = value;
				OnPropertyChanged( ObjectName );
			}
		}
		
		public int Integer
		{
			get { return Marshal.ToType<int>(Object); }
			set { Object = value; }
		}
		
		public float Float
		{
			get { return Marshal.ToType<float>(Object); }
			set { Object = value; }
		}
		
		public float4 Float4
		{
			get { return Marshal.ToType<float4>(Object); }
			set { Object = value; }
		}
		
		public float3 Float3
		{
			get { return Marshal.ToType<float3>(Object); }
			set { Object = value; }
		}

		public float2 Float2
		{
			get { return Marshal.ToType<float2>(Object); }
			set { Object = value; }
		}
		
		public bool Boolean
		{
			get { return Marshal.ToType<bool>(Object); }
			set { Object = value; }
		}

		public string String
		{
			get { return Marshal.ToType<string>(Object); }
			set { Object = value; }
		}
	}
}
