using Uno;
using Uno.Collections;
using Uno.UX;


namespace Fuse.Controls
{
	/**
		Draws a polygon with a number of equal length sides.
	*/
	public partial class RegularPolygon : Shape
	{
		int _sides = 5;
		public int Sides
		{
			get { return _sides; }
			set
			{
				if (value == _sides) return;
				_sides = value;
				InvalidateSurfacePath();
				OnPropertyChanged("Sides");
			}
		}

	}
}