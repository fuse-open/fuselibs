using Fuse.Reactive;

namespace Fuse.Charting
{
	/**
		Iterator for visual plot data.
		
		This works like an @Each for the visible data points. Use a @PlotBar or  @PlotCurvePoint to add elements matching this data. Or use a `{Plot data.*}` to get at the variables for the data point.
		
			<Panel>
				<c:PlotData>
					<c:PlotBar/>
				</c:PlotData>
			</Panel>
		
			<Curve>
				<c:PlotData>
					<c:PlotCurvePoint/>
				</c:PlotData>
			</Curve>
	*/
	public class PlotData : Instantiator, IPlotDataItemProvider
	{
		/**
			Iterate data from this DataSeries, by index. The index is based on the order the `DataSeries` are added to the Plot.
			
				<Plot>
					<DataSeries Source="{values0}" ux:Name="seriesOne"/><!-- SeriesIndex="0" -->
					<DataSeries Source="{values1}" ux:Name="seriesTwo"/><!-- SeriesIndex="1" -->
		*/
		public int SeriesIndex { get; set; }
		
		/**
			Iterate data from this DataSeries. Use a `ux:Name` on the DataSeries.
			
				<Plot>
					<DataSeries Source="{values0}" ux:Name="seriesOne"/>
					<DataSeries Source="{values1}" ux:Name="seriesTwo"/>
				
					...
					<PlotData Series="seriesTwo">
						...
					</PlotData>
		*/
		public DataSeries Series { get; set; }
		
		AxisFilter _filter = new AxisFilter();
		public PlotData()
		{
			_filter.SetExcludeExtend(false);
			_filter.IsCountAxis = true; //working on the logical "data" axis.
		}
		
		/** @see PlotAxis.SkipEnds */
		public int2 SkipEnds
		{
			get { return _filter.SkipEnds; }
			set 
			{
				if (_filter.SetSkipEnds(value))
					UpdateFilter();
			}
		}

		/** @see PlotAxis.ExcludeExtend */
		public bool ExcludeExtend
		{
			get { return _filter.ExcludeExtend; }
			set
			{
				if (_filter.SetExcludeExtend(value))
					UpdateFilter();
			}
		}
		
		LabelFilterObservable _obsFilter;
		PlotBehavior _plot;
		protected override void OnRooted()
		{
			base.OnRooted();
			
			_plot = PlotBehavior.FindPlot(this);
			if (_plot == null)
			{
				Fuse.Diagnostics.UserError( "Could not find PlotBehavior", this );
			}
			else
			{
				_filter.Plot = _plot;
				UpdateFilter();
			}
		}
		
		void UpdateFilter()
		{
			if (_plot == null)
				return;
				
			var items = Series != null ? _plot.GetDataItemsObservable(Series) :
				_plot.GetDataItemsObservable(SeriesIndex); 
			if (_obsFilter == null && _filter.RequireFilter)
				_obsFilter = new LabelFilterObservable{ Filter = _filter, Source = items };

			object useItems = items;
			if (_obsFilter != null)
			{
				_obsFilter.Update();
				useItems = _obsFilter;
			}
			SetItemsDerivedRooting( useItems );
		}
		
		protected override void OnUnrooted()
		{
			if (_plot != null)
			{
				_filter.Plot = null;
				_plot = null;
				_obsFilter = null;
				SetItems( null );
			}
			
			base.OnUnrooted();
		}
		
	}
}
