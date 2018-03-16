using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Internal;

namespace Fuse.Controls
{
	/**
		Determines how the bounds of a path are calculated for fitting into an element.
	*/
	public enum FitMode
	{
		/** The bounds are taken as 0,0 for the top-left to the maximum bounds of `Data`. Use this is you have positioned your drawing relative to the top-left origin and would like to keep that space. */
		GeometryMaximum,
		/** The bounds of the drawing are the minimum size required to fully contain the shape specified in `Data`. Thus only relative values in the Data matter.  Use this when stretching your image to fill the `Path` element.*/
		ShrinkToGeometry,
		/** Explicit extents set by the `Extents` property. Those extents are considered the canvas size for all `Data` points. Use this when layering multiple paths on the same canvas to preserve their relative positions and sizes. */
		Extents,
	}

	public partial class Path : SegmentedShape
	{
		List<LineSegment> _segments = new List<LineSegment>();
		string _data;
		/**
			A string contained the SVG formatted path data. As specified by SVG 1.1.
			
			The following draws a rectangle with a blue stroke:
			
				<Path Data="M 100 100 L 300 100 L 200 300 z" StrokeColor="#008" StrokeWidth="2"/>

			The size of the resulting shape depends on `FitMode`.
		*/
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
		
		/**
			How are the bounds, calculated by `Data` and `FitMode`, stretched to fill the available area in `Path`
		*/
		public StretchMode StretchMode
		{
			get { return sizing.stretchMode; }
			set
			{
				if (sizing.SetStretchMode(value))
					OnShapeLayoutChanged();
			}
		}
		
		/** 
			Whether stretching, shrinking, or both are allowed.
		*/
		public StretchDirection StretchDirection
		{
			get { return sizing.stretchDirection; }
			set
			{
				if (sizing.SetStretchDirection(value) )
					OnShapeLayoutChanged();
			}
		}

		/** 
			For images that are not stretched to fill the bounds of `Path`, how are they aligned.
		*/
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
		/**
			Which regions of the polygon are filled by the brushes.
		*/
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
		/**
			How are the bounds of the image calculated from the `Data`, and how is the image fit into those bounds.
		*/
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
		/**
			Sets explicit extents to use instead of calculating the bounds of `Data`.
			
			Setting this implicitly sets `FitMode == Extents`
		*/
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
		//https://github.com/fusetools/fuselibs-private/issues/3718
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