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
	}
}
