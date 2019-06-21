using Uno;
using Uno.UX;
using Fuse.Scripting;

namespace Fuse.Sensor
{

	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/Sensor

		This module provides easy access to sensors on the device. There are 8 types of sensors supported by this module, namely:
		* Accelerometer Sensor
		* Gyroscope sensor
		* Magnetometer sensor
		* Gravity Sensor
		* User Acceleration Sensor
		* Rotation sensor
		* Step Counter Sensor
		* Pressure sensor

		Besides being able to read sensor data, this module can also monitor changes in state of the battery and network connectivity

		Use [startListening](api:fuse/sensor/sensormodule/startlistening_bbef95e2.json) to get continual sensor data updates.
		 And use [stopListening](api:fuse/sensor/sensormodule/stoplistening_bbef95e2.json) to stop getting continual sensor data updates.

		You need to add a reference to `"Fuse.Sensor"` in your project file to use this feature.

		This module is an @EventEmitter, so the methods from @EventEmitter can be used to listen to events.

		> Please note that this module will not work on Desktop Preview. When running on the device, not all devices have a complete sensor hardware,
		>  so not all sensor output data can be obtained, it all depends on the availability of sensors on the device.
		>  Make sure to check "error" event for possible error that encounter.

		## Example

		The following example shows how to access accelerometer sensor:

			<JavaScript>
				var Observable = require("FuseJS/Observable");
				var Sensor = require("FuseJS/Sensor");
				var accelerometerData = Observable("")
				var errorMessage = Observable("")

				Sensor.on("error", function(failMessage) {
					errorMessage.value = failMessage;
				});

				Sensor.on("changed", function(data) {
					if (data.type == Sensor.ACCELEROMETER) {
						accelerometerData.value = "X axis : " + data.x + " Y axis : " + data.y + " Z axis : " + data.z;
					}
				});

				function startAccelerometerContinuousListener() {
					Sensor.startListening(Sensor.ACCELEROMETER);
				}

				function stopAccelerometerContinuousListener() {
					Sensor.stopListening(Sensor.ACCELEROMETER);
				}

				module.exports = {
					startAccelerometerContinuousListener,
					stopAccelerometerContinuousListener,
					accelerometerData,
					errorMessage
				};
			</JavaScript>

			<StackPanel ItemSpacing="5" Margin="0,30,0,0">
				<Text>Accelerometer data :</Text>
				<Text Value="{accelerometerData}" />
				<Text Value="{errorMessage}" Color="Red" />

				<Button Text="Start continuous Accelerometer listener" Clicked="{startAccelerometerContinuousListener}" />
				<Button Text="Stop continuous Accelerometer listener" Clicked="{stopAccelerometerContinuousListener}" />
			</StackPanel>

		In the above example we're using `"changed"` event. Data returned by this module are JavaScript objects of the following form:

			{
				type: sensor type (in this case is Sensor.ACCELEROMETER),
				x: value of x axis,
				y: value of y axis,
				z: value of z axis,
			}

		## Output

		Data returned on the "changed" event argument are JavaScript objects with always have `type` property.
		 Value of `type` property determine what type sensor data it contains.

		Accelerometer, Gyroscope, Magnetometer, Gravity, User Acceleration and Rotation data all have same form of JavaScript object as desribed in the example below:

			var Sensor = require("FuseJS/Sensor")
			Sensor.on('changed', function(data) {
				switch (data.type) {
					case Sensor.ACCELEROMETER:
						console.log("X axis : " + data.x + " Y axis : " + data.y + " Z axis : " + data.z);
						break;
					case Sensor.GYROSCOPE:
						console.log("X axis : " + data.x + " Y axis : " + data.y + " Z axis : " + data.z);
						break;
					case Sensor.MAGNETOMETER:
						console.log("X axis : " + data.x + " Y axis : " + data.y + " Z axis : " + data.z);
						break;
					case Sensor.GRAVITY:
						console.log("X axis : " + data.x + " Y axis : " + data.y + " Z axis : " + data.z);
						break;
					case Sensor.USER_ACCELERATION:
						console.log("X axis : " + data.x + " Y axis : " + data.y + " Z axis : " + data.z);
						break;
					case Sensor.ROTATION:
						console.log("X axis : " + data.x + " Y axis : " + data.y + " Z axis : " + data.z);
						break;
				}
			});

