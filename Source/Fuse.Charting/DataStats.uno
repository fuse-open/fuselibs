using Uno;
using Uno.Collections;

using Fuse.Elements;
using Fuse.Controls;

namespace Fuse.Charting
{
	public enum PlotAxisMetric
	{
		/** The index/position of the data items is treated as the axis. For example, on the XAxis the first item in the source data gets a value of 0, the next a value of 1, etc. */
		Count,
		/** A variant of Count that positions the data items in the center of the indexed regions. For example, on the XAxis the first item in the source data gets a value of 0.5, the next 1.5, etc. */
		OffsetCount,
		/** The axis covers the range of values present in the data */
		Range,
		/** The range continues the range of the previous axis */
		MergeRange,
	}
	
	class DataSpec
	{
		public DataSpec()
		{
			for (int i=0; i < Data.NumAxes; ++i)
			{
				_axisMetric[i] = PlotAxisMetric.Range;
				_axisSteps[i] = 10;
				_hasRange[i] = false;
			}
		}
		
		internal event Action Changed;
		
		void OnChanged()
		{
			if (Changed != null)
				Changed();
		}
		
		PlotAxisMetric[] _axisMetric = new PlotAxisMetric[Data.NumAxes];
		public PlotAxisMetric GetAxisMetric(int axis)
		{
			return _axisMetric[axis];
		}
		
		public void SetAxisMetric(int axis, PlotAxisMetric value)
		{
			if (value == _axisMetric[axis])
				return;
			if (axis == 0 && value == PlotAxisMetric.MergeRange)
			{
				value = PlotAxisMetric.Range;
				Fuse.Diagnostics.UserError( "Cannot user MergeRange on first axis", this );
			}
			
			_axisMetric[axis] = value;
			OnChanged();
		}
		
		public bool IsCountAxis(int axis)
		{
			var style = GetAxisMetric(axis);
			return style == PlotAxisMetric.Count || style == PlotAxisMetric.OffsetCount;
		}
		
		internal int[] _axisSteps = new int[Data.NumAxes];
		public int GetAxisSteps(int axis)
		{
			return _axisSteps[axis];
		}
		public void SetAxisSteps(int axis, int value)
		{
			value = Math.Max(value, 1);
			if (_axisSteps[axis] == value)
				return;
			_axisSteps[axis] = value;
			OnChanged();
		}
		
		float _rangePadding = 0;
		public float RangePadding 
		{ 
			get { return _rangePadding; }
			set 
			{
				if (_rangePadding == value)
					return;
					
				_rangePadding = value;
				OnChanged();
			}
		}
		
		bool[] _hasRange = new bool[Data.NumAxes];
		public bool HasRange(int axis)
		{
			return _hasRange[axis];
		}
		
		float2[] _range = new float2[Data.NumAxes];
		public float2 GetRange(int axis)
		{
			return _range[axis];
		}
		public void SetRange(int axis, float2 value)
		{
			if (_range[axis] == value && _hasRange[axis])
				return;
				
			_hasRange[axis] = true;
			_range[axis] = value;
			OnChanged();
		}
	}

	class DataStats
	{
		//size of the original data set
		public int FullCount; // >= 0
		//size of the data set window
		public int Count;
		//extend ends of the Count range
		public int2 Extended
		{
			get { return Range - Offset; }
		}

		//the range into the source data (may still exceed bounds with combined series)
		public int2 Range
		{
			get 
			{ 
				return int2( Math.Max(0, Offset - _extend[0]), 
					Math.Min(FullCount, Offset + Count + _extend[1])); 
			}
		}
		
		//the range of data that is inside the desired window
		public int2 WindowRange
		{
			get
			{
				return int2( Math.Max(0, Offset),  Math.Min(FullCount, Offset + Count)); 
			}
		}

		//the count of data in the set (at both ends) that is part of the extended set (outside the window)
		public int2 RangeExtended
		{
			get 
			{
				var range = Range;
				var window = WindowRange;
				return int2( window[0] - range[0], range[1] - window[1] ); 
			}
		}
		
		//offset of window into data set
		public int Offset; // >= 0
		
		int2 _extend;

		// The minimum and maximum of the data (possibly adjusted for steps and range padding)
		public float4 Minimum, Maximum; // Maximum >= Minimum
		// The number of steps (places for labels/markers) on the axis
		public int4 Steps = int4(1); // >= 1
		// The total value of all data points
		public float4 Total;
		
		public DataStats Clone()
		{
			return new DataStats{
				FullCount = FullCount,
				Count = Count,
				_extend = _extend,
				Offset = Offset,
				Minimum = Minimum,
				Maximum = Maximum,
				Steps = Steps,
				Total = Total};
		}
		
		public void Combine( DataStats ds )
		{
			FullCount = Math.Max(FullCount, ds.FullCount);
			Count = Math.Max(Count, ds.Count);
			_extend = Math.Max(_extend, ds._extend); 
			Minimum = Math.Min(Minimum, ds.Minimum);
			Maximum = Math.Max(Maximum, ds.Maximum);
			//steps can't be combined
			//total can't be combined
		}
		
		void MergeAxis( int a, int b )
		{
			var mn = Math.Min( Minimum[a], Minimum[b] );
			var mx = Math.Max( Maximum[a], Maximum[b] );
			
			Minimum[a] = Minimum[b] = mn;
			Maximum[a] = Maximum[b] = mx;
		} 

