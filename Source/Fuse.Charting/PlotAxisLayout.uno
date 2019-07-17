using Uno;
using Uno.Collections;

namespace Fuse.Charting
{
	public enum PlotAxisLayoutAxis
	{
		//numbers must match axes index to allow direct (int) casting
		X = 0,
		Y = 1,
	}
	
	public enum PlotAxisLayoutPosition
	{	
		/** Layout is grid-like with each cell positioned in the top-left position of the available area */
		Cell,
		/** Layout is directly at the tick point, suitable for using with an Anchor based layout */
		Anchor,
	}
	
	/**
		Positions elements along an axis' tick locations.
		
		Consider using @PlotAxis instead to provide labels for the plot. It will use this layout.
		
		@advanced
	*/
	public class PlotAxisLayout : Fuse.Layouts.Layout
	{
		PlotAxisLayoutAxis _axis = PlotAxisLayoutAxis.X;
		public PlotAxisLayoutAxis Axis
		{
			get { return _axis; }
			set
			{
				if (_axis == value)
					return;
					
				_axis = value;
				InvalidateLayout();
			}
		}
		
		PlotAxisLayoutPosition _position = PlotAxisLayoutPosition.Cell;
		public PlotAxisLayoutPosition ContentPosition
		{
			get { return _position; }
			set
			{
				if (_position == value)
					return;
					
				_position = value;
				InvalidateLayout();
			}
		}

		int AxisIndex
		{
			get { return Axis == PlotAxisLayoutAxis.X ? 0 : 1; }
		}
		
		void OnDataChanged(object s, DataChangedArgs args)
		{
			InvalidateLayout();
		}
		
		struct CellSizing
		{
			public LayoutParams LP;
			public float2 Step;
			public float2 Origin;
			public bool IsVert;
		}
		
		int _stepCount;
		public int StepCount
		{
			get { return _stepCount; }
			set
			{
				if (_stepCount == value)
					return;
					
				_stepCount = Math.Max(1,value);
				InvalidateLayout();
			}
		}
		
		PlotOrientation _orientation;
		public PlotOrientation Orientation
		{
			get { return _orientation; }
			set
			{
				if (_orientation == value)
					return;
					
				_orientation = value;
				InvalidateLayout();
			}
		}
		
		float _positionBase;
		public float ContentPositionBase
		{
			get { return _positionBase; }
			set
			{
				if (_positionBase == value)
					return;
					
				_positionBase = value;
				InvalidateLayout();
			}
		}
		
		float _scale = 1;
		public float Scale
		{
			get { return _scale; }
			set 
			{
				if (_scale == value)
					return;
					
				_scale = value;
				InvalidateLayout();
			}
		}
		
		CellSizing CellSize(LayoutParams lp)
		{
			var nlp = lp.CloneAndDerive();
			
			var count = StepCount;
			var step = float2(0);
			var origin = float2(0);
			var isVert = Orientation == PlotOrientation.Vertical;
			if (isVert)
			{
				var sz = nlp.Size.Y / count;
				step.Y = -sz;
				nlp.SetY( sz * Scale );
				origin = float2(0,lp.Size.Y);
			}
			else
			{
				step.X = nlp.Size.X / count;
				nlp.SetX( step.X * Scale );	
			}
			
			return new CellSizing{ LP = nlp, Step = step, Origin = origin, IsVert = isVert };
		}
		
		internal override float2 GetContentSize(Visual container, LayoutParams lp)
		{
			var cs = CellSize(lp);
			
			var max = float2(0);
			var count = 0;
			for (var n = container.FirstChild<Visual>(); n != null; n = n.NextSibling<Visual>())
			{
				if (!AffectsLayout(n))
					continue;
					
				var sz = n.GetMarginSize( cs.LP );
				max = Math.Max(sz,max);
				count++;
			}
			
			if (cs.IsVert)
				max.Y = max.Y * count;
			else
				max.X = max.X * count;
			
			return max;
		}
		
		internal override void ArrangePaddingBox(Visual container, float4 padding, LayoutParams lp)
		{
			if (padding != float4(0))
				Fuse.Diagnostics.UserWarning( "PlotAxisLayout does not support the `Padding` property", this );
				
			var cs = CellSize(lp);

			var dataOffset = ContentPositionBase;
			var posOffset = ContentPosition == PlotAxisLayoutPosition.Cell ? -Math.Abs(cs.Step/2) : float2(0);
			
			var c = 0;
			for (var n = container.FirstChild<Visual>(); n != null; n = n.NextSibling<Visual>())
			{
				if (ArrangeMarginBoxSpecial(n, padding, lp))
					continue;

				var axisIndex = c;
				//If the item is an AxisEntry (which it's expected to be), use that to determine what label
				//it is. This allows for filtering in PlotAxis
				var axisEntry = GetNodeAxisEntry(n);
				if (axisEntry != null)
					axisIndex = axisEntry.ScreenIndex;
				
				n.ArrangeMarginBox( (axisIndex + dataOffset) * cs.Step + posOffset + cs.Origin, cs.LP );
				c++;
			}
		}

		/** Locate the AxisEntry for this item, assuming the setup of a the `Each` from `PlotAxis`  as the immediate parent */
		AxisEntry GetNodeAxisEntry(Node n)
		{
			var provider = n.ContextParent as Node.ISubtreeDataProvider;
			if (n == null)
				return null;
			
			object o;
			provider.TryGetDataProvider( n, Node.DataType.Prime, out o );
			return o as AxisEntry;
		}
		
	}
}