			function startListeningSensor() {
				Sensor.startListening(Sensor.ACCELEROMETER);
				Sensor.startListening(Sensor.GYROSCOPE);
				Sensor.startListening(Sensor.MAGNETOMETER);
				Sensor.startListening(Sensor.GRAVITY);
				Sensor.startListening(Sensor.USER_ACCELERATION);
				Sensor.startListening(Sensor.ROTATION);
			}

			function stopListeningSensor() {
				Sensor.stopListening(Sensor.ACCELEROMETER);
				Sensor.stopListening(Sensor.GYROSCOPE);
				Sensor.stopListening(Sensor.MAGNETOMETER);
				Sensor.stopListening(Sensor.GRAVITY);
				Sensor.stopListening(Sensor.USER_ACCELERATION);
				Sensor.stopListening(Sensor.ROTATION);
			}

		Step counter and pressure data has slightly different output JavaScript object as described in the example below:

			var Sensor = require("FuseJS/Sensor")
			Sensor.on('changed', function(data) {
				switch (data.type) {
					case Sensor.STEP_COUNTER:
						console.log("Num Steps taken : " + data.x);
						break;
					case Sensor.PRESSURE:
						console.log("Pressure in hPa / mbar : " + data.x);
						console.log("Relative Altitude (iOS only) in meters : " + data.y);
						break;
				}
			});

			function startListeningSensor() {
				Sensor.startListening(Sensor.STEP_COUNTER);
				Sensor.startListening(Sensor.PRESSURE);
			}

			function stopListeningSensor() {
				Sensor.stopListening(Sensor.STEP_COUNTER);
				Sensor.stopListening(Sensor.PRESSURE);
			}

		Lastly, monitoring state changes of battery or network connectivity has output JavaScript object as follow:

			var Sensor = require("FuseJS/Sensor")
			Sensor.on('changed', function(data) {
				switch (data.type) {
					case Sensor.BATTERY:
						console.log("Battery level : " + data.level);
						console.log("Battery state : " + data.state); // possible values : charging, unplug, full, not charging, unknown
						break;
					case Sensor.CONNECTION_STATE:
						console.log("connection state : " + data.state); // boolan value : true connected, false disconnected
						console.log("connection state string : " + data.stateString); // possible values : 'connected' or 'disconnected'
						break;
				}
			});

			function startMonitoringState() {
				Sensor.startListening(Sensor.BATTERY);
				Sensor.startListening(Sensor.CONNECTION_STATE);
			}

			function stopMonitoringState() {
				Sensor.stopListening(Sensor.BATTERY);
				Sensor.stopListening(Sensor.CONNECTION_STATE);
			}

		To handle errors from Sensor we can listen to the `"error"` event, as follows:

			var Sensor = require("FuseJS/Sensor")
			Sensor.on("error", function(err) { ... })

		@scriptproperty (int) ACCELEROMETER track accelerometer sensor.
		@scriptproperty (int) GYROSCOPE track gyroscope sensor.
		@scriptproperty (int) MAGNETOMETER track magnetometer sensor.
		@scriptproperty (int) GRAVITY track gravity sensor.
		@scriptproperty (int) USER_ACCELERATION track user acceleration sensor.
		@scriptproperty (int) ROTATION track rotation sensor.
		@scriptproperty (int) STEP_COUNTER track step counter sensor.
		@scriptproperty (int) PRESSURE track pressure sensor.
		@scriptproperty (int) BATTERY track battery states.
		@scriptproperty (int) CONNECTION_STATE track network connectivity states.

	*/
	public class SensorModule : NativeEventEmitterModule
	{
		static readonly SensorModule _instance;
		static Fuse.Sensor.SensorType _sensorType;
		AccelerometerTracker _acceleromaterTracker;
		GyroscopeTracker _gyroscopeTracker;
		MagnetometerTracker _magnetometerTracker;
		UserAccelerationTracker _userAccelerationTracker;
		GravityTracker _gravityTracker;
		RotationTracker _rotationTracker;
		PedometerTracker _pedometerTracker;
		PressureTracker _pressureTracker;
		BatteryTracker _batteryTracker;
		ConnectionTracker _connectionTracker;

