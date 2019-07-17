using Uno;

using Fuse.Animations;
using Fuse.Controls;
using Fuse.Motion;
using Fuse.Motion.Simulation;

namespace Fuse.Charting
{
	/**
		Convenience wrapper for platting CurvePoint's in a plot.

		This shares most of the functionality of `PlotPoint` except creates a `CurvePoint` suitable for a `Curve.

		# Example

		This example demonstrates a simple line graph built using `PlotCurvePoint`

			<Panel xmlns:c="Fuse.Charting" >
				<JavaScript>
					var Observable = require("FuseJS/Observable");

					function Item(val) {
						this.value = val;
					}
					var data = Observable(new Item(3), new Item(4), new Item(6), new Item(0), new Item(4));

					module.exports = {
						data: data
					}
				</JavaScript>
				<Panel BoxSizing="FillAspect" Aspect="1" >
					<c:Plot >
						<c:DataSeries Data="{data}" />
						<Curve StrokeWidth="5" StrokeColor="#008" >
							<c:PlotData>
								<c:PlotCurvePoint/>
							</c:PlotData>
						</Curve>
					</c:Plot>
				</Panel>
			</Panel>
	*/
	public class PlotCurvePoint : CurvePoint, IPlotDataItemListener<PlotDataPoint>
	{
		DestinationBehavior<float2>_animator = new DestinationBehavior<float2>();

		public PlotCurvePoint()
		{
			_calc.Init();
		}
		
		PointCalculator _calc;
		/** @see @PlotPoint.Style */
		public PlotPointStyle Style
		{
			get { return _calc.Style; }
			set { _calc.Style = value; }
		}
		
		/** @see @PlotPoint.Offset */
		public float Offset
		{
			get { return _calc.Offset; }
			set { _calc.Offset = value; }
		}
		
		/**
			An @AttractorConfig used to animate the position of the point.
			
			The default (null) will not do any animation.
		*/
		public AttractorConfig Attractor
		{
			get { return _animator.Motion as AttractorConfig; }
			set { _animator.Motion = value; }
		}
		
		PlotDataItemWatcher<PlotDataPoint> _watcher;
		protected override void OnRooted()
		{
			base.OnRooted();
			_watcher = new PlotDataItemWatcher<PlotDataPoint>(this,this);
			_calc.CheckAttractor(Attractor, this);
		}
			
		protected override void OnUnrooted()
		{
			_watcher.Dispose();
			_watcher = null;
			_animator.Unroot();
			base.OnUnrooted();
		}
		
		void IPlotDataItemListener<PlotDataPoint>.OnNewData( PlotDataPoint entry )
		{
			_animator.SetValue( _calc.PrepareEntry(entry), AnimUpdate );
		}
		
		void AnimUpdate( float2 value )
		{
			var p = _calc.ValueToPos(value);
			X = p.X;
			Y = p.Y;
		}
	}
}