using Uno;
using Uno.Collections;

using Fuse.Elements;

namespace Fuse.Drawing
{
	/**
		Utilities used to help draw curves and shapes.
		@hide
	*/
	public static class SurfaceUtil
	{
		/**
			Convert an EllipticArc segment into a series of BezierCurve segments.
			
			Even if the bakend supports arcs it's likely easier to call this rather than try and translate the parameters. Most backends end up using bezier curves anyway (CoreGraphics, Android, SVG in Web libraries).
		*/
		static public void EllipticArcToBezierCurve( float2 from, LineSegment arc, IList<LineSegment> curves )
		{
			if (EllipticArcOutOfRange( from, arc ))
			{
				curves.Add( new LineSegment{ Type = LineSegmentType.Straight, To = arc.To } );
				return;
			}
			
			var radius = Math.Abs(arc.A);
			var xAngle = arc.B.X;
			var center = float2(0);
			var angles = float2(0);
			
			EndpointToCenterArcParams( from, arc.To, ref radius, xAngle,
				arc.Flags.HasFlag( LineSegmentFlags.EllipticArcLarge ),
				arc.Flags.HasFlag( LineSegmentFlags.EllipticArcSweep ),
				out center, out angles );

			EllipticArcToBezierCurve( center, radius, xAngle, angles[0], angles[1], false, curves );
		}

		const float _zeroTolerance = 1e-05f;

		static internal bool EllipticArcOutOfRange( float2 from, LineSegment arc )
		{
			//F.6.2 Out-of-range parameters
			var len = Vector.Length( arc.To - from );
			if (len < _zeroTolerance)
				return true;
			
			var radius = Math.Abs(arc.A);
			if (radius.X < _zeroTolerance || radius.Y < _zeroTolerance)
				return true;

			return false;
		}
		
		static public void EllipticArcToBezierCurve( float2 center, float2 radius, float xAngle, float startAngle, 
			float deltaAngle, bool moveToStart, IList<LineSegment> curves )
		{
			var s = startAngle;
			var e = s + deltaAngle;
			bool neg = e < s;
			float sign = neg ? -1 : 1;
			var remain = Math.Abs(e - s);

			var prev = EllipticArcPoint( center, radius, xAngle, s );
			if (moveToStart)
				curves.Add( new LineSegment{ Type = LineSegmentType.Move, To = prev } );
			
			while( remain > _zeroTolerance )
			{
				var step = Math.Min( remain, Math.PIf / 4 );
				var signStep = step * sign;
				
				var p1 = prev;
				var p2 = SurfaceUtil.EllipticArcPoint( center, radius, xAngle, s + signStep );
				
				var alphaT = Math.Tan(signStep / 2);
				var alpha = Math.Sin(signStep) * (Math.Sqrt(4 + 3 * alphaT * alphaT)- 1) / 3;
				var q1 = p1 + alpha * EllipticArcDerivative( center, radius, xAngle, s );
				var q2 = p2 - alpha * EllipticArcDerivative( center, radius, xAngle, s + signStep );
				curves.Add( new LineSegment{ Type = LineSegmentType.BezierCurve, To = p2,
					A = q1, B = q2 });
				
				s += signStep;
				remain -= step;
				prev = p2;
			}
		}
		