		/**
			Produce the Data.Value field.
		*/
		static void CountValueAssign( IList<Data> data, DataSpec spec )
		{
			for (int i=0; i < data.Count; ++i)
			{
				var v = data[i].SourceValue;
				for (int j=0; j < Data.NumAxes; j++)
				{
					var r = spec.GetAxisMetric(j);
					if (r == PlotAxisMetric.Count)
						v[j] = i;
					else if (r == PlotAxisMetric.OffsetCount)
						v[j] = i + 0.5f;
				}
				data[i].Value = v;
			}
		}
		
		static void AddValueAssign( IList<Data> data, IList<Data> prev )
		{
			for (int i=0; i < data.Count; ++i)
			{
				var p = i >= prev.Count ? 0f : prev[i].Value.Y;
				var c = data[i].Value.Y;
				
				data[i].Value.Y = p + c;
				data[i].Value.Z = p;
			}
		}
		
		static public DataStats CalculateAll( IList<DataSeries> series, DataSpec spec )
		{
			DataStats dataStats = null;
			for (int i=0; i < series.Count; ++i)
			{
				CountValueAssign( series[i].PlotData, spec );
				if (series[i].Metric == DataSeriesMetric.Add && i > 0)
					AddValueAssign( series[i].PlotData, series[i-1].PlotData );
					
				series[i].Stats = DataStats.Calculate(series[i].PlotData, spec);
				if (i == 0)
					dataStats = series[i].Stats.Clone();
				else
					dataStats.Combine(series[i].Stats);
			}
			
			return dataStats;
		}
		
		/**	
			This returns the calculated stats as well as produced derived data in the Data objects themselves.
		*/
		static public DataStats Calculate( IList<Data> data, DataSpec spec )
		{
			var ds = new DataStats();
				
			ds.Count = data.Count;
			ds.FullCount = data.Count;
			ds.Offset = 0;
			ds.Total = Data.DefaultValue;
			if (data.Count != 0)
			{
				ds.Minimum = data[0].Value;
				ds.Total += data[0].Value;
				data[0].CumulativeValue = ds.Total;
				ds.Maximum = ds.Minimum;
				for (int i=1; i< data.Count;++i)
				{
					ds.Total += data[i].Value;
					data[i].CumulativeValue = ds.Total;
					ds.Minimum = Math.Min(ds.Minimum, data[i].Value);
					ds.Maximum = Math.Max(ds.Maximum, data[i].Value);
				}
			}

			ds.Steps = int4(1);
			
			for (int i=1; i < Data.NumAxes; ++i)
			{
				if (spec.GetAxisMetric(i) == PlotAxisMetric.MergeRange)
					ds.MergeAxis(i-1,i);
			}
			
			return ds;
		}
		
		public void Extend( int2 Extend )
		{
			_extend = Extend;
		}

		public void ApplyLimits( DataSpec spec, int offset, int limit, bool hasLimit )
		{
			Offset = Math.Min( offset, FullCount );
			Count = hasLimit ? Math.Clamp( limit, 0, FullCount - Offset ) : FullCount - Offset;
			
			//extend to 0 if necessary and apply padding
			Minimum = Math.Min(Minimum, float4(0)) * (1 + spec.RangePadding);
			Maximum = Math.Max(Maximum, float4(0)) * (1 + spec.RangePadding);;
			
			for (int i=0; i < 4; ++i)
			{
				if( spec.HasRange(i) )
				{
					Steps[i] = spec.GetAxisSteps(i);
					var r = spec.GetRange(i);
					Minimum[i] = r[0];
					Maximum[i] = r[1];
					continue;
				}
				
				switch (spec.GetAxisMetric(i))
				{
					case PlotAxisMetric.Count:
						Steps[i] = Count - 1;
						Minimum[i] = Offset;
						Maximum[i] = Offset + Count - 1;
						break;
				
					case PlotAxisMetric.OffsetCount:
						Steps[i] = Count;
						Minimum[i] = Offset;
						Maximum[i] = Offset + Count;
						break;
				
					case PlotAxisMetric.MergeRange:
						Minimum[i] = Minimum[i-1];
						Maximum[i] = Maximum[i-1];
						Steps[i] = Steps[i-1];
						break;
						
					case PlotAxisMetric.Range:
					{
						var mn = Minimum[i];
						var mx = Maximum[i];
						int s = spec.GetAxisSteps(i);
						DataUtils.GetStepping( ref s, ref mn, ref mx );
						Minimum[i] = mn;
						Maximum[i] = mx;
						Steps[i] = s;
						break;
					}
				}
				
				Steps[i] = Math.Max(Steps[i],1); //to match restriction in DataSpec.SetAxisSteps (for sanity)
			}
			
		}
		
		public float GetRelativeValue( float v, int axis )
		{
			return DataUtils.RelDiv( v - Minimum[axis], Maximum[axis] - Minimum[axis] );
		}
		
		public float4 GetRelativeValue( float4 v )
		{
			return float4(
				GetRelativeValue(v[0],0),
				GetRelativeValue(v[1],1),
				GetRelativeValue(v[2],2),
				GetRelativeValue(v[3],3) );
		}
		
		public float4 Baseline
		{
			get
			{
				//TODO: It's not clear why this is the correct formula, it may not work on some ranges
				return Math.Abs(DataUtils.RelDiv(Minimum, Maximum - Minimum));
			}
		}
	}
}	
