using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Sensor
{
	extern(Android) class AndroidAccelerometerProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.AccelerometerSensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.AccelerometerSensor)handle).start();
			} catch (Exception e) {
				@{AndroidAccelerometerProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.AccelerometerSensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.AccelerometerSensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	extern(Android) class AndroidGyroscopeProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.GyroscopeSensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.GyroscopeSensor)handle).start();
			} catch (Exception e) {
				@{AndroidGyroscopeProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.GyroscopeSensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.GyroscopeSensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	extern(Android) class AndroidMagnetometerProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.MagnetometerSensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.MagnetometerSensor)handle).start();
			} catch (Exception e) {
				@{AndroidMagnetometerProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.MagnetometerSensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.MagnetometerSensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	extern(Android) class AndroidUserAccelerationProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.UserAccelerationSensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.UserAccelerationSensor)handle).start();
			} catch (Exception e) {
				@{AndroidUserAccelerationProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.UserAccelerationSensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.UserAccelerationSensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	extern(Android) class AndroidGravityProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.GravitySensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.GravitySensor)handle).start();
			} catch (Exception e) {
				@{AndroidGravityProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.GravitySensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.GravitySensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	extern(Android) class AndroidRotationProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.RotationSensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.RotationSensor)handle).start();
			} catch (Exception e) {
				@{AndroidRotationProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.RotationSensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.RotationSensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	extern(Android) class AndroidPedometerProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.PedometerSensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.PedometerSensor)handle).start();
			} catch (Exception e) {
				@{AndroidPedometerProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.PedometerSensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.PedometerSensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	extern(Android) class AndroidPressureProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.PressureSensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.PressureSensor)handle).start();
			} catch (Exception e) {
				@{AndroidPressureProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.PressureSensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.PressureSensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	extern(Android) class AndroidBatteryProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.BatterySensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.BatterySensor)handle).start();
			} catch (Exception e) {
				@{AndroidBatteryProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.BatterySensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.BatterySensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertBatteryData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	extern(Android) class AndroidConnectionStateProvider : ISensorTracker
	{
		Java.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> onDataChanged, Action<string> onDataError)
		{
			_OnDataChanged = onDataChanged;
			_OnDataError = onDataError;
			_sensor = InitSensor(OnDataChanged);
		}

		public void StartListening()
		{
			StartSensor(_sensor);
		}

		public void StopListening()
		{
			StopSensor(_sensor);
		}

		public bool IsSensing()
		{
			return IsSensing(_sensor);
		}

		[Foreign(Language.Java)]
		extern(Android) Java.Object InitSensor(Action<Java.Object> onDataChanged)
		@{
			return new com.fuse.sensorkit.ConnectionStateSensor(onDataChanged);
		@}

		[Foreign(Language.Java)]
		extern(Android) void StartSensor(Java.Object handle)
		@{
			try {
				((com.fuse.sensorkit.ConnectionStateSensor)handle).start();
			} catch (Exception e) {
				@{AndroidConnectionStateProvider:Of(_this).OnError(string):Call(e.getMessage())};
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) void StopSensor(Java.Object handle)
		@{
			((com.fuse.sensorkit.ConnectionStateSensor)handle).stop();
		@}

		[Foreign(Language.Java)]
		extern(Android) bool IsSensing(Java.Object handle)
		@{
			return ((com.fuse.sensorkit.ConnectionStateSensor)handle).isSensing();
		@}

		void OnDataChanged(Java.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertConnectionStateData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

}