using Uno;
using Uno.Collections;

using Fuse.Elements;
using Fuse.Controls;

namespace Fuse.Charting
{
	class Data
	{
		//changing this from 4 is not really feasible, since many places just use `float4` for calculations/storage
		public const int NumAxes = 4;
		
		float4 _sourceValue;
		public float4 SourceValue
		{
			get { return _sourceValue; }
			set
			{
				if (_sourceValue == value)
					return;
					
				_sourceValue = value;
				Invalidate();
			}
		}
		
		IObject _sourceObject;
		public IObject SourceObject
		{
			get { return _sourceObject; }
			set
			{
				if (_sourceObject == value)
					return;
					
				_sourceObject = value;
				Invalidate();
			}
		}
		
		//a poor-typdef essentially, so we dont have to assume a float4 in other places, use `var q = Data.DefaultValue`
		static public float4 DefaultValue { get { return float4(0); } }
		
		string _label;
		public string Label
		{
			get { return _label; }
			set
			{
				if (_label == value)
					return;
					
				_label = value;
				Invalidate();
			}
		}
		
		float4 _color;
		public float4 Color
		{
			get { return _color; }
			set
			{
				if (_color == value)
					return;
					
				_color = value;
				Invalidate();
			}
		}
		
		//derived data that will be updated by DataStats.
		public float4 Value;
		public float4 CumulativeValue;
		
		//intrinsic fields/properties for PlotBehavior
		internal PlotBehavior Behavior;
		
		void Invalidate()
		{
			if (Behavior != null)
				Behavior.InvalidateData();
		}
	}
}