using Uno;
using Uno.UX;

using Fuse.Drawing;

namespace Fuse.Controls
{
	/** Displays a star

		Star is a @Shape and does not have fills, strokes and a size by default,
		you must set this for it to be visible. 

		## Example:

			<Star Width="200" Height="200" Ratio="0.4" >
				<LinearGradient>
					<GradientStop Offset="0" Color="#0ee" />
					<GradientStop Offset="1" Color="#e0e" />
				</LinearGradient>
			</Star>

	*/
	public partial class Star : Shape
	{
		int _points = 5;
		public int Points
		{
			get { return _points; }
			set
			{
				if (value == _points) return;
				_points = value;
				InvalidateSurfacePath();
				OnPropertyChanged("Points");
			}
		}
		
		float _ratio = 0.5f;
		public float Ratio
		{
			get { return _ratio; }
			set
			{
				if (value == _ratio)
					return;
				_ratio = value;
				InvalidateSurfacePath();
				OnPropertyChanged("Ratio");
			}
		}
		
		float _roundRatio;
		public float RoundRatio 
		{ 
			get { return _roundRatio; }
			set
			{
				if (value ==_roundRatio)
					return;
				_roundRatio = value;
				InvalidateSurfacePath();
				OnPropertyChanged("RoundRatio");
			}
		}

		float _degrees = 0;
		public float RotationDegrees
		{
			get { return _degrees; }
			set
			{
				if (value == _degrees)
					return;
				_degrees = value;
				InvalidateSurfacePath();
				OnPropertyChanged("RotationDegrees");
			}
		}
		
		internal float RotationRadians
		{
			get { return _degrees / 180 * Math.PIf; }
		}
	}
}