		public SensorModule()
			: base(false,
				"changed", "error")
		{
			if (_instance != null) return;

			_instance = this;
			Resource.SetGlobalKey(_instance, "FuseJS/Sensor");
			_acceleromaterTracker = new AccelerometerTracker();
			_gyroscopeTracker = new GyroscopeTracker();
			_magnetometerTracker = new MagnetometerTracker();
			_userAccelerationTracker = new UserAccelerationTracker();
			_gravityTracker = new GravityTracker();
			_rotationTracker = new RotationTracker();
			_pedometerTracker = new PedometerTracker();
			_pressureTracker = new PressureTracker();
			_batteryTracker = new BatteryTracker();
			_connectionTracker = new ConnectionTracker();

			AddMember(new NativeProperty<int, int>("ACCELEROMETER", SensorType.ACCELEROMETER));
			AddMember(new NativeProperty<int, int>("GYROSCOPE", SensorType.GYROSCOPE));
			AddMember(new NativeProperty<int, int>("MAGNETOMETER", SensorType.MAGNETOMETER));
			AddMember(new NativeProperty<int, int>("GRAVITY", SensorType.GRAVITY));
			AddMember(new NativeProperty<int, int>("USER_ACCELERATION", SensorType.USER_ACCELERATION));
			AddMember(new NativeProperty<int, int>("ROTATION", SensorType.ROTATION));
			AddMember(new NativeProperty<int, int>("STEP_COUNTER", SensorType.STEP_COUNTER));
			AddMember(new NativeProperty<int, int>("PRESSURE", SensorType.PRESSURE));
			AddMember(new NativeProperty<int, int>("BATTERY", SensorType.BATTERY));
			AddMember(new NativeProperty<int, int>("CONNECTION_STATE", SensorType.CONNECTION_STATE));
			AddMember(new NativeFunction("startListening", (NativeCallback)StartListening));
			AddMember(new NativeFunction("isSensing", (NativeCallback)IsSensing));
			AddMember(new NativeFunction("stopListening", (NativeCallback)StopListening));

			_acceleromaterTracker.DataChanged += DataChanged;
			_acceleromaterTracker.DataError += OnError;

			_gyroscopeTracker.DataChanged += DataChanged;
			_gyroscopeTracker.DataError += OnError;

			_magnetometerTracker.DataChanged += DataChanged;
			_magnetometerTracker.DataError += OnError;

			_userAccelerationTracker.DataChanged += DataChanged;
			_userAccelerationTracker.DataError += OnError;

			_gravityTracker.DataChanged += DataChanged;
			_gravityTracker.DataError += OnError;

			_rotationTracker.DataChanged += DataChanged;
			_rotationTracker.DataError += OnError;

			_pedometerTracker.DataChanged += DataChanged;
			_pedometerTracker.DataError += OnError;

			_pressureTracker.DataChanged += DataChanged;
			_pressureTracker.DataError += OnError;

			_batteryTracker.DataChanged += DataChanged;
			_batteryTracker.DataError += OnError;

			_connectionTracker.DataChanged += DataChanged;
			_connectionTracker.DataError += OnError;
		}

