using Uno;
using Uno.Graphics;

using Fuse;
using Fuse.Elements;
using Fuse.Drawing.Internal;

namespace Fuse.Drawing.Primitives
{
	abstract class WedgeCoverage : LimitCoverage
	{
		public float StartAngle = 0;
		public float EndAngle = Math.PIf * 2;
		
		float2 StartVec: float2( Math.Sin(StartAngle), -Math.Cos(StartAngle));
		float2 EndVec: float2( -Math.Sin(EndAngle), Math.Cos(EndAngle));
		float2 NormVec: Vector.Normalize(StartVec+EndVec);
		
		float2 P: req(VertexPosition as float2)
			pixel VertexPosition;
		
		public float da0: Vector.Dot( P, StartVec );
		public float da1: Vector.Dot( P, EndVec );
		
		// miter limit of 0.0
		public float dm: Vector.Dot(P, NormVec);
		
		public float LimitCoverage:  req(DrawContext as DrawContext) req(da as float)
			req(Sharpness as float)
			Math.Clamp( 0.5f - da * DrawContext.ViewportPixelsPerPoint*Sharpness, 0, 1);
		
/*		public float Angle : req(OriginPosition as float2)
			Math.Atan2( pixel OriginPosition.Y, pixel OriginPosition.X );
		public float AngleDistance: 
			Math.Abs(StartAngle-Angle) < Math.Abs(Angle-EndAngle) ?
				(StartAngle-Angle) : (Angle-EndAngle);
				
		public float LimitCoverage: AngleDistance > 0 ? 0 : 1;*/
	}
	
	class ConvexWedgeCoverage : WedgeCoverage
	{
		float da: Math.Max( dm, Math.Max(da0,da1) );
	}
	
	class ConcaveWedgeCoverage : WedgeCoverage
	{
		float da: Math.Min( dm, Math.Min(da0,da1) );
	}
	
	public class Wedge
	{
		static public Wedge Singleton = new Wedge();

		ConvexWedgeCoverage _convexWedgeCoverage = new ConvexWedgeCoverage();
		ConcaveWedgeCoverage _concaveWedgeCoverage = new ConcaveWedgeCoverage();
		
		WedgeCoverage SetupWedgeCoverage( float startAngle, float endAngle )
		{
			var pStartAngle = Math.Mod( startAngle, 2*Math.PIf );
			var pEndAngle = Math.Mod( endAngle, 2*Math.PIf );
			if (pEndAngle < pStartAngle)
				pEndAngle += 2*Math.PIf;
			
			WedgeCoverage wc = _concaveWedgeCoverage;
			if ((pEndAngle - pStartAngle) < Math.PIf)
				wc = _convexWedgeCoverage;
			
			wc.StartAngle = pStartAngle;
			wc.EndAngle = pEndAngle;
			return wc;
		}
		
		StrokeCoverage _strokeCoverage = new StrokeCoverage();
		public void Stroke(DrawContext dc, Element node, float radius, Stroke stroke, float2 center,
			float startAngle, float endAngle, float smoothness)
		{
			var r = stroke.GetDeviceAdjusted(dc.ViewportPixelsPerPoint);
			var sc = _strokeCoverage;
			sc.Radius = r[0]/2;
			sc.Center = r[1];

			//include outer region for stroke
			var extend = Math.Max(0,r[0]+r[1]) + smoothness;
		
			var wc = SetupWedgeCoverage(startAngle, endAngle);
			Circle.Singleton.Draw(dc ,node, radius, stroke.Brush, sc, wc,
				extend, center, smoothness );
		}
		
		FillCoverage _fillCoverage = new FillCoverage();
		public void Fill(DrawContext dc, Element node, float radius, Brush brush, float2 center,
			float startAngle, float endAngle, float smoothness)
		{
			var wc = SetupWedgeCoverage(startAngle, endAngle);
			Circle.Singleton.Draw(dc, node, radius, brush, _fillCoverage, wc, smoothness,
				center,	smoothness);
		}
	}
}
