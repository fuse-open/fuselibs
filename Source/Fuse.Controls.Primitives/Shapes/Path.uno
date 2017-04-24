using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Internal;

namespace Fuse.Controls
{
	public enum FitMode
	{
		GeometryMaximum,
		ShrinkToGeometry,
		/** Explicit extents set by the `Extents` property */
		Extents,
	}

	public partial class Path : Shape
	{
		List<LineSegment> _segments = new List<LineSegment>();
		string _data;
		public string Data
		{
			get { return _data; } //TODO
			set 
			{ 
				if (_data == value)
					return;
				_data = value;
				_segments.Clear();
				LineParser.ParseSVGPath(value, _segments);
				InvalidateSurfacePath();
			}
		}
		
		SizingContainer sizing = new SizingContainer();
		internal SizingContainer Sizing { get { return sizing; } }
		
		public StretchMode StretchMode
		{
			get { return sizing.stretchMode; }
			set
			{
				if (sizing.SetStretchMode(value))
					OnShapeLayoutChanged();
			}
		}
		
		public StretchDirection StretchDirection
		{
			get { return sizing.stretchDirection; }
			set
			{
				if (sizing.SetStretchDirection(value) )
					OnShapeLayoutChanged();
			}
		}

		public Fuse.Elements.Alignment ContentAlignment
		{
			get { return sizing.align; }
			set
			{
				if (sizing.SetAlignment(value) )
					OnShapeLayoutChanged();
			}
		}

		FillRule _fillRule;
		public FillRule FillRule
		{
			get { return _fillRule; }
			set
			{
				_fillRule = value;
				OnShapeLayoutChanged();
			}
		}		
		
		FitMode _fitMode = FitMode.ShrinkToGeometry;
		public FitMode FitMode
		{
			get { return _fitMode; }
			set
			{
				if (value != _fitMode )
				{
					_fitMode = value;
					OnShapeLayoutChanged();
				}
			}
		}
		
		void OnShapeLayoutChanged()
		{
			InvalidateSurfacePath();
			InvalidateLayout();
		}
		
		float4 _extents;
		public float4 Extents
		{
			get { return _extents; }
			set
			{
				if (_extents == value && _fitMode == FitMode.Extents)
					return;
					
				_extents = value;
				_fitMode = FitMode.Extents;
				OnShapeLayoutChanged();
			}
		}
		
		float2 GetDesiredContentSize()
		{
			var hi = float2(0);
			var lo = float2(0);
			var bounds = CalcNaturalExtents();
			
			switch( FitMode )
			{
				case FitMode.GeometryMaximum:
					lo = float2(0);
					hi = bounds.Maximum;
					break;

				case FitMode.ShrinkToGeometry:
					lo = bounds.Minimum;
					hi = bounds.Maximum;
					break;
					
				case FitMode.Extents:
					lo = Extents.XY;
					hi = Extents.ZW;
					break;
			}

			var natural = hi - lo;
			return natural;
		}
		
		
		protected override float2 GetContentSize( LayoutParams lp )
		{
			var natural = GetDesiredContentSize();
			var r= Sizing.ExpandFillSize( natural, lp );
			return r;
		}

		//TODO: This defniitely needs to be cached if the path itself has not changed (it is called often enough
		//to make a difference)
		//https://github.com/fusetools/fuselibs/issues/3718
		Rect CalcNaturalExtents()
		{
			return LineMetrics.GetBounds(_segments);
		}
		
		protected override Rect CalcShapeExtents()
		{
			var pos = CalcPositioning();
			//follows logic of CreateSurfacePath
			var mn = (pos.NaturalExtents.Minimum - pos.Extents.Minimum) * pos.Scale + pos.Offset + pos.Extents.Minimum;
			var mx = (pos.NaturalExtents.Maximum - pos.Extents.Minimum) * pos.Scale + pos.Offset + pos.Extents.Minimum;
			
			var r = new Rect( mn, mx - mn ); //origin/size form
			return r;
		}
		
		protected override void InvalidateSurfacePath()
		{
			base.InvalidateSurfacePath();
			InvalidateRenderBounds();
		}
		
		struct Positioning
		{
			public float2 Scale;
			public float2 Offset;
			public Rect NaturalExtents;
			public Rect Extents;
		}
		
		Positioning CalcPositioning()
		{
			var naturalExtents = CalcNaturalExtents();
			var desiredSize = GetDesiredContentSize();
			var scale = Sizing.CalcScale( ActualSize, desiredSize );
			var offset = Sizing.CalcOrigin( ActualSize, desiredSize * scale );

			var extents = naturalExtents;
			
			switch( FitMode )
			{
				case FitMode.GeometryMaximum:
					break;

				case FitMode.ShrinkToGeometry:
					offset -= extents.Minimum;
					break;
					
				case FitMode.Extents:
					offset -= extents.Minimum;
					extents = new Rect( Extents.XY, Extents.ZW - Extents.XY );
					break;
			}

			return new Positioning{ Scale = scale, Offset = offset, NaturalExtents = naturalExtents,
				Extents = extents };
		}
	}
}