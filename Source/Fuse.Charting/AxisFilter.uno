using Uno;

namespace Fuse.Charting
{
	/**
		Common filtering logic to apply to axis items.
	*/
	class AxisFilter
	{
		public int2 SkipEnds { get; private set; }
		public int Group { get; private set; }
		public bool ExcludeExtend { get; private set; }
		
		public AxisFilter()
		{
			SkipEnds = int2(0);
			Group = 1;
			ExcludeExtend = true;
		}
		
		/**
			@return false if there is no filtering of the source data required
		*/
		public bool RequireFilter
		{
			get
			{
				return SkipEnds != int2(0) ||
					Group != 1 ||
					ExcludeExtend;
			}
		}
				
		public bool SetSkipEnds(int2 value) 
		{
			if (value == SkipEnds)
				return false;
			SkipEnds = value;
			return true;
		}
		
		public bool SetGroup(int value)
		{
			value = Math.Max(1,value);
			if (Group == value)
				return false;
			Group = value;
			return true;
		}
		
		public bool SetExcludeExtend(bool value)
		{
			if (ExcludeExtend == value)
				return false;
			ExcludeExtend = value;
			return true;
		}

		//set at rooting time
		public PlotBehavior Plot;
		public bool IsCountAxis;

		public int GetWindowIndex(int axisIndex)
		{
			if (IsCountAxis)
				return axisIndex - Plot.PlotStats.Offset;
			return axisIndex;
		}

		public bool Accept(object axisEntryObject, int axisIndex, int axisCount)
		{
			int w;
			return Accept(axisEntryObject, axisIndex, axisCount, out w);
		}

		public bool Accept(object axisEntryObject, int axisIndex, int axisCount, out int windowIndex)
		{
			var axisEntry = axisEntryObject as AxisEntry;
			if (axisEntry != null)
				return Accept( axisEntry.Index, axisIndex, axisCount, out windowIndex);
				
			var plotData = axisEntryObject as PlotDataPoint;
			if (plotData != null)
				return Accept( plotData.Index, axisIndex, axisCount, out windowIndex);
				
			windowIndex = 0;
			return false;
		}
		
		bool Accept(int dataIndex, int axisIndex, int axisCount, out int windowIndex)
		{
			if (Plot == null)
			{
				windowIndex = 0;
				return false;
			}
				
			windowIndex = GetWindowIndex(dataIndex);

			//use true index for group to avoid alternating visual labels if the user steps in non-group increments
			if ((dataIndex % Group) != 0)
				return false;
				
			//exclude the entire group if it's outside the end
			if ((axisIndex + Group - 1) >= axisCount)
				return false;
				
			var skip = SkipEnds;
			if (ExcludeExtend && IsCountAxis)
				skip += Plot.PlotStats.RangeExtended;
			if (axisIndex < skip[0] || axisIndex >= (axisCount - skip[1]))
				return false;
				
			return true;
		}
	}
}