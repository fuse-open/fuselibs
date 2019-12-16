using Uno;
using Uno.UX;

namespace Fuse.Charting
{
	/** A common base for iterated chart data */
	abstract class IPlotDataItem : IObject
	{
		public delegate void ChangedHandler();
		public event ChangedHandler Changed;
		
		public abstract bool ContainsKey(string key);
		public abstract object this[string key] { get; }
		public abstract string[] Keys { get; }
		
		protected void OnChanged()
		{
			if (Changed != null)
				Changed();
		}
	}

	interface IPlotDataItemListener<T>
	{
		void OnNewData(T entry);
	}
	
	interface IPlotDataItemProvider { }
	
	/**
		Locates and watches for a IPlotDataItem in the context of a given node.
	*/
	class PlotDataItemWatcher<T> : IDisposable where T : IPlotDataItem
	{
		IPlotDataItemListener<T> _listener;
		T _point;
		
		public PlotDataItemWatcher(Node origin, IPlotDataItemListener<T> listener) 
		{
			_listener = listener;
			_point = GetDataContext(origin);
			if (_point != null)
			{
				_listener.OnNewData(_point);
				_point.Changed += OnChanged;
			}
		}
		
		void OnChanged()
		{
			// HACK: Early-out on attempts to access a disposed object.
			// This happens quite frequently in a user app and we don't want this to cause
			// a fatal crash, nor spam the log with error messages. The app seems to work
			// fine if we simply early-out here instead.
			if (_listener == null)
				return;

			_listener.OnNewData(_point);
		}

		internal T GetDataContext(Node from)
		{
			var n = from.ContextParent;
			var p = (Node)from;
			while (n != null)
			{
				if (n is IPlotDataItemProvider)
				{
					object o;
					(n as Node.ISubtreeDataProvider).TryGetDataProvider( p, Node.DataType.Prime, out o );
					return o as T;
				}
				p = n;
				n = n.ContextParent;
			}
			
			Fuse.Diagnostics.UserError( "Must be used within a Plot", from );
			return null;
		}		

		public void Dispose()
		{
			if (_point != null)
			{
				_point.Changed -= OnChanged;
				_point = null;
			}
			_listener = null;
		}
	}
	
	/**
		Data for a point in a plot.
		
		The X,Y,Z,W values are stored as relative in the 0..1 range. Under the names x,y,z,w in this[] they are exposed as Size values using Unit.Percent. Using the rel* names they are exposed as the 0..1 values.
	*/
	class PlotDataPoint : IPlotDataItem
	{
		public void Update( Data data, int index )
		{
			Data = data;
			Index = index;
			OnChanged();
		}
		
		public PlotBehavior Plot;
		public Data Data;
		public int Index;
		public int SeriesIndex;
		
		const string XName = "x";
		const string YName = "y";
		const string ZName = "z";
		const string WName = "w";
		const string ScreenRelativeValueName = "screenRel";
		const string RelativeValueName = "rel";
		const string SourceValueName = "source";
		const string CumulativeValueName = "cumulative";
		const string AccumulatedValueName = "accumulated";
		const string CumulativeWeightName = "cumulativeWeight";
		const string AccumulatedWeightName = "accumulatedWeight";
		const string WeightName = "weight";
		const string LabelName = "label";
		const string ObjectName = "object";
		
		static string[] NameKeys = new []{ XName, YName, ZName, WName,
			SourceValueName, ScreenRelativeValueName, RelativeValueName,
			CumulativeValueName, AccumulatedValueName,
			CumulativeWeightName, AccumulatedWeightName,
			WeightName, LabelName, ObjectName
			};
			
		public override bool ContainsKey(string key)
		{
			for (int i=0; i < NameKeys.Length; ++i)
			{
				if (NameKeys[i] == key)
					return true;
			}
			return false;
		}
		
		float GetValue(int axis)
		{
			return Plot.PlotStats.GetRelativeValue( RawValue[axis], axis );
		}
		
		public float Count { get { return Plot.PlotStats.Count; } }
		
		static DataSeries Empty = new DataSeries();
		
		DataSeries Series
		{
			get
			{
				var series = Plot.Series;
				if (SeriesIndex < 0 || SeriesIndex >= series.Count)
					return Empty;
				return series[SeriesIndex];
			}
		}
		
