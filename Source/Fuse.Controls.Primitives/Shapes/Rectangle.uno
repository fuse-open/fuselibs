using Uno;
using Uno.UX;

using Fuse.Drawing;

namespace Fuse.Controls
{
	/** Displays a rectangle.

		Setting the rectangle's `Color` property gives it a solid color fill:

			<Rectangle Color="Blue" Width="100" Height="100" />
		
		Rectangles can have an arbitrary number of @Fills and @Strokes. Fills are of 
		type @Brush, and can be specified as tags inside the rectangle.

		> Note that by default, a Rectangle has no fills or strokes, making it 
		> invisible unless you provide some or specify something. 

		## Example		

		    <Grid Alignment="Center" Rows="100,100,100" Columns="100">
				<Rectangle Margin="10" CornerRadius="4">
					<SolidColor Color="#a542db" />
				</Rectangle>
				<Rectangle Margin="10" CornerRadius="4">
					<LinearGradient>
						<GradientStop Offset="0" Color="#a542db" />
						<GradientStop Offset="1" Color="#3579e6" />
					</LinearGradient>
				</Rectangle>
				<Rectangle Margin="10" CornerRadius="4">
					<Stroke Offset="4" Width="1" Color="#3579e6" />
					<SolidColor Color="#3579e6" />
				</Rectangle>
			</Grid>
	*/
	public partial class Rectangle : Shape
	{
		float4 _cornerRadius;
		/** The size of the rounded corner, in points. 

			By default, rectangles have sharp corners.

			@default 0
		*/
		[UXOriginSetter("SetCornerRadius")]
		public float4 CornerRadius
		{
			get { return _cornerRadius; }
			set { SetCornerRadius(value, this); }
		}
		
		/**
			Limits the corner radius to half the size provided (usually the ActualSize).
		*/
		float4 GetConstrainedCornerRadius( float2 sz )
		{
			float4 useCornerRadius = CornerRadius;
			var mn = Math.Min(sz.X/2, sz.Y/2);
			for (int i=0; i < 4; ++i)
				useCornerRadius[i] = Math.Clamp(useCornerRadius[i],0,mn);
			return useCornerRadius;
		}
		
		float4 ConstrainedCornerRadius
		{
			get { return GetConstrainedCornerRadius(ActualSize); }
		}
		
		public static readonly Selector CornerRadiusPropertyName = "CornerRadius";
		public void SetCornerRadius(float4 value, IPropertyListener origin)
		{
			if (_cornerRadius != value)
			{
				_cornerRadius = value;
				OnPropertyChanged(CornerRadiusPropertyName, origin);
				InvalidateSurfacePath();
			}
		}
	}
	
}
