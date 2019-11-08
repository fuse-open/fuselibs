using Uno;
using Uno.UX;

using Fuse.Animations;
using Fuse.Controls;
using Fuse.Motion;
using Fuse.Motion.Simulation;

namespace Fuse.Charting
{
	/** Where the point is being positioned */
	public enum PlotPointStyle
	{
		/** Position based on the X/Y values in a rectangular layout */
		Axial,
		/** For a pie chart, positioned at the center of edge wedge (on the edge of the circle). This is based on the weight and accumulated weight of each segment. */
		Radial,
		/** For a spider chart, the point is placed around the circle based on the relativeX value. The distance away from center on the Y value. */
		Angular,
		/** Like Angular, except always positiong at the edge of the circle. */
		AngularFull,
	}
	
	public enum PlotPointAnchor
	{
		/** Axial = Center, Radial = Radial */
		Default,
		/** The `Anchor` property is not set. Use this is you wish to specify an explicit `Anchor` */
		None,
		/** The anchor is set to 50%,50%, the default*/
		Center,
		/** The anchor is set to position the element on the outside of a circle so the bounds don't overlap */
		Radial,
	}
	
	/** 
		Common calculations for PlotPoint and PlotCurvePoint
	*/
	struct PointCalculator
	{
		public PlotPointStyle Style;
		public float Offset;
		
		public void Init()
		{
			Style = PlotPointStyle.Axial;
			Offset = 0;
		}
		
		public void CheckAttractor( AttractorConfig attractor, object where )
		{
			if (attractor != null)
			{
				//still deciding, but leaning towards normalized everywhere (it's the simplest)
				if (/*Style == PlotPointStyle.Axial &&*/ attractor.Unit != MotionUnit.Normalized )
					Fuse.Diagnostics.UserWarning( "Expecting Unit=\"Normalized\" for attractor", where );
				//if (Style == PlotPointStyle.Radial && attractor.Unit != MotionUnit.Radians )
				//	Fuse.Diagnostics.UserWarning( "Expecting Unit=\"Radians\" for attractor", where );
			}
		}
		

		public float2 ValueToPos( float2 value )
		{
			switch (Style)
			{
				case PlotPointStyle.Axial:
					return value.XY;
			
				case PlotPointStyle.AngularFull:
				case PlotPointStyle.Radial:
				{
					var len = 1 + Offset;
					return float2( (Math.Cos(value.X) * len + 1) / 2,
						(Math.Sin(value.X) * len + 1) / 2);
				}
				
				case PlotPointStyle.Angular:
				{
					var len = value[1] + Offset;
					return float2( (Math.Cos(value[0]) * len + 1) / 2,
						(Math.Sin(value[0]) * len + 1) / 2);
				}
			}
			
			return float2(0);
		}
		
		public float2 AngleToAnchor( float angle )
		{
			angle = PiRange(angle);
			var pi = Math.PIf;

			//calculate tolerance for side placement (box will just border on the side)
			var considerOffset = Math.Clamp( Offset, 0, 0.2f ); //after a point it just starts looking wrong
			var axisEps = Math.Acos( 1 - considerOffset );
			
			//expects -pi ... +pi range
			return angle < -pi + axisEps ? float2(1,0.5f) :
				angle < -pi/2-axisEps ? float2(1,1) :
				angle < -pi/2+axisEps ? float2(0.5f,1) :
				angle < -axisEps ? float2(0,1) :
				angle < axisEps ? float2(0,0.5f) :
				angle < pi/2-axisEps ? float2(0,0) :
				angle < pi/2+axisEps ? float2(0.5f,0) :
				angle < pi-axisEps ? float2(1,0) : float2(1,0.5f);
		}
		
		public float2 PrepareEntry( PlotDataPoint entry )
		{
			var value = float2(0);
			var rel = entry.ScreenRelativeValue;
			
			switch (Style)
			{
				case PlotPointStyle.Axial:
					value = float2(rel.X, rel.Y);
					break;
					
				case PlotPointStyle.Radial:
				{
					var angle = (entry.AccumulatedWeight.Y + entry.Weight.Y / 2) * Math.PIf * 2;
					value = float2(angle, 0);
					break;
				}
				
				case PlotPointStyle.AngularFull:
				case PlotPointStyle.Angular:
				{
					value = float2(rel.X * Math.PIf * 2, 1 - rel.Y);
					break;
				}
			}
			
			return value;
		}
		
		//force angle into -pi...pi range
		static float PiRange(float a)
		{
			var l = Math.Floor( (a + Math.PIf) / (Math.PIf * 2) );
			return a -  l * Math.PIf * 2;
		}
		
		public bool IsRadial
		{
			get { return Style == PlotPointStyle.Radial || Style == PlotPointStyle.Angular
				|| Style == PlotPointStyle.AngularFull; }
		}
	}
	
	/**
		A `Panel` positioned on the data point for a chart. This is an easy way to position an object at the correct position for the current plot data.
		
		This panel has a default of `Anchor="50%,50%"`.  This can be changed with `PointAnchor`
		
		This panel does not have any default size.
	*/
	public class PlotPoint : PlotElement
	{
		DestinationBehavior<float2>_animator = new DestinationBehavior<float2>();

		/**
			Specifies where on a circle to start drawing our points.

			The range is from 0 to 1, relative to the circumference of a full circle.
		*/
		public float RadialOffset { get; set; }

		/**
			Specifies how much of a circle our points will consume.

			The range is from 0 to 1, relative to the circumference of a full circle.
		*/
		public float RadialScale { get; set; }

		public PlotPoint()
		{
			Anchor = new Size2( new Size(50, Unit.Percent), new Size(50,Unit.Percent) );
			RadialScale = 1;
			_calc.Init();
		}
		
		PointCalculator _calc;
		/**
			The style of the point which primarily determines the position where it is located.
		*/
		public PlotPointStyle Style
		{
			get { return _calc.Style; }
			set { _calc.Style = value; }
		}
		
		/**
			For a Radial style specifies the offset, as a factor of the element size, from the edge of the circle to the anchor point.
		*/
		public float PointOffset
		{
			get { return _calc.Offset; }
			set { _calc.Offset = value; }
		}
		
		
		PlotPointAnchor _anchor = PlotPointAnchor.Default;
		/**
			The desired `Element.Anchor` for this `PlotPoint`.
		*/
		public PlotPointAnchor PointAnchor
		{
			get { return _anchor; }
			set { _anchor = value; }
		}
		
		PlotPointAnchor EffectivePointAnchor
		{
			get
			{
				if (PointAnchor == PlotPointAnchor.Default)
					return _calc.IsRadial ? PlotPointAnchor.Radial : PlotPointAnchor.Center;
				return PointAnchor;
			}
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
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_calc.CheckAttractor(Attractor, this);
		}

		void AnimUpdate( float2 value )
		{
			value.X *= RadialScale;
			value.X += RadialOffset * Math.PIf * 2;

			var p = _calc.ValueToPos(value);
			X = new Size( p.X * 100, Unit.Percent );
			Y = new Size( p.Y * 100, Unit.Percent );
					
			if (EffectivePointAnchor == PlotPointAnchor.Radial)
			{
				var position = _calc.AngleToAnchor(value.X);
				Anchor = new Size2( new Size( position.X * 100, Unit.Percent ),
				new Size( position.Y * 100, Unit.Percent ) );
			}
		}
		
		internal override void OnDataPointChanged( PlotDataPoint entry )
		{
			_animator.SetValue( _calc.PrepareEntry(entry), AnimUpdate );
		}
		
		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			_animator.Unroot();
		}
		
	}
}