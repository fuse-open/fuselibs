using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Elements;

namespace Fuse.Charting
{
	public enum PlotOrientation
	{
		/** Used to indicate the main plot decides layout */
		Default,
		/** The X Axis data is displayed horizontally */
		Horizontal,
		/** The X Axis data is displayed vertically */
		Vertical,
	}
	
	static class TypeUtils
	{
		public static PlotOrientation Opposite( PlotOrientation a )
		{
			switch (a)
			{
				case PlotOrientation.Default: return PlotOrientation.Default;
				case PlotOrientation.Horizontal: return PlotOrientation.Vertical;
				case PlotOrientation.Vertical: return PlotOrientation.Horizontal;
			}
			return PlotOrientation.Default;
		}
	}
	
	class DataChangedArgs : Uno.EventArgs
	{
		public DataChangedArgs() { }
	}
	
	delegate void DataChangedHandler( object sender, DataChangedArgs args );

	//pseudo - typedefs (would prefer `using` syntax from C#)
	class ObservableAxisItems : ReadOnlyObservableList<AxisEntry> { }
	class ObservableDataItems : ReadOnlyObservableList<PlotDataPoint> { }
	
	/**	
		Data calculations and management of plotting data.
		
		@see @Fuse.Charting.Plot for the high-level wrapper and common field descriptions.
		@hide
	*/
	class PlotBehavior : Behavior
	{
		public PlotBehavior()
		{
			_axisItems = new ObservableAxisItems[Data.NumAxes];
			for (int i=0; i < Data.NumAxes; ++i)
				_axisItems[i] = new ObservableAxisItems();
				
			//reasonable default for X-axis
			_spec.SetAxisMetric(0, PlotAxisMetric.OffsetCount);
		}
		
		DataSpec _spec = new DataSpec();
		internal DataSpec DataSpec
		{
			get { return _spec; }
			set 
			{
				if (_spec == value)
					return;
					
				if (value == null)
					throw new Exception("Invalid DataSpec");
					
				if (IsRootingCompleted)
					_spec.Changed -= OnSpecChanged;
				_spec = value;
				if (IsRootingCompleted)
				{
					_spec.Changed += OnSpecChanged;
					OnSpecChanged();
				}
			}
		}
		
		internal static PlotBehavior FindPlot(Node from)
		{
			while (from != null)
			{
				var v = from as Visual;
				if (v != null)
				{
					var p = v.FirstChild<PlotBehavior>();
					if (p != null)
						return p;
				}
				from = from.Parent;
			}
			
			return null;
		}		
		
		PlotOrientation _orientation = PlotOrientation.Horizontal;
		public PlotOrientation Orientation
		{
			get { return _orientation; }
			set
			{
				if (_orientation == value)
					return;
					
				_orientation = value;
				InvalidateCalculation();
			}
		}
		
		internal PlotOrientation GetAxisOrientation(int axis)
		{
			if (axis > 1)
				return PlotOrientation.Default;
				
			if (axis == 0)
				return Orientation;
			
			//axis == 1
			return TypeUtils.Opposite(Orientation);
		}
		
		internal PlotAxisMetric AxisMetric(int i) { return _spec.GetAxisMetric(i); }
		internal bool IsCountAxis(int i) { return _spec.IsCountAxis(i); }
		
		int _offset = 0;
		public int Offset
		{
			get { return _offset; }
			set
			{
				var v = Math.Max(0,value);
				if (_offset == v)
					return;
					
				_offset = v;
				InvalidateWindow();
			}
		}
		
		bool _hasLimit;
		int _limit;
		public int Limit
		{
			get { return _limit; }
			set
			{
				value = Math.Max(1,value);
				if (_limit == value && _hasLimit)
					return;
					
				_hasLimit = true;
				_limit = value;
				InvalidateWindow();
			}
		}
		
		int2 _extend;
		public int2 Extend
		{
			get { return _extend; }
			set
			{
				if (_extend == value)
					return;
					
				_extend = value;
				InvalidateWindow();
			}
		}
		
		List<DataSeries> _series = new List<DataSeries>();
		[UXContent]
		public IList<DataSeries> Series
		{
			get { return _series; }
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			for (int i=0; i < _series.Count; ++i)
				_series[i].Root(this);
				
			DataSpec.Changed += OnSpecChanged;
			InvalidateData();
		}
		
