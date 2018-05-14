using Uno;

using Fuse.Elements;

namespace Fuse.Charting
{
	/**
		Controls the size-related aspects of the Plot to create a responsive layout.
		
		This is placed within the element where the primary plot data will actually be drawn. It adjusts the properties of the plot based on the available size.
	*/
	public class PlotArea : Behavior
	{
		float2 _stepSize = float2(100);
		bool[] _hasStepSize = new bool[2];
		
		/**
			The desired size of the steps (spaces between ticks, or the size of the colums), in the plot.
			
			This is used to calculate how much data is plotted for Count axes, or how many ticks are displayed on range axis. The actual count depends on the size and the nature of the data.
		*/
		public float XStepSize
		{	
			get { return _stepSize[0]; }
			set { SetStepSize(0, value); }
		}

		/** @see XStepSize */
		public float YStepSize
		{
			get { return _stepSize[1]; }
			set { SetStepSize(1, value); }
		}
		
		void SetStepSize( int axis, float value )
		{
			if (_stepSize[axis] == value && _hasStepSize[axis])
				return;
		
			_stepSize[axis] = value;
			_hasStepSize[axis] = true;
			ListenPlaced(IsRootingCompleted);
			Update();
		}
		
		Element _parentElement;
		PlotBehavior _plot;
		protected override void OnRooted()
		{
			base.OnRooted();
			_parentElement = Parent as Element;
			if (_parentElement == null)
				Fuse.Diagnostics.UserError( "Parent must be an Element", this );
			
			_plot = PlotBehavior.FindPlot(this);
			if (_plot == null)
				Fuse.Diagnostics.UserError( "Could not find PlotBehavior", this );
			ListenPlaced(true);
			Update();
		}
		
		void Update()
		{
			if (_parentElement != null)
				Placed(_parentElement.ActualSize);
		}
		
		protected override void OnUnrooted()
		{
			ListenPlaced(false);
			_parentElement = null;
			_plot = null;
			base.OnUnrooted();
		}
		
		bool _listenPlaced;
		void ListenPlaced(bool rooted)
		{
			var should = rooted && (_hasStepSize[0] || _hasStepSize[1]) && (_parentElement != null)
				&& (_plot != null);
			if (should == _listenPlaced)
				return;
				
			if (should)
				_parentElement.Placed += OnPlaced;
			else
				_parentElement.Placed -= OnPlaced;
			_listenPlaced = should;
		}

		void OnPlaced(object sender, PlacedArgs args)
		{
			if (_plot == null)
				return;

			Placed(args.NewSize);
		}
		
		void Placed( float2 size )
		{
			for (int i=0; i < 2; ++i)
			{
				if (!_hasStepSize[i])
					continue;
					
				var isX = _plot.GetAxisOrientation( i ) == PlotOrientation.Horizontal;
				var axisSize = isX ? size.X : size.Y;
				
				var count = (int)(axisSize / _stepSize[i]);
				count = Math.Max(1,count);
				
				if (_plot.IsCountAxis(i))	
					_plot.Limit = count;
				else
					_plot.DataSpec.SetAxisSteps( i, count );
			}
		}
	}
	
}
