using Uno;

using Fuse.Controls;
using Fuse.Reactive;

namespace Fuse.Charting
{
	/** 
		Iterates over the axis steps/data.
		
		This example places rotated labels at each tick. Though note this simple layout can be achieved easier just using `PlotAxis` instead.
		
			<c:PlotAxisData Axis="X">
				<Text X="{Plot axis.position} * 100%" Y="0" FontSize="18" Color="#000" 
					Value="{Plot axis.label}" Anchor="105%,45%" TransformOrigin="Anchor" ux:Name="t">
					<Rotation Degrees="-60"/>
				</Text>
			</c:PlotAxisData>
	*/
	public class PlotAxisData : Instantiator, IPlotDataItemProvider
	{
		PlotBehavior _plot;
		internal PlotBehavior Plot { get { return _plot; } }
		
		LabelFilterObservable _obsFilter;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			if (!_hasAxis)
				Fuse.Diagnostics.UserError( "Requires Axis", this );
				
			_plot = PlotBehavior.FindPlot(this);
			if (_plot == null)
			{
				Fuse.Diagnostics.UserError( "Could not find PlotBehavior", this );
			}
			else
			{
				_filter.Plot = _plot;
				_plot.DataChanged += OnDataChanged;
				
				var sourceItems = _plot.GetAxisItems((int)Axis);
				_obsFilter = new LabelFilterObservable{ Filter = _filter, Source = sourceItems };
				UpdateFilter();
				SetItemsDerivedRooting( _obsFilter );
			}
		}
		
		void UpdateFilter()
		{
			if (_obsFilter == null || _plot == null)
				return;
				
			_filter.IsCountAxis = _plot.IsCountAxis( AxisIndex );
			_obsFilter.Update();
		}
		
		protected override void OnUnrooted()
		{
			if (_plot != null)
			{
				_plot.DataChanged -= OnDataChanged;
				SetItems( null );
				_obsFilter = null;
				_plot = null;
				_filter.Plot = null;
			}
			base.OnUnrooted();
		}
		
		void OnDataChanged(object s, DataChangedArgs args)
		{
			//It appears possible to get a data change without the labels Observable being updated.  This is
			//probably due to ExtendEnds.
			_obsFilter.Update();
		}
		
		AxisFilter _filter = new AxisFilter();
		
		/**
			Excludes data points from the start and end of the axis data.
		*/
		public int2 SkipEnds
		{
			get { return _filter.SkipEnds; }
			set 
			{
				if (_filter.SetSkipEnds(value))
					UpdateFilter();
			}
		}
		
		/**
			Only one data point will be iterated for each group of this size. This allows creating labels that group several data points.
			
			The groups will be 0-based in the input data, so with a `Group=3` you'll have groups of 0,1,2 and 3,4,5. These groupings are maintained while stepping through the data.
		*/
		public int Group
		{
			get { return _filter.Group; }
			set
			{
				if (_filter.SetGroup(value))
					UpdateFilter();
			}
		}
		
		/**
			The extra data points added `Plot.DataExtend` are not included in the enumeration.
		*/
		public bool ExcludeExtend
		{
			get { return _filter.ExcludeExtend; }
			set
			{
				if (_filter.SetExcludeExtend(value))
					UpdateFilter();
			}
		}

		bool _hasAxis = false; //used to issue warning
		PlotAxisLayoutAxis _axis;
		/**
			The data points for this Axis.
		*/
		public PlotAxisLayoutAxis Axis
		{
			get { return _axis; }
			set 
			{ 	
				if (_axis == value && _hasAxis)
					return;
					
				_hasAxis = true;
				_axis = value;
				UpdateFilter(); //can affect ExcludeExtend
			}
		}
		
		internal int AxisIndex
		{
			get { return Axis == PlotAxisLayoutAxis.X ? 0 : 1; }
		}
		
		
	}
	
	/**
		A layout and enumeration for the axis steps of a @Plot, which is used to place labels on axes. Often used together with a @(GridLayout) for positioning.
		
		# Example

		The following example places labels on the y-axis of a bar chart.

			<Panel xmlns:c="Fuse.Charting" >
				<JavaScript>
					var Observable = require("FuseJS/Observable");

					function Item(val) {
						this.value = val;
					}
					var data = Observable(new Item(3), new Item(4), new Item(6), new Item(3), new Item(4));

					module.exports = {
						data: data
					}
				</JavaScript>
				<Panel BoxSizing="FillAspect" Aspect="1">
					<c:Plot Margin="40">
						<GridLayout Rows="1*,40" Columns="40,1*"/>
						<c:DataSeries Data="{data}" />
						<c:PlotAxis Row="0" Column="0" Axis="Y">
						    <Text ux:Template="Label" Alignment="Center" FontSize="14" Color="#666"
						        Value="{Plot axis.value}"/>
						</c:PlotAxis>
						<c:PlotData>
							<c:PlotBar Row="0" Column="1">
								<Rectangle Color="#F00" Height="100%" Margin="2" Alignment="Bottom"/>
							</c:PlotBar>
						</c:PlotData>
					</c:Plot>
				</Panel>
			</Panel>
	*/
	public class PlotAxis : Panel
	{
		PlotAxisData _each = new PlotAxisData();
		PlotAxisLayout _layout = new PlotAxisLayout();
		
		public PlotAxis()
		{
			Layout = _layout;
			
			Children.Add(_each);
			_each.TemplateKey = "Label";
			_each.TemplateSource = this;
		}
		
		public PlotAxisLayoutAxis Axis
		{
			get { return _each.Axis; }
			set 
			{ 	
				_each.Axis = value;
				_layout.Axis = _each.Axis; 
			}
		}
		
		public PlotAxisLayoutPosition ContentPosition
		{
			get { return _layout.ContentPosition; }
			set { _layout.ContentPosition = value; }
		}
		
		public int2 SkipEnds
		{
			get { return _each.SkipEnds; }
			set { _each.SkipEnds = value; }
		}
		
		public int Group
		{
			get { return _each.Group; }
			set
			{
				_each.Group = value;
				_layout.Scale = _each.Group;
			}
		}
		
		public bool ExcludeExtend
		{
			get { return _each.ExcludeExtend; }
			set { _each.ExcludeExtend = value; }
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();

			if (_each.Plot != null)
				_each.Plot.DataChanged += OnDataChanged;
		}
		
		protected override void OnUnrooted()
		{
			if (_each.Plot != null)
				_each.Plot.DataChanged -= OnDataChanged;
			base.OnUnrooted();
		}
		
		void OnDataChanged(object s, DataChangedArgs args)
		{
			if (_each.Plot == null) //defensive, should never happen
				return;
				
			_layout.StepCount = _each.Plot.PlotStats.Steps[_each.AxisIndex];
			_layout.Orientation = _each.Plot.GetAxisOrientation(Axis);
			
			_layout.ContentPositionBase = _each.Plot.AxisMetric( _each.AxisIndex ) == PlotAxisMetric.OffsetCount ? 0.5f : 0;
			InvalidateLayout();
		}
	}
	
	class LabelFilterObservable : FilterObservable
	{
		public AxisFilter Filter = new AxisFilter();
		
		protected override bool Accept(object value, int axisIndex, int axisCount )
		{
			return Filter.Accept(value, axisIndex, axisCount);
		}
	}
	
}