		protected override void OnUnrooted()
		{
			for (int i=0; i < _series.Count; ++i )
				_series[i].Unroot();
			
			for (int i=0; i < Data.NumAxes; ++i)
				_axisItems[i].Clear();
			_dataItems.Clear();
			
			DataSpec.Changed -= OnSpecChanged;
			base.OnUnrooted();
		}
		
		bool _pendingData;
		internal void InvalidateData()
		{
			if (!IsRootingStarted || _pendingData)
				return;

			//we defer to give a chance for various properties to be set in once pass of rooting
			UpdateManager.AddDeferredAction(DeferredUpdateData);
			_pendingData = true;
		}
		
		void OnSpecChanged()
		{
			InvalidateData();
		}
		
		void InvalidateCalculation()
		{
			InvalidateData();
		}
		
		void InvalidateWindow()
		{
			//simple approach for now
			InvalidateData();
		}
		
		internal event DataChangedHandler DataChanged;

		//stats derived from the actual data
		DataStats _dataStats = new DataStats(); //start with default to ensure it's never null
		//modified stats for the plot
		DataStats _plotStats = new DataStats();
		
		internal DataStats DataStats { get { return _dataStats; } }
		internal DataStats PlotStats { get { return _plotStats; } }

		void DeferredUpdateData()
		{
			_pendingData = false;
			if (!IsRootingCompleted || _series.Count == 0)
				return;

			_dataStats = DataStats.CalculateAll( _series, _spec );
			if (_dataStats.Count == 0)
				return;
			
			_plotStats = _dataStats.Clone();
			_plotStats.Extend(Extend);
			_plotStats.ApplyLimits( _spec, Offset, Limit, _hasLimit );
			
			for (int s=0; s < _series.Count; ++s)
			{
				var data = _series[s].PlotData;
				var dataItems = GetDataItems(s);
				
				var ends = _plotStats.Extended;
				//reuse items based on the index in the source data. this will ensure that things like Each
				//recognize the same object
				var diAt = 0;
				for (int i=ends[0]; i < ends[1]; ++i)
				{
					var ndx = i + _plotStats.Offset;
					if (ndx < 0 || ndx >= data.Count)
						continue;
				
					while (diAt < dataItems.Count && dataItems[diAt].Index < ndx)
						dataItems.RemoveAt(diAt);
						
					if (diAt < dataItems.Count && dataItems[diAt].Index == ndx)
						dataItems[diAt++].Update( data[ndx], ndx );
					else
						dataItems.Insert( diAt++, new PlotDataPoint{ Data = data[ndx], 
							SeriesIndex = s, Plot = this, Index = ndx } );
				}
				
				while( dataItems.Count > diAt )
					dataItems.RemoveAt( dataItems.Count - 1 );
			}
			//clear other watched series (don't remove them since they could appear again)
			for (int i=_series.Count; i < _dataItems.Count; ++i)
				_dataItems[i].Clear();
			
			for (int i=0; i < Data.NumAxes; ++i)
				UpdateAxisItems(_series[0].PlotData, i); //names from first data set
				
			//already at the end of a dispatched message so no need to dispacth again
			if (DataChanged != null)
				DataChanged( this, new DataChangedArgs() );
		}

		List<ObservableDataItems> _dataItems = new List<ObservableDataItems>();
		internal Fuse.Reactive.IObservableArray GetDataItemsObservable(int series)
		{	
			return GetDataItems(series);
		}

		internal Fuse.Reactive.IObservableArray GetDataItemsObservable(DataSeries series)
		{
			for (int i=0; i < Series.Count; ++i)
			{
				if (Series[i] == series)
					return GetDataItems(i);
			}

			Fuse.Diagnostics.UserError( "DataSeries is not part of this plot", this );
			return GetDataItems(0);
		}
		
		ObservableDataItems GetDataItems(int series)
		{
			if (series < 0 || series > 128) //reasonable limit to prevent nonsense
			{
				Fuse.Diagnostics.UserError( "Out-of-range series index", this );
				series = 0;
			}
			while (series >= _dataItems.Count)
				_dataItems.Add( new ObservableDataItems() );
			return _dataItems[series];
		}
		
