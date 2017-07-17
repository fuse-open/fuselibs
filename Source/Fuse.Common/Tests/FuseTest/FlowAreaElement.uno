using Uno;
using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace FuseTest
{
	/**
		Like an Area control but fills the area with logically flowing boxes. This can be used to simulate
		wrapping text, or a vertically wrapping element.
	*/
	public class FlowAreaElement : Element
	{
		/* How many cells to arrange in the area */
		public int Length { get; set; }
		
		/* The size of the cells. The default is 0,0 to force using an explicit size in the tests */
		public float2 CellSize { get; set; }
		
		protected override float2 GetContentSize( LayoutParams lp )
		{
			const float zeroTolerance = 1e-05f;
			if (CellSize.X < zeroTolerance || CellSize.Y < zeroTolerance)
			{
				Fuse.Diagnostics.UserError( "invalid CellSize", this );
				return float2(0,0);
			}
			
			bool hasX, hasY;
			var f = lp.GetAvailableSize(out hasX, out hasY);
			
			var xCount = Math.Min( Length, (int)Math.Floor(f.X / CellSize.X) );
			if (hasX && xCount > 0)
				return float2( xCount * CellSize.X, RoundUpDiv(Length, xCount) * CellSize.Y);

			var yCount = Math.Min( Length, (int)Math.Floor(f.Y / CellSize.Y) );
			if (hasY && yCount > 0)
				return float2( RoundUpDiv(Length, yCount) * CellSize.X, yCount * CellSize.Y );
				
			//use a square aspect (wrt cell count, not size)
			var aCount = (int)Math.Max( 1.0, Math.Sqrt( Length ) );
			return float2( aCount * CellSize.X, RoundUpDiv(Length, aCount) * CellSize.Y);
		}
		
		int RoundUpDiv( int num, int den )
		{
			return (num + den - 1) / den;
		}

		protected override void OnDraw(Fuse.DrawContext dc) { }
	}
}