		/**
			@scriptmethod startListening(sensorType)

			Starts the Sensor listening service.

			[onChanged](api:fuse/sensor/sensormodule/datachanged_a09c80e3.json)
			events will be generated as the sensor changes.


			Use [stopListening](api:fuse/sensor/sensormodule/stoplistening_bbef95e2.json) to stop the service.

			@param sensorType what type sensor that want to listen. see @SensorType for details

		*/
		object StartListening(Context c, object[] args)
		{
			if (args.Length == 0)
			{
				EmitError("Please Specify SensorType");
				return null;
			}
			var sensorType = Marshal.ToInt(args[0]);
			switch (sensorType)
			{
				case SensorType.ACCELEROMETER:
					if (!_acceleromaterTracker.IsSensing())
						_acceleromaterTracker.StartListening();
					break;
				case SensorType.GYROSCOPE:
					if (!_gyroscopeTracker.IsSensing())
						_gyroscopeTracker.StartListening();
					break;
				case SensorType.MAGNETOMETER:
					if (!_magnetometerTracker.IsSensing())
						_magnetometerTracker.StartListening();
					break;
				case SensorType.GRAVITY:
					if (!_gravityTracker.IsSensing())
						_gravityTracker.StartListening();
					break;
				case SensorType.USER_ACCELERATION:
					if (!_userAccelerationTracker.IsSensing())
						_userAccelerationTracker.StartListening();
					break;
				case SensorType.ROTATION:
					if (!_rotationTracker.IsSensing())
						_rotationTracker.StartListening();
					break;
				case SensorType.STEP_COUNTER:
					if (!_pedometerTracker.IsSensing())
						_pedometerTracker.StartListening();
					break;
				case SensorType.PRESSURE:
					if (!_pressureTracker.IsSensing())
						_pressureTracker.StartListening();
					break;
				case SensorType.BATTERY:
					if (!_batteryTracker.IsSensing())
						_batteryTracker.StartListening();
					break;
				case SensorType.CONNECTION_STATE:
					if (!_connectionTracker.IsSensing())
						_connectionTracker.StartListening();
					break;
				default:
					EmitError("Unknown SensorType");
					break;
			}
			return null;
		}

		/**
			@scriptmethod stopListening(sensorType)

			Stops the Sensor listening service.

			@param sensorType what type sensor that want to stop listen. see @SensorType for details
		*/
		object StopListening(Context c, object[] args)
		{
			if (args.Length == 0)
			{
				EmitError("Please Specify SensorType");
				return null;
			}
			var sensorType = Marshal.ToInt(args[0]);
			switch (sensorType)
			{
				case SensorType.ACCELEROMETER:
					if (_acceleromaterTracker.IsSensing())
						_acceleromaterTracker.StopListening();
					break;
				case SensorType.GYROSCOPE:
					if (_gyroscopeTracker.IsSensing())
						_gyroscopeTracker.StopListening();
					break;
				case SensorType.MAGNETOMETER:
					if (_magnetometerTracker.IsSensing())
						_magnetometerTracker.StopListening();
					break;
				case SensorType.GRAVITY:
					if (_gravityTracker.IsSensing())
						_gravityTracker.StopListening();
					break;
				case SensorType.USER_ACCELERATION:
					if (_userAccelerationTracker.IsSensing())
						_userAccelerationTracker.StopListening();
					break;
				case SensorType.ROTATION:
					if (_rotationTracker.IsSensing())
						_rotationTracker.StopListening();
					break;
				case SensorType.STEP_COUNTER:
					if (_pedometerTracker.IsSensing())
						_pedometerTracker.StopListening();
					break;
				case SensorType.PRESSURE:
					if (_pressureTracker.IsSensing())
						_pressureTracker.StopListening();
					break;
				case SensorType.BATTERY:
					if (_batteryTracker.IsSensing())
						_batteryTracker.StopListening();
					break;
				case SensorType.CONNECTION_STATE:
					if (_connectionTracker.IsSensing())
						_connectionTracker.StopListening();
					break;
				default:
					EmitError("Unknown SensorType");
					break;
			}
			return null;
		}