		ObservableAxisItems[] _axisItems;
		internal Fuse.Reactive.IObservableArray XAxisItems
		{
			get { return _axisItems[0]; }
			set { }
		}
		
		internal Fuse.Reactive.IObservableArray YAxisItems
		{
			get { return _axisItems[1]; }
			set { }
		}

		internal Fuse.Reactive.IObservableArray ZAxisItems
		{
			get { return _axisItems[2]; }
			set { }
		}
		
		internal Fuse.Reactive.IObservableArray WAxisItems
		{
			get { return _axisItems[3]; }
			set { }
		}
		
		internal Fuse.Reactive.IObservableArray GetAxisItems(int axis)
		{
			return _axisItems[axis];
		}
		
		void UpdateAxisItems( List<Data> data, int axis )
		{
			//create a temp list to ensure we add new items in order, and don't double-initialize,
			//both of which is inefficient for Each as it observes the items
			AxisEntryData[] labels = null;
			var metric = AxisMetric(axis);
			switch (metric)
			{
				case PlotAxisMetric.Count:
				case PlotAxisMetric.OffsetCount:
				{
					var c = _plotStats.Count;
					var ends = _plotStats.Extended;
					var ec = ends[1] - ends[0];
					var f = new AxisEntryData[ec];
					for (int i=0; i < ec; ++i)
					{
						var ndx = i + _plotStats.Offset + ends[0];
						var sourceData = (ndx < 0 || ndx >= data.Count) ? null : data[ndx];
						f[axis == 1 ? (ec-i-1) : i] = new AxisEntryData{ 
							Data = sourceData,
							Index = ndx,
							Value = ndx,
							Position = metric == PlotAxisMetric.OffsetCount ? 
								((i + ends[0] + 0.5f) / (float)c) : ((i + ends[0]) / (float)c) };
					}
					labels = f;
					break;
				}

				case PlotAxisMetric.MergeRange:
				case PlotAxisMetric.Range:
				{
					var c = _plotStats.Steps[axis];
					var f = new AxisEntryData[c+1];
					var mn = _plotStats.Minimum[axis];
					var mx = _plotStats.Maximum[axis];
					var step = (mx - mn) /  c;
					for (int i=0; i <= c; ++i)
						f[i] = new AxisEntryData{ 
							Data = null,
							Index = i, 
							Value = mn + step * i,
							Position = i / (float)c };
					labels = f;
					break;
				}
			}
			
			//defensive case
			if (labels == null)
				labels = new AxisEntryData[0];
				
			//add/update items
			//Keep items that are the same, as in DeferredUpdateData
			var items = _axisItems[axis];
			var iAt = 0;
			for (int i=0; i < labels.Length; ++i)
			{
				while (iAt < items.Count && items[iAt].Data.Index < labels[i].Index)
					items.RemoveAt(iAt);
					
				if (iAt < items.Count && items[iAt].Data.Index == labels[i].Index)
					items[iAt++].Update( labels[i] );
				else
					items.Insert( iAt++, new AxisEntry{ Plot = this, Data = labels[i], Axis = axis } );
			}
			
			//remove excessive
			while(items.Count > labels.Length)
				items.RemoveAt(items.Count-1);
		}

		/**
			Steps the offset by an amount. This clamps the result into a range that displays `Limit` worth of data.
		*/
		public void StepOffset(int step)
		{
			var effLimit = _hasLimit ? Limit : 1;
			var nextOffset = Offset + step;
			var cOffset = Math.Clamp( nextOffset, 0, Math.Max(0, DataStats.Count - effLimit) );
			Offset = cOffset;
		}
		
		public float4 ScreenValue(float4 v)
		{
			if (Orientation == PlotOrientation.Horizontal)
				return float4(v[0],1-v[1],v[2],v[3]);
			return float4(v[1],1-v[0],v[2],v[3]);
		}
		
		public int4 ScreenSteps(int4 v)
		{
			if (Orientation == PlotOrientation.Horizontal)
				return int4(v[0],v[1],v[2],v[3]);
			return int4(v[1],v[0],v[2],v[3]);
		}
	}
}
