using Uno;
using Uno.Threading;

namespace Fuse.Controls.FuseTextRenderer
{
	class AsyncMeasurer
	{
		CacheState _state;
		TextControlData _data;
		Action<CacheState> _done;

		public AsyncMeasurer(CacheState state, TextControlData data, Action<CacheState> done)
		{
			_state = state;
			_data = data;
			_done = done;
		}

		public void Run()
		{
			float2 measurements;
			_state = _state.GetMeasurements(_data, out measurements);
			UpdateManager.Dispatcher.Invoke1(_done, _state);
		}
	}
}