		public float4 RawValue { get { return Data.Value; } }
		public float4 CumulativeValue { get { return Data.CumulativeValue; } }
		
		public Size X { get { return new Size(ScreenRelativeValue.X * 100,Unit.Percent); } }
		public Size Y { get { return new Size(ScreenRelativeValue.Y * 100,Unit.Percent); } }
		public Size Z { get { return new Size(ScreenRelativeValue.Z * 100,Unit.Percent); } }
		public Size W { get { return new Size(ScreenRelativeValue.W * 100,Unit.Percent); } }
		
		public float4 ScreenRelativeValue
		{ get { return Plot.ScreenValue(Plot.PlotStats.GetRelativeValue( RawValue )); } }
		
		public float4 RelativeValue
		{ get { return Plot.PlotStats.GetRelativeValue( RawValue ); } }
		
		public float4 AccumulatedValue { get { return CumulativeValue - RawValue; } }
		
		public float4 CumulativeWeight { get { return CumulativeValue / Series.Stats.Total; } }
		public float4 AccumulatedWeight { get { return AccumulatedValue / Series.Stats.Total; } }
		public float4 Weight { get { return RawValue / Series.Stats.Total; } }
		
		public override object this[string key]
		{
			get
			{
				var q = GetValue(key);
				return q;
			}
		}
		
		public object GetValue( string key )
		{
			if (key == XName) return X;
			if (key == YName) return Y;
			if (key == ZName) return Z;
			if (key == WName) return W;
				
			if (key == ScreenRelativeValueName) return ScreenRelativeValue;
			if (key == RelativeValueName) return RelativeValue;
			if (key == SourceValueName) return RawValue;
			if (key == CumulativeValueName) return CumulativeValue;
			if (key == AccumulatedValueName) return AccumulatedValue;
			if (key == CumulativeWeightName) return CumulativeWeight;
			if (key == AccumulatedWeightName) return AccumulatedWeight;
			if (key == WeightName) return Weight;
			if (key == LabelName) return Data.Label;
			if (key == ObjectName) return Data.SourceObject;
			
			return null;
		}
		
		public override string[] Keys
		{
			get { return NameKeys; }
		}
	}
	

	/** Helper class to simplify coding of the creation of the AxisEntry ObservableList */
	struct AxisEntryData
	{
		//null if not available (always null for Range axes)
		public Data Data;
		public float Value;
		//index in the source data
		public int Index;
		public float Position;
	}
	
	/** Data for an axis label */
	class AxisEntry : IPlotDataItem
	{
		public PlotBehavior Plot;
		public int Axis;
		public AxisEntryData Data;
		
		const string ValueName = "value";
		const string IndexName = "index";
		const string LabelName=  "label";
		const string PositionName = "position";
		const string ObjectName = "object";
		const string ScreenIndexName = "screenIndex";

		public void Update( AxisEntryData data )
		{
			Data = data;
			OnChanged();
		}
		
		public int Index { get { return Data.Index; } }

		public int ScreenIndex 
		{ 
			get 
			{ 
				if (Plot.IsCountAxis(Axis))
					return Data.Index - Plot.Offset; 
				return Data.Index;
			} 
		}
		
		public float Position { get { return Data.Position; } }
		
		public override bool ContainsKey(string key)
		{
			return key == ValueName || key == IndexName || key == LabelName || key == PositionName ||
				key == ObjectName || key == ScreenIndexName;
		}
		
		public override object this[string key]
		{
			get
			{
				if (key == ValueName)
					return Data.Value;
				if (key == IndexName)
					return Data.Index;
				if (key == LabelName)
					return Data.Data == null ? null : Data.Data.Label;
				if (key == PositionName)
					return Data.Position;
				if (key == ObjectName)
					return Data.Data == null ? null : Data.Data.SourceObject;
				if (key == ScreenIndexName)
					return ScreenIndex;
				return null;
			}
		}
		
		public override string[] Keys 
		{ 
			get { return new[]{ ValueName, IndexName, LabelName, PositionName, ObjectName,
				ScreenIndexName }; }
		}
	}
	
}