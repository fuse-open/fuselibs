using Uno;

using Fuse.Controls;
using Fuse.Drawing;

namespace Fuse.Charting
{
	[Flags]
	/** The Axis being drawn by PlotTicks */
	public enum PlotTickAxis
	{
		X = 1 << 0,
		Y = 1 << 1,
		Both = X | Y,
	}

	/** The style of ticks being drawn */
	public enum PlotTickStyle
	{
		/** The ticks are along the horizontal/vertical axis for the chart. This is generally used for line and bar charts. */
		Axial,
		/** The ticks are radial lines from the center to the edge. This is generally used for pie and spider charts. */
		Angular,
	}
	
	/**
		Creates tick marks, usually for an axis. This is a @Shape, allowing `Stroke...` properties to be used for drawing the ticks.  The ticks that are drawn will line up with the labels of @PlotAxis provided they are the same element size (either `Width` or `Height` depending on the axis).

		# Example

		The following example shows `PlotTicks` being used to draw lines on the x-axis of a bar chart.

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
						<c:PlotData>
							<c:PlotBar Row="0" Column="1">
								<Rectangle Color="#F00" Height="100%" Margin="2" Alignment="Bottom"/>
							</c:PlotBar>
						</c:PlotData>
						<c:PlotTicks Axis="Y" StrokeWidth="1" StrokeColor="#555" Row="0" Column="1" />
					</c:Plot>
				</Panel>
			</Panel>

		`AxisLine` indicates a line across the entire access should be drawn at this offset. In this example it's the top of the ticks, making this suitable for the bottom of a chart.
	*/
	public class PlotTicks : Shape
	{
		protected override bool NeedSurface { get { return true; } }

		PlotTickAxis _axes = PlotTickAxis.X;
		/**
			Draw ticks for which axes.
			
			`Both` is allowed, in which case a grid will be created.
		*/
		public PlotTickAxis Axis
		{
			get { return _axes; }
			set
			{
				if (_axes == value)
					return;
					
				_axes = value;
				InvalidateSurfacePath();
			}
		}

		PlotTickStyle _style = PlotTickStyle.Axial;
		/**
			The style of ticks being drawn.
		*/
		public PlotTickStyle Style
		{
			get { return _style; }
			set
			{
				if (_style == value)
					return;
					
				_style = value;
				InvalidateSurfacePath();
			}
		}
		
		bool _hasAxisLine;
		float _axisLine;
		/** 
			X or Y Offset, relative to size, in which to draw the axis line.
			
			If not specified then no line will be drawn.
		*/
		public float AxisLine
		{
			get { return _axisLine; }
			set
			{
				if (_hasAxisLine && _axisLine == value)
					return;
					
				_hasAxisLine = true;
				_axisLine = value;
				InvalidateSurfacePath();
			}
		}
		
		float _offset = 0;
		/** For Style="Angular", offset the base of the lines (from center) by this amount (relative value) */
		public float BaseOffset
		{
			get { return _offset; }
			set 
			{
				if (_offset == value)
					return;
					
				_offset = value;
				InvalidateSurfacePath();
			}
		}

		AxisFilter _filter = new AxisFilter();
		/** @see PlotAxis.Group */
		public int Group
		{
			get { return _filter.Group; }
			set
			{
				if (_filter.SetGroup(value))
					InvalidateSurfacePath();
			}
		}

		/** @see PlotAxis.SkipEnds */
		public int2 SkipEnds
		{
			get { return _filter.SkipEnds; }
			set 
			{
				if (_filter.SetSkipEnds(value))
					InvalidateSurfacePath();
			}
		}

		/** @see PlotAxis.ExcludeExtend */
		public bool ExcludeExtend
		{
			get { return _filter.ExcludeExtend; }
			set
			{
				if (_filter.SetExcludeExtend(value))
					InvalidateSurfacePath();
			}
		}
		
		
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
				_plot.DataChanged += OnDataChanged;
			}
		}
		
		protected override void OnUnrooted()
		{
			if (_plot != null)
			{
				_plot.DataChanged -= OnDataChanged;
				_plot = null;
				_filter.Plot = null;
			}
			base.OnUnrooted();
		}
		
		void OnDataChanged(object s, DataChangedArgs args)
		{
			InvalidateSurfacePath();
		}
			
		void GetOrientation( int axis, out float2 xVector, out float2 yVector )
		{
			var o = _plot.GetAxisOrientation(axis);
			if (o == PlotOrientation.Horizontal)
			{
				xVector = float2(1,0);
				yVector = float2(0,1);
			}
			else
			{
				xVector = float2(0,1);
				yVector = float2(1,0);
			}
		}
		
		protected override SurfacePath CreateSurfacePath(Surface surface)
		{
			var list = new LineSegments();

			if (_plot != null)
			{
				if (Axis.HasFlag(PlotTickAxis.X))
					DrawLine( list, 0 );
				if (Axis.HasFlag(PlotTickAxis.Y))
					DrawLine( list, 1 );
			}
			
			return surface.CreatePath(list.Segments);
		}
		
		void DrawLine( LineSegments list, int axis )
		{
			_filter.IsCountAxis = _plot.IsCountAxis( axis );
			var items = _plot.GetAxisItems(axis);
			
			var isOffset = _plot.AxisMetric( axis ) == PlotAxisMetric.OffsetCount;
			var offset = isOffset ? 0.5f : 0f;
			var steps = _plot.PlotStats.Steps[axis];
			var sz = ActualSize;
			
			switch (Style)
			{
				case PlotTickStyle.Axial:
				{
					float2 a, b;
					GetOrientation(axis, out a, out b);
					if (_hasAxisLine)
					{
						list.MoveTo( _axisLine * b * sz );
						list.LineToRel( a * sz );
					}
				
					for (int i=0; i < items.Length; ++i)
					{
						int w;
						if (!_filter.Accept(items[i], i, items.Length, out w))
							continue;
							
						var pos = (w + offset) / (float)steps;
						list.MoveTo( pos * a * sz );
						list.LineToRel( b * sz );
					}
					break;
				}
				
				case PlotTickStyle.Angular:
				{
					if (_hasAxisLine)
					{
						list.MoveTo( float2(_axisLine,0) * sz/2 + sz/2 );
						list.EllipticArcToRel( float2(-_axisLine,0) * sz, _axisLine * sz/2, 0, false, true );
						list.EllipticArcToRel( float2(_axisLine,0) * sz, _axisLine * sz/2, 0, false, true );
					}
					
					for (int i=0; i < items.Length; ++i)
					{
						int w;
						if (!_filter.Accept(items[i], i, items.Length, out w))
							continue;
							
						var angle = (w + offset) / (float)steps * Math.PIf * 2;
						var position = float2( Math.Cos(angle), Math.Sin(angle) );
						list.MoveTo( sz * 0.5f + position * sz/2 * BaseOffset );
						list.LineToRel( position * sz/2 * (1-BaseOffset) );
					}
					break;
				}
			}
		}
	}
}
