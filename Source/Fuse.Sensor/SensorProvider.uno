using Uno;

namespace Fuse.Sensor
{
	interface ISensorTracker
	{
		void StartListening();

		void StopListening();

		void Init(Action<object> OnDataChanged, Action<string> OnDataError);

		bool IsSensing();
	}

	public partial class BaseTracker
	{
		public event Action<object> DataChanged;

		public event Action<string> DataError;

		protected void OnDataChanged(object newData)
		{
			if(DataChanged != null)
				DataChanged(newData);
		}

		protected void OnDataError(string error)
		{
			if(DataError != null)
				DataError(error);
		}
	}

	public partial class AccelerometerTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public AccelerometerTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidAccelerometerProvider();
			else if defined(iOS)
				_sensorTracker = new IOSAccelerometerProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}

	public partial class GyroscopeTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public GyroscopeTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidGyroscopeProvider();
			else if defined(iOS)
				_sensorTracker = new IOSGyroscopeProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}

	public partial class MagnetometerTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public MagnetometerTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidMagnetometerProvider();
			else if defined(iOS)
				_sensorTracker = new IOSMagnetometerProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}

	public partial class UserAccelerationTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public UserAccelerationTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidUserAccelerationProvider();
			else if defined(iOS)
				_sensorTracker = new IOSUserAccelerationProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}

	public partial class GravityTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public GravityTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidGravityProvider();
			else if defined(iOS)
				_sensorTracker = new IOSGravityProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}

	public partial class RotationTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public RotationTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidRotationProvider();
			else if defined(iOS)
				_sensorTracker = new IOSRotationProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}

	public partial class PedometerTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public PedometerTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidPedometerProvider();
			else if defined(iOS)
				_sensorTracker = new IOSPedometerProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}

	public partial class BatteryTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public BatteryTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidBatteryProvider();
			else if defined(iOS)
				_sensorTracker = new IOSBatteryProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}

	public partial class ConnectionTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public ConnectionTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidConnectionStateProvider();
			else if defined(iOS)
				_sensorTracker = new IOSConnectionStateProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}

	public partial class PressureTracker : BaseTracker
	{
		static ISensorTracker _sensorTracker;
		public PressureTracker()
		{
			if(_sensorTracker != null) return;
			if defined(Android)
				_sensorTracker = new AndroidPressureProvider();
			else if defined(iOS)
				_sensorTracker = new IOSPressureProvider();
			else
				_sensorTracker = new SpoofSensorProvider();
			_sensorTracker.Init(OnDataChanged, OnDataError);
		}

		public void StartListening()
		{
			_sensorTracker.StartListening();
		}

		public void StopListening()
		{
			_sensorTracker.StopListening();
		}

		public bool IsSensing()
		{
			return _sensorTracker.IsSensing();
		}
	}
}