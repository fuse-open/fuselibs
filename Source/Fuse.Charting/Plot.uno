using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Controls;

namespace Fuse.Charting
{
	/**
		A panel that contains a chart.
		
		@see Docs/plot.md
	*/
	public partial class Plot : Panel
	{
		PlotBehavior _plot = new PlotBehavior();
		
		public Plot()
		{
			Children.Add(_plot);
		}
		
		[UXContent]
		/**
			The source data used for the Plot.
			
			These are specified as a child of the `Plot` element:
			
				<c:Plot>
					<c:DataSeries Data="{data1}"/>
					<c:DataSeries Data="{data2}"/>
					<c:DataSeries Data="{data3}"/>
				
		*/
		public IList<DataSeries> Series
		{
			get { return _plot.Series; }
		}
		
		/**
			The primary orientation of the chart. This determines how the sub-elements, such as `PlotAxis`, `PlotTicks`, `PlotBar`, etc. are visually oriented.
		*/
		public PlotOrientation Orientation
		{
			get { return _plot.Orientation; }
			set { _plot.Orientation = value; }
		}
		
		/** 
			The calculation used to determine the values of the axis. This determines how the source data is converted to the values for plotting. 
			
			The default for the XAxis is `OffsetCount`, whereas all other axes are `Range`.
		*/
		public PlotAxisMetric XAxisMetric
		{
			get { return _plot.DataSpec.GetAxisMetric(0); }
			set { _plot.DataSpec.SetAxisMetric(0,value); }
		}
		/** @see @XAxisMetric */
		public PlotAxisMetric YAxisMetric
		{
			get { return _plot.DataSpec.GetAxisMetric(1); }
			set { _plot.DataSpec.SetAxisMetric(1,value); }
		}
		/** @see @XAxisMetric */
		public PlotAxisMetric ZAxisMetric
		{
			get { return _plot.DataSpec.GetAxisMetric(2); }
			set { _plot.DataSpec.SetAxisMetric(2,value); }
		}
		/** @see @XAxisMetric */
		public PlotAxisMetric WAxisMetric
		{
			get { return _plot.DataSpec.GetAxisMetric(3); }
			set { _plot.DataSpec.SetAxisMetric(3,value); }
		}

		/**
			For Range axes this extends the range of the values to ensure there is padding near the edges of the charts.
	
			The range is also adjusted to create pleasant stepping values. This padding will be added prior to that, thus the final padding could still be more.
		*/
		public float RangePadding
		{
			get { return _plot.DataSpec.RangePadding; }
			set { _plot.DataSpec.RangePadding = value; }
		}

		/**
			Limits how many data points are included in the plot. This creates a window of the visible data, suitable for dynamic stepping.
			
			This is only useful if the data-set is count base (exactly one axis has a metric of `Count` or `OffsetCount`). By default the X axis is suitable for stepping. 
			
			Consider allowing @PlotArea to determine this value instead. It will make the chart layout responsive.
		*/
		public int DataLimit
		{
			get { return _plot.Limit; }
			set { _plot.Limit = value; }
		}
		
		/**
			The first data point to use in the in plot. Combined with `Limit` to create dynamic stepping.
		*/
		public int DataOffset
		{
			get { return _plot.Offset; }
			set { _plot.Offset = value; }
		}

		/**
			Includes additional data in the visible range created by Offset/Limit.
			
			For example:
			
				<Plot DataLimit="6" DataExtend="2,1">
				
			This will adjust the chart to display 6 items. It will however also include the the two items before the size shown, and the 1 after it. This will result in items being displayed beyond the edges of the chart, which can be employed for various visual effects.
			
			One such effect would be a `ClipToBounds="true"` on a `Curve`. This would you to have the curve extend completely to the edges of the chart instead of ending at the visible data set.
		*/
		public int2 DataExtend
		{
			get { return _plot.Extend; }
			set { _plot.Extend = value; }
		}
		
		/** 
			The desired number of steps for ticks and labels.
			
			The actual number is calculated to produce pleasant stepping values. The value here is the maximum number of steps that will be used.
			
			Consider using `PlotArea` instead of setting this value directly. It will choose a number based on available display space.
			
			This option is ignore for Axes that use a `Count` or `OffsetCount` metric. In those cases the stepping is determined by `DataLimit`.
		*/
		public int XAxisSteps
		{
			get { return _plot.DataSpec.GetAxisSteps(0); }
			set { _plot.DataSpec.SetAxisSteps(0,value); }
		}
		/** @see XAxisSteps */
		public int YAxisSteps
		{
			get { return _plot.DataSpec.GetAxisSteps(1); }
			set { _plot.DataSpec.SetAxisSteps(1,value); }
		}
		
		/** 
			Overrides the calculated range for an axis with  a `Range` metric. 
			
			This is useful when you want the presented values to be over a fixed range, such as 0...100.
			
			If not specified a range will be chosen that produces pleasant stepping values for ticks and labels.
		*/
		public float2 XRange
		{
			get { return _plot.DataSpec.GetRange(0); }
			set { _plot.DataSpec.SetRange(0,value); }
		}
		/** @see XRange */
		public float2 YRange
		{
			get { return _plot.DataSpec.GetRange(1); }
			set { _plot.DataSpec.SetRange(1,value); }
		}
		/** @see XRange */
		public float2 ZRange
		{
			get { return _plot.DataSpec.GetRange(2); }
			set { _plot.DataSpec.SetRange(2,value); }
		}
		/** @see XRange */
		public float2 WRange
		{
			get { return _plot.DataSpec.GetRange(3); }
			set { _plot.DataSpec.SetRange(3,value); }
		}
	}
}