		/**
			Perform the endpoint to center arc parameter conversion as detailed in the SVG 1.1 spec.
			F.6.5 Conversion from endpoint to center parameterization
			
			@param r must be a ref in case it needs to be scaled up, as per the SVG spec
		*/
		internal static void EndpointToCenterArcParams( float2 p1, float2 p2, ref float2 r_, float xAngle, 
			bool flagA, bool flagS, out float2 c, out float2 angles )
		{
			double rX = Math.Abs(r_.X);
			double rY = Math.Abs(r_.Y);
			
			//(F.6.5.1)
			double dx2 = (p1.X - p2.X) / 2.0;
			double dy2 = (p1.Y - p2.Y) / 2.0;
			double x1p = Math.Cos(xAngle)*dx2 + Math.Sin(xAngle)*dy2;
			double y1p = -Math.Sin(xAngle)*dx2 + Math.Cos(xAngle)*dy2;
			
			//(F.6.5.2)
			double rxs = rX * rX;
			double rys = rY * rY;
			double x1ps = x1p * x1p;
			double y1ps = y1p * y1p;
			// check if the radius is too small `pq < 0`, when `dq > rxs * rys` (see below)
			// cr is the ratio (dq : rxs * rys) 
			double cr = x1ps/rxs + y1ps/rys;
			if (cr > 1) {
				//scale up rX,rY equally so cr == 1
				var s = Math.Sqrt(cr);
				rX = s * rX;
				rY = s * rY;
				rxs = rX * rX;
				rys = rY * rY;
			}
			double dq = (rxs * y1ps + rys * x1ps);
			double pq = (rxs*rys - dq) / dq;
			double q = Math.Sqrt( Math.Max(0,pq) ); //use Max to account for float precision
			if (flagA == flagS)
				q = -q;
			double cxp = q * rX * y1p / rY;
			double cyp = - q * rY * x1p / rX;
			
			//(F.6.5.3)
			double cx = Math.Cos(xAngle)*cxp - Math.Sin(xAngle)*cyp + (p1.X + p2.X)/2;
			double cy = Math.Sin(xAngle)*cxp + Math.Cos(xAngle)*cyp + (p1.Y + p2.Y)/2;

			//(F.6.5.5)
			double theta = svgAngle( 1,0, (x1p-cxp) / rX, (y1p - cyp)/rY );
			//(F.6.5.6)
			double delta = svgAngle(
				(x1p - cxp)/rX, (y1p - cyp)/rY,
				(-x1p - cxp)/rX, (-y1p-cyp)/rY);
			delta = Math.Mod(delta, Math.PIf * 2 );
			if (!flagS)
				delta -= 2 * Math.PIf;

			r_ = float2((float)rX,(float)rY);
			c = float2((float)cx,(float)cy);
			angles = float2((float)theta, (float)delta);
		}

		//TODO: Check if this is one of our standard angle calculations
		static float svgAngle( double ux, double uy, double vx, double vy )
		{
			var u = float2((float)ux, (float)uy);
			var v = float2((float)vx, (float)vy);
			//(F.6.5.4)
			var dot = Vector.Dot(u,v);
			var len = Vector.Length(u) * Vector.Length(v);
			var ang = Math.Acos( Math.Clamp(dot / len,-1,1) ); //floating point precision, slightly over values appear
			if ( (u.X*v.Y - u.Y*v.X) < 0)
				ang = -ang;
			return ang;
		}
		
		/*
			Equations from:
				Drawing an elliptical arc using polylines, quadratic or cubic Bézier curves
					by L. Maisonobe
			http://www.spaceroots.org/documents/ellipse/elliptical-arc.pdf
		*/
		static public float2 EllipticArcPoint( float2 c, float2 r, float xAngle, float t )
		{
			return float2(
				c.X + r.X * Math.Cos(xAngle) * Math.Cos(t) - r.Y * Math.Sin(xAngle) * Math.Sin(t),
				c.Y + r.X * Math.Sin(xAngle) * Math.Cos(t) + r.Y * Math.Cos(xAngle) * Math.Sin(t));
		}
		
		static public float2 EllipticArcDerivative( float2 c, float2 r, float xAngle, float t ) 
		{
			return float2(
				-r.X * Math.Cos(xAngle) * Math.Sin(t) - r.Y * Math.Sin(xAngle) * Math.Cos(t),
				-r.X * Math.Sin(xAngle) * Math.Sin(t) + r.Y * Math.Cos(xAngle) * Math.Cos(t) );
		}

		static public bool AngleInRange(float angle, float start, float end)
		{
			if (end < start)
			{
				var t = end;
				end = start;
				start = t;
			}
			
			var delta = end - start;
			if (delta >= 2* Math.PIf)
				return true;
				
			angle = Math.Mod( angle, 2*Math.PIf);
			var pStartAngle = Math.Mod( start, 2*Math.PIf );
			var pEndAngle = pStartAngle + delta;

			if (angle >= pStartAngle && angle <= pEndAngle)
				return true;
			if (angle <= (pEndAngle - Math.PIf*2))
				return true;
			return false;
		}		
		
		static public float2 BezierCurveDerivative( float2 p0, float2 p1, float2 p2, float2 p3, float t )
		{
			var t2 = t * t;
			return 3 * (-(p0-3*p1-p3+3*p2)*t2  + 2*(p0-2*p1+p2)*t - p0 + p1);
		}
	}
}
