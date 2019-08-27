using Uno;
using Uno.UX;

using Fuse.Controls;
using Fuse.Reactive;

namespace Fuse.Charting
{
	/**
		Common base for plot positioned elements.
	*/
	abstract public class PlotElement : Panel, IPlotDataItemListener<PlotDataPoint>
	{
		internal PlotElement()
		{
			//This should probably be "false", but see this issue:
			//https://github.com/fusetools/fuselibs-private/issues/3866
			SnapToPixels = true;
		}

		PlotDataItemWatcher<PlotDataPoint> _watcher;
		protected override void OnRooted()
		{
			base.OnRooted();
			_watcher = new PlotDataItemWatcher<PlotDataPoint>(this,this);
		}
			
		protected override void OnUnrooted()
		{
			_watcher.Dispose();
			_watcher = null;
			base.OnUnrooted();
		}
		
		void IPlotDataItemListener<PlotDataPoint>.OnNewData(PlotDataPoint entry) { OnDataPointChanged(entry); }
		internal abstract void OnDataPointChanged( PlotDataPoint entry );
	}
}
