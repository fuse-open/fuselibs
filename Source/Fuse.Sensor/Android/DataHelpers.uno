using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Sensor
{
	[ForeignInclude(Language.Java, "com.fuse.sensorkit.SensorData", "com.fuse.sensorkit.BatteryData", "com.fuse.sensorkit.ConnectionStateData")]
	public extern(Android) class SensorDataHelpers
	{
		[Foreign(Language.Java)]
		public static float[] GetData(this Java.Object handle)
		@{
			return new FloatArray(((SensorData)handle).getData());
		@}

		[Foreign(Language.Java)]
		public static int GetSensorType(this Java.Object handle)
		@{
			return ((SensorData)handle).getSensorType().ordinal();
		@}

		[Foreign(Language.Java)]
		public static float GetBatteryLevel(this Java.Object handle)
		@{
			return ((BatteryData)handle).getLevel();
		@}

		[Foreign(Language.Java)]
		public static string GetBatteryState(this Java.Object handle)
		@{
			return ((BatteryData)handle).getBatteryStatusString();
		@}

		[Foreign(Language.Java)]
		public static bool GetConnectionStatus(this Java.Object handle)
		@{
			return ((ConnectionStateData)handle).getStatus();
		@}

		[Foreign(Language.Java)]
		public static string GetConnectionStatusString(this Java.Object handle)
		@{
			return ((ConnectionStateData)handle).getStatusString();
		@}

		public static SensorData ConvertSensorData(Java.Object obj)
		{
			float[] data = SensorDataHelpers.GetData(obj);
			return new SensorData(SensorDataHelpers.GetSensorType(obj), float3(data[0], data[1], data[2]));
		}

		public static BatteryData ConvertBatteryData(Java.Object obj)
		{
			return new BatteryData(SensorDataHelpers.GetBatteryLevel(obj), SensorDataHelpers.GetBatteryState(obj));
		}

		public static object ConvertConnectionStateData(Java.Object obj)
		{
			return new ConnectionStateData(SensorDataHelpers.GetConnectionStatus(obj), SensorDataHelpers.GetConnectionStatusString(obj));
		}
	}
}