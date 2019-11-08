using Uno;

using Fuse.Animations;
using Fuse.Controls;
using Fuse.Motion;
using Fuse.Motion.Simulation;

namespace Fuse.Charting
{
	/**
		Creates a wedge shape for a pie chart.
		
		This sets the `StartAngle` and `EndAngle` of the base `Ellipse` class. You should not override this properties, though other `Ellipse` and `Shape` properties are okay.
		
			<Panel BoxSizing="FillAspect" Aspect="1">
				<c:PlotData>
					<c:PlotWedge StrokeColor="#000" StrokeWidth="2">
				</c:PlotData>
			</Panel>
	*/
	public class PlotWedge : Ellipse, IPlotDataItemListener<PlotDataPoint>
	{
		DestinationBehavior<float> _animStart = new DestinationBehavior<float>();
		DestinationBehavior<float> _animEnd = new DestinationBehavior<float>();

		/**
			Specifies where on a circle to start drawing our wedges.

			The range is from 0 to 1, relative to the circumference of a full circle.
		*/
		public float RadialOffset { get; set; }

		/**
			Specifies how much of a circle our wedges will consume.

			The range is from 0 to 1, relative to the circumference of a full circle.
		*/
		public float RadialScale { get; set; }

		public PlotWedge()
		{
			RadialScale = 1;
		}

		/**
			An @AttractorConfig used to animate a change in the shape of the wedge.
			
			The default (null) will not do any animation.
		*/
		public AttractorConfig Attractor
		{
			get { return _animStart.Motion as AttractorConfig; }
			set 
			{ 
				_animStart.Motion = value; 
				_animEnd.Motion = value;
			}
		}
		
		PlotDataItemWatcher<PlotDataPoint> _watcher;
		protected override void OnRooted()
		{
			base.OnRooted();
			_watcher = new PlotDataItemWatcher<PlotDataPoint>(this,this);
		}
			
		protected override void OnUnrooted()
		{
			_watcher.Dispose();
			_watcher = null;
			_animStart.Unroot();
			_animEnd.Unroot();
			base.OnUnrooted();
		}
		
		/*
			In order to keep a full circle during animation we need to animat the start and end location separately. This ensures all wedges will have their common points in sync. This is really not an optimal solution, but it's one that works without creating a specialized pie chart visual
		*/
		void IPlotDataItemListener<PlotDataPoint>.OnNewData( PlotDataPoint entry )
		{
			//use normalized input to be consistent with other convenience clases, allows the same
			//AttractorConfig to be used everywhere
			_animStart.SetValue( entry.AccumulatedWeight.Y, AnimStart );
			_animEnd.SetValue( entry.CumulativeWeight.Y, AnimEnd );
		}
		
		const float PI2 = Math.PIf * 2;

		void AnimStart( float value )
		{
			StartAngle = PI2 * RadialOffset + value * PI2 * RadialScale;
		}
		
		void AnimEnd( float value )
		{
			EndAngle = PI2 * RadialOffset + value * PI2 * RadialScale;
		}
	}
}