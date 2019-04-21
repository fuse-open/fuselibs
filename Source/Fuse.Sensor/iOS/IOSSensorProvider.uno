using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Sensor
{
	[Require("Xcode.Framework", "CoreMotion")]
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
				@{IOSAccelerometerProvider:Of(_this).OnDataChanged(float,float,float):Call(x,y,z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSAccelerometerProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSAccelerometerProvider:Of(_this).OnError(string):Call(@"Accelerometer sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOAccelerometer* accel = (FOAccelerometer*)handle;
			bool stopped = [accel stopSensing];
			if (!stopped)
				@{IOSAccelerometerProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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

	[Require("Xcode.Framework", "CoreMotion")]
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
				@{IOSGyroscopeProvider:Of(_this).OnDataChanged(float,float,float):Call(gyroData.rotationRate.x,gyroData.rotationRate.y,gyroData.rotationRate.z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSGyroscopeProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSGyroscopeProvider:Of(_this).OnError(string):Call(@"Gyroscope sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOGyroscope* gyro = (FOGyroscope*)handle;
			bool stopped = [gyro stopSensing];
			if (!stopped)
				@{IOSGyroscopeProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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

	[Require("Xcode.Framework", "CoreMotion")]
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
				@{IOSMagnetometerProvider:Of(_this).OnDataChanged(float,float,float):Call(magnetoData.magneticField.x,magnetoData.magneticField.y,magnetoData.magneticField.z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSMagnetometerProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSMagnetometerProvider:Of(_this).OnError(string):Call(@"Magnetometer sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOMagnetometer* magneto = (FOMagnetometer*)handle;
			bool stopped = [magneto stopSensing];
			if (!stopped)
				@{IOSMagnetometerProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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

	[Require("Xcode.Framework", "CoreMotion")]
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
				@{IOSGravityProvider:Of(_this).OnDataChanged(float,float,float):Call(deviceMotionData.gravity.x,deviceMotionData.gravity.y,deviceMotionData.gravity.z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSGravityProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSGravityProvider:Of(_this).OnError(string):Call(@"Gravity sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			bool stopped = [motion stopSensing];
			if (!stopped)
				@{IOSGravityProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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

	[Require("Xcode.Framework", "CoreMotion")]
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
				@{IOSUserAccelerationProvider:Of(_this).OnDataChanged(float,float,float):Call(x,y,z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSUserAccelerationProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSUserAccelerationProvider:Of(_this).OnError(string):Call(@"User Accelerometer sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			bool stopped = [motion stopSensing];
			if (!stopped)
				@{IOSUserAccelerationProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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

	[Require("Xcode.Framework", "CoreMotion")]
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
				@{IOSRotationProvider:Of(_this).OnDataChanged(float,float,float):Call(deviceMotionData.rotationRate.x,deviceMotionData.rotationRate.y,deviceMotionData.rotationRate.z)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSRotationProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSRotationProvider:Of(_this).OnError(string):Call(@"Rotation sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FODeviceMotion* motion = (FODeviceMotion*)handle;
			bool stopped = [motion stopSensing];
			if (!stopped)
				@{IOSRotationProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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

	[Require("Xcode.Framework", "CoreMotion")]
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
				@{IOSPedometerProvider:Of(_this).OnDataChanged(float,float,float):Call([pedometerData.numberOfSteps floatValue],0.0f,0.0f)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSPedometerProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSPedometerProvider:Of(_this).OnError(string):Call(@"Step counter sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOPedometer* pedometer = (FOPedometer*)handle;
			bool stopped = [pedometer stopSensing];
			if (!stopped)
				@{IOSPedometerProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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

	[Require("Xcode.Framework", "SystemConfiguration")]
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
				@{IOSPressureProvider:Of(_this).OnDataChanged(float,float,float):Call(pressure,[altitudeData.relativeAltitude floatValue],0.0f)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSPressureProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSPressureProvider:Of(_this).OnError(string):Call(@"Pressure sensor is not available.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOPressure* pressure = (FOPressure*)handle;
			bool stopped = [pressure stopSensing];
			if (!stopped)
				@{IOSPressureProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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
				@{IOSBatteryProvider:Of(_this).OnDataChanged(ObjC.Object):Call(batteryData)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSBatteryProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSBatteryProvider:Of(_this).OnError(string):Call(@"Battery monitoring could not be started.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOBattery* battery = (FOBattery*)handle;
			bool stopped = [battery stopSensing];
			if (!stopped)
				@{IOSBatteryProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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

	[Require("Xcode.Framework", "SystemConfiguration")]
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
				@{IOSConnectionStateProvider:Of(_this).OnDataChanged(ObjC.Object):Call(status)};
			}
			error:^void (NSError* err)
			{
				if (err != nil)
					@{IOSConnectionStateProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
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
				@{IOSConnectionStateProvider:Of(_this).OnError(string):Call(@"Connection State monitoring could not be started.")};
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) void StopSensor(ObjC.Object handle)
		@{
			FOConnection* conn = (FOConnection*)handle;
			bool stopped = [conn stopSensing];
			if (!stopped)
				@{IOSConnectionStateProvider:Of(_this).OnError(string):Call(@"Stopping Failed")};
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