		/**
			@scriptmethod isSensing(sensorType)

			check whether sensor module is sensing for particular sensor.

			@param sensorType what type sensor that want to check. see @SensorType for details
		*/
		object IsSensing(Context c, object[] args)
		{
			if (args.Length == 0)
			{
				EmitError("Please Specify SensorType");
				return null;
			}
			var sensorType = Marshal.ToInt(args[0]);
			switch (sensorType)
			{
				case SensorType.ACCELEROMETER:
					return _acceleromaterTracker.IsSensing();
				case SensorType.GYROSCOPE:
					return _gyroscopeTracker.IsSensing();
				case SensorType.MAGNETOMETER:
					return _magnetometerTracker.IsSensing();
				case SensorType.GRAVITY:
					return _gravityTracker.IsSensing();
				case SensorType.USER_ACCELERATION:
					return _userAccelerationTracker.IsSensing();
				case SensorType.ROTATION:
					return _rotationTracker.IsSensing();
				case SensorType.STEP_COUNTER:
					return _pedometerTracker.IsSensing();
				case SensorType.PRESSURE:
					return _pressureTracker.IsSensing();
				case SensorType.BATTERY:
					return _batteryTracker.IsSensing();
				case SensorType.CONNECTION_STATE:
					return _connectionTracker.IsSensing();
				default:
					EmitError("Unknown SensorType");
					break;
			}
			return null;
		}

		/**
			@scriptevent changed(location)

			Raised when the sensor changes.

			Use [startListening](api:fuse/sensor/sensormodule/startlistening_bbef95e2.json) to get these events.

			@param data will contain the new data, see @SensorData or @BatteryData or @InternetConnectionData
		*/
		void DataChanged(object data)
		{
			EmitFactory(ChangedArgsFactory, data);
		}

		/**
			@scriptevent error(error)

			Raised when an error occurs.

			@param error a string describing the error
		*/
		void OnError(string error)
		{
			EmitError(error);
		}

		static object[] ChangedArgsFactory(Context context, object obj)
		{
			if (obj is BatteryData)
				return new object[] { "changed", BatteryDataConverter(context, (BatteryData)obj) };
			else if (obj is ConnectionStateData)
				return new object[] { "changed", ConnectionDataConverter(context, (ConnectionStateData)obj) };
			else
				return new object[] { "changed", SensorDataConverter(context, (SensorData)obj) };
		}

		static Scripting.Object SensorDataConverter(Context context, SensorData sensorData)
		{
			var obj = context.NewObject();
			if(sensorData != null)
			{
				obj["type"] = sensorData.Type;
				obj["x"] = sensorData.Data[0];
				obj["y"] = sensorData.Data[1];
				obj["z"] = sensorData.Data[2];
			}
			return obj;
		}

		static Scripting.Object BatteryDataConverter(Context context, BatteryData sensorData)
		{
			var obj = context.NewObject();
			if(sensorData != null)
			{
				obj["type"] = (int)SensorType.BATTERY;
				obj["level"] = sensorData.Level;
				obj["state"] = sensorData.State;
			}
			return obj;
		}

		static Scripting.Object ConnectionDataConverter(Context context, ConnectionStateData sensorData)
		{
			var obj = context.NewObject();
			obj["type"] = (int)SensorType.CONNECTION_STATE;
			obj["state"] = sensorData.ConnectionStatus;
			obj["stateString"] = sensorData.ConnectionStatusString;
			return obj;
		}
	}

	/** Determines the sensor type available for @SensorModule. */
	public enum SensorType {
		/** Measures the acceleration force in m/s2 that is applied to a device on all three physical axes (x, y, and z), including the force of gravity (9.81 m/s2) */
		ACCELEROMETER = 0,
		/** Measures a device's rate of rotation in rad/s around each of the three physical axes (x, y, and z) */
		GYROSCOPE = 1,
		/** Measures the ambient geomagnetic field for all three physical axes (x, y, z) in μT */
		MAGNETOMETER = 2,
		/** Measures the force of gravity in m/s2 that is applied to a device on all three physical axes (x, y, z). */
		GRAVITY = 3,
		/** Measures the acceleration force in m/s2 that is applied to a device on all three physical axes (x, y, and z), excluding the force of gravity. */
		USER_ACCELERATION = 4,
		/** Measures the orientation of a device by providing the three elements of the device's rotation vector. */
		ROTATION = 5,
		/** Number of steps taken by the user since the last reboot while the sensor was activated. */
		STEP_COUNTER = 6,
		/** Measures the ambient air pressure in hPa or mbar. */
		PRESSURE = 7,
		/** Monitor battery level and state */
		BATTERY = 8,
		/** Monitor network connectivity */
		CONNECTION_STATE = 9
	}
}