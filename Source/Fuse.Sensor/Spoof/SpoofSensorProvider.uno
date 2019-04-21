using Uno;

namespace Fuse.Sensor
{
	public class SpoofSensorProvider : ISensorTracker
	{
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
		}

		public void StartListening()
		{
			_OnDataError("Sensor not available in desktop preview");
		}

		public void StopListening()
		{
			_OnDataError("Sensor not available in desktop preview");
		}

		public bool IsSensing()
		{
			return false;
		}
	}
}