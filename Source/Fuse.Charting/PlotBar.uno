using Uno;
using Uno.UX;

using Fuse.Animations;
using Fuse.Controls;
using Fuse.Motion;
using Fuse.Motion.Simulation;

namespace Fuse.Charting
{
	public enum PlotBarStyle
	{
		/** Standard alignment of the Y-Axis to the baseline */
		Baseline,
		/** Uses Y as current value and Z as the previous value to produce a ranged bar */
		Range,
		/** Covers the complete area for this axis step, ignoring the actual Y value. This is useful if you wish to add a background to the item, or enabled interaction on the whole region. */
		Full,
	}

	/**
		Positions a plot bar.
		
		This automatically sets the `X`,`Y`,`Width`,`Heigth` and `Anchor` properties on the element. The result is undefined if you override one of these values. Use a child element if you wish to make an element relative to the PlotBar placement.
		

		# Example

		The following example draws a red bar chart using the `PlotBar` element and @Rectangle

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
						<c:DataSeries Data="{data}" />
						<c:PlotData>
							<c:PlotBar>
								<Rectangle Color="#F00" Height="100%" Margin="2" Alignment="Bottom"/>
							</c:PlotBar>
						</c:PlotData>
					</c:Plot>
				</Panel>
			</Panel>
	*/
	public class PlotBar : PlotElement
	{
		PlotBarStyle _style = PlotBarStyle.Baseline;
		public PlotBarStyle Style
		{
			get { return _style; }
			set 
			{
				if (_style == value)
					return;
					
				_style = value;
			}
		}
		
		/**
			An @AttractorConfig used to animate the position and size change of the bar.
			
			The default (null) will not do any animation.
		*/
		public AttractorConfig Attractor
		{
			get { return _animPosition.Motion as AttractorConfig; }
			set 
			{ 	
				_animPosition.Motion = value;
				_animSize.Motion = value;
				if (value.Unit != MotionUnit.Normalized )
					Fuse.Diagnostics.UserWarning( "Expecting Unit=\"Normalized\" for attractor", this );
			}
		}
		
		DestinationBehavior<float4>_animPosition = new DestinationBehavior<float4>();
		DestinationBehavior<float2>_animSize = new DestinationBehavior<float2>();
		
		internal override void OnDataPointChanged( PlotDataPoint entry )
		{
			var relValue = entry.RelativeValue;
			var isVert = entry.Plot.GetAxisOrientation(0) == PlotOrientation.Vertical;
			
			var barWidth = 1.0f / entry.Count;
			
			float barValue = 0, barBase = 0;
			switch (Style)
			{
				case PlotBarStyle.Baseline:
					barValue = relValue.Y - entry.Plot.PlotStats.Baseline.Y;
					barBase = entry.Plot.PlotStats.Baseline.Y;
					break;
					
				case PlotBarStyle.Range:
					barValue = relValue.Y - relValue.Z;
					barBase = relValue.Z;
					break;
					
				case PlotBarStyle.Full:
					barValue = 1;
					barBase = 0;
					break;
			}
				
			var barEnd = barBase + barValue;
			
			//we must align to the baseline so it always appears flat even with pixel precision and aliasing issues
			//this works better when combined with `SnapToPixels="true"` and partially avoids issue (3866)
			var primeAnchor = (isVert ? barEnd < barBase : barEnd > barBase) ? 1f : 0f;
			var secondAnchor = 0.5f;
			
			var axisBase = relValue.X;

			float nX, nY, nHeight, nWidth;
			float2 nAnchor;
			if (isVert)
			{
				nX = barBase;
				nY = 1-axisBase;
				nHeight = barWidth;
				nWidth = Math.Abs(barValue);
				nAnchor = float2( primeAnchor, secondAnchor);
			}
			else
			{
				nX = axisBase;
				nY = 1- barBase;
				nHeight = Math.Abs(barValue);
				nWidth = barWidth;
				nAnchor = float2( secondAnchor, primeAnchor);
			}
			
			_animPosition.SetValue( float4( nX, nY, nAnchor.X, nAnchor.Y ), AnimPosition );
			_animSize.SetValue( float2( nWidth, nHeight ), AnimSize );
		}
		
		void AnimPosition( float4 value )
		{
			X = new Size( value[0] * 100, Unit.Percent );
			Y = new Size( value[1] * 100, Unit.Percent );
			Anchor = new Size2( 
				new Size(value[2] * 100, Unit.Percent),
				new Size(value[3] * 100, Unit.Percent) );
		}
		
		void AnimSize( float2 value)
		{
			Width = new Size( value[0] * 100, Unit.Percent );
			Height = new Size( value[1] * 100, Unit.Percent );
		}
	}
}
