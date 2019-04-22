using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Sensor
{
	[ForeignInclude(Language.ObjC, "iOS/data/FOBatteryData.h", "iOS/data/FOConnectionStateData.h")]
	public extern(iOS) class SensorDataHelpers
	{
		[Foreign(Language.ObjC)]
		public static float GetBatteryLevel(this ObjC.Object handle)
		@{
			return [handle getLevel];
		@}

		[Foreign(Language.ObjC)]
		public static string GetBatteryState(this ObjC.Object handle)
		@{
			return [handle stateString];
		@}

		[Foreign(Language.ObjC)]
		public static bool GetConnectionState(this ObjC.Object handle)
		@{
			return [handle getStatus];
		@}

		[Foreign(Language.ObjC)]
		public static string GetConnectionStateString(this ObjC.Object handle)
		@{
			return [handle getStatusString];
		@}

		public static SensorData ConvertSensorData(int sensorType, float x, float y, float z)
		{
			return new SensorData(sensorType,float3(x,y,z));
		}

		public static BatteryData ConvertBatteryData(ObjC.Object data)
		{
			return new BatteryData(SensorDataHelpers.GetBatteryLevel(data), SensorDataHelpers.GetBatteryState(data));
		}

		public static object ConvertConnectionState(ObjC.Object data)
		{
			return new ConnectionStateData(SensorDataHelpers.GetConnectionState(data), SensorDataHelpers.GetConnectionStateString(data));
		}
	}
}