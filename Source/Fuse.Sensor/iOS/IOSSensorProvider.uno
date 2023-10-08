using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Sensor
{
	[Require("xcode.framework", "CoreMotion")]
	[ForeignInclude(Language.ObjC, "iOS/sensors/FOAccelerometer.h")]
	extern(iOS) class IOSAccelerometerProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FOAccelerometer* accel = [[FOAccelerometer alloc] initWithBlock:^void (CMAccelerometerData* accelerometerData)
			{
				// Normalize acceleration to match with android
				float x = accelerometerData.acceleration.x * -9.81f;
				float y = accelerometerData.acceleration.y * -9.81f;
				float z = accelerometerData.acceleration.z * -9.81f;
				@{IOSAccelerometerProvider:of(_this).OnDataChanged(float,float,float):call(x,y,z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSAccelerometerProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return accel;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FOAccelerometer* accel = (FOAccelerometer*)handle;
			bool started = [accel startSensing];
			if (!started)
				@{IOSAccelerometerProvider:of(_this).OnError(string):call(@"Accelerometer sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOAccelerometer* accel = (FOAccelerometer*)handle;
			bool stopped = [accel stopSensing];
			if (!stopped)
				@{IOSAccelerometerProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FOAccelerometer* accel = (FOAccelerometer*)handle;
			return accel.isSensing;
		@}

		void OnDataChanged(float x, float y, float z)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(SensorType.ACCELEROMETER,x,y,z));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	[Require("xcode.framework", "CoreMotion")]
	[ForeignInclude(Language.ObjC, "iOS/sensors/FOGyroscope.h")]
	extern(iOS) class IOSGyroscopeProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FOGyroscope* gyro = [[FOGyroscope alloc] initWithBlock:^void (CMGyroData* gyroData)
			{
				@{IOSGyroscopeProvider:of(_this).OnDataChanged(float,float,float):call(gyroData.rotationRate.x,gyroData.rotationRate.y,gyroData.rotationRate.z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSGyroscopeProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return gyro;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FOGyroscope* gyro = (FOGyroscope*)handle;
			bool started = [gyro startSensing];
			if (!started)
				@{IOSGyroscopeProvider:of(_this).OnError(string):call(@"Gyroscope sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOGyroscope* gyro = (FOGyroscope*)handle;
			bool stopped = [gyro stopSensing];
			if (!stopped)
				@{IOSGyroscopeProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FOGyroscope* gyro = (FOGyroscope*)handle;
			return gyro.isSensing;
		@}

		void OnDataChanged(float x, float y, float z)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(SensorType.GYROSCOPE,x,y,z));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	[Require("xcode.framework", "CoreMotion")]
	[ForeignInclude(Language.ObjC, "iOS/sensors/FOMagnetometer.h")]
	extern(iOS) class IOSMagnetometerProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FOMagnetometer* magneto = [[FOMagnetometer alloc] initWithBlock:^void (CMMagnetometerData* magnetoData)
			{
				@{IOSMagnetometerProvider:of(_this).OnDataChanged(float,float,float):call(magnetoData.magneticField.x,magnetoData.magneticField.y,magnetoData.magneticField.z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSMagnetometerProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return magneto;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FOMagnetometer* magneto = (FOMagnetometer*)handle;
			bool started = [magneto startSensing];
			if (!started)
				@{IOSMagnetometerProvider:of(_this).OnError(string):call(@"Magnetometer sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOMagnetometer* magneto = (FOMagnetometer*)handle;
			bool stopped = [magneto stopSensing];
			if (!stopped)
				@{IOSMagnetometerProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FOMagnetometer* magneto = (FOMagnetometer*)handle;
			return magneto.isSensing;
		@}

		void OnDataChanged(float x, float y, float z)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(SensorType.MAGNETOMETER,x,y,z));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	[Require("xcode.framework", "CoreMotion")]
	[ForeignInclude(Language.ObjC, "iOS/sensors/FODeviceMotion.h")]
	extern(iOS) class IOSGravityProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FODeviceMotion* motion = [[FODeviceMotion alloc] initWithBlock:^void (CMDeviceMotion* deviceMotionData)
			{
				@{IOSGravityProvider:of(_this).OnDataChanged(float,float,float):call(deviceMotionData.gravity.x,deviceMotionData.gravity.y,deviceMotionData.gravity.z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSGravityProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return motion;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			bool started = [motion startSensing];
			if (!started)
				@{IOSGravityProvider:of(_this).OnError(string):call(@"Gravity sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			bool stopped = [motion stopSensing];
			if (!stopped)
				@{IOSGravityProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			return motion.isSensing;
		@}

		void OnDataChanged(float x, float y, float z)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(SensorType.GRAVITY,x,y,z));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	[Require("xcode.framework", "CoreMotion")]
	[ForeignInclude(Language.ObjC, "iOS/sensors/FODeviceMotion.h")]
	extern(iOS) class IOSUserAccelerationProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FODeviceMotion* motion = [[FODeviceMotion alloc] initWithBlock:^void (CMDeviceMotion* deviceMotionData)
			{
				// Normalize acceleration to match with android
				float x = deviceMotionData.userAcceleration.x * -1.0f;
				float y = deviceMotionData.userAcceleration.y * -1.0f;
				float z = deviceMotionData.userAcceleration.z * -1.0f;
				@{IOSUserAccelerationProvider:of(_this).OnDataChanged(float,float,float):call(x,y,z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSUserAccelerationProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return motion;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			bool started = [motion startSensing];
			if (!started)
				@{IOSUserAccelerationProvider:of(_this).OnError(string):call(@"User Accelerometer sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			bool stopped = [motion stopSensing];
			if (!stopped)
				@{IOSUserAccelerationProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			return motion.isSensing;
		@}

		void OnDataChanged(float x, float y, float z)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(SensorType.USER_ACCELERATION,x,y,z));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	[Require("xcode.framework", "CoreMotion")]
	[ForeignInclude(Language.ObjC, "iOS/sensors/FODeviceMotion.h")]
	extern(iOS) class IOSRotationProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FODeviceMotion* motion = [[FODeviceMotion alloc] initWithBlock:^void (CMDeviceMotion* deviceMotionData)
			{
				@{IOSRotationProvider:of(_this).OnDataChanged(float,float,float):call(deviceMotionData.rotationRate.x,deviceMotionData.rotationRate.y,deviceMotionData.rotationRate.z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSRotationProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return motion;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			bool started = [motion startSensing];
			if (!started)
				@{IOSRotationProvider:of(_this).OnError(string):call(@"Rotation sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			bool stopped = [motion stopSensing];
			if (!stopped)
				@{IOSRotationProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			return motion.isSensing;
		@}

		void OnDataChanged(float x, float y, float z)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(SensorType.ROTATION,x,y,z));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	[Require("xcode.framework", "CoreMotion")]
	[ForeignInclude(Language.ObjC, "iOS/sensors/FOPedometer.h")]
	extern(iOS) class IOSPedometerProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FOPedometer* pedometer = [[FOPedometer alloc] initWithBlock:^void (CMPedometerData* pedometerData)
			{
				@{IOSPedometerProvider:of(_this).OnDataChanged(float,float,float):call([pedometerData.numberOfSteps floatValue],0.0f,0.0f)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSPedometerProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return pedometer;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FOPedometer* pedometer = (FOPedometer*)handle;
			bool started = [pedometer startSensing];
			if (!started)
				@{IOSPedometerProvider:of(_this).OnError(string):call(@"Step counter sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOPedometer* pedometer = (FOPedometer*)handle;
			bool stopped = [pedometer stopSensing];
			if (!stopped)
				@{IOSPedometerProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FOPedometer* pedometer = (FOPedometer*)handle;
			return pedometer.isSensing;
		@}

		void OnDataChanged(float x, float y, float z)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(SensorType.STEP_COUNTER,x,y,z));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	[Require("xcode.framework", "SystemConfiguration")]
	[ForeignInclude(Language.ObjC, "iOS/sensors/FOPressure.h")]
	extern(iOS) class IOSPressureProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FOPressure* pressure = [[FOPressure alloc] initWithBlock:^void (CMAltitudeData* altitudeData)
			{
				// default ios pressure data in kPa, we normalize pressure data to match android value in hPa / mbar
				float pressure = [altitudeData.pressure floatValue]*10;
				@{IOSPressureProvider:of(_this).OnDataChanged(float,float,float):call(pressure,[altitudeData.relativeAltitude floatValue],0.0f)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSPressureProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return pressure;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FOPressure* pressure = (FOPressure*)handle;
			bool started = [pressure startSensing];
			if (!started)
				@{IOSPressureProvider:of(_this).OnError(string):call(@"Pressure sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOPressure* pressure = (FOPressure*)handle;
			bool stopped = [pressure stopSensing];
			if (!stopped)
				@{IOSPressureProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FOPressure* pressure = (FOPressure*)handle;
			return pressure.isSensing;
		@}

		void OnDataChanged(float x, float y, float z)
		{
			_OnDataChanged(SensorDataHelpers.ConvertSensorData(SensorType.PRESSURE,x,y,z));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	[ForeignInclude(Language.ObjC, "iOS/sensors/FOBattery.h", "iOS/data/FOBatteryData.h")]
	extern(iOS) class IOSBatteryProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FOBattery* battery = [[FOBattery alloc] initWithBlock:^void (FOBatteryData* batteryData)
			{
				@{IOSBatteryProvider:of(_this).OnDataChanged(ObjC.Object):call(batteryData)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSBatteryProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return battery;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FOBattery* battery = (FOBattery*)handle;
			bool started = [battery startSensing];
			if (!started)
				@{IOSBatteryProvider:of(_this).OnError(string):call(@"Battery monitoring could not be started.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOBattery* battery = (FOBattery*)handle;
			bool stopped = [battery stopSensing];
			if (!stopped)
				@{IOSBatteryProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FOBattery* battery = (FOBattery*)handle;
			return battery.isSensing;
		@}

		void OnDataChanged(ObjC.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertBatteryData(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}

	[Require("xcode.framework", "SystemConfiguration")]
	[ForeignInclude(Language.ObjC, "iOS/sensors/FOConnection.h", "iOS/data/FOConnectionStateData.h")]
	extern(iOS) class IOSConnectionStateProvider : ISensorTracker
	{
		ObjC.Object _sensor;
		Action<object> _OnDataChanged;
		Action<string> _OnDataError;

		public void Init(Action<object> OnDataChanged, Action<string> OnDataError)
		{
			_OnDataChanged = OnDataChanged;
			_OnDataError = OnDataError;
			_sensor = InitSensor();
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

		[Foreign(Language.ObjC)]
		extern(iOS) ObjC.Object InitSensor()
		@{
			FOConnection* connection = [[FOConnection alloc] initWithBlock:^void (FOConnectionStateData * status)
			{
				@{IOSConnectionStateProvider:of(_this).OnDataChanged(ObjC.Object):call(status)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSConnectionStateProvider:of(_this).OnError(string):call(err.localizedDescription)};
			}
			];
			return connection;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StartSensor(ObjC.Object handle)
		@{
			FOConnection* conn = (FOConnection*)handle;
			bool started = [conn startSensing];
			if (!started)
				@{IOSConnectionStateProvider:of(_this).OnError(string):call(@"Connection State monitoring could not be started.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOConnection* conn = (FOConnection*)handle;
			bool stopped = [conn stopSensing];
			if (!stopped)
				@{IOSConnectionStateProvider:of(_this).OnError(string):call(@"Stopping Failed")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) bool IsSensing(ObjC.Object handle)
		@{
			FOConnection* conn = (FOConnection*)handle;
			return conn.isSensing;
		@}

		void OnDataChanged(ObjC.Object newData)
		{
			_OnDataChanged(SensorDataHelpers.ConvertConnectionState(newData));
		}

		void OnError(string error)
		{
			_OnDataError(error);
		}
	}
}