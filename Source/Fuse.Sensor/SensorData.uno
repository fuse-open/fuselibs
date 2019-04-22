namespace Fuse.Sensor
{

	public class SensorData
	{
		int _type;
		float3 _data;

		public int Type { get { return _type; } }

		public float3 Data { get { return _data; } }

		public SensorData(int type, float3 data)
		{
			_type = type;
			_data = data;
		}
	}

	public class BatteryData
	{
		float _level;
		string _state;

		public float Level { get { return _level; } }

		public string State { get { return _state; } }

		public BatteryData(float level, string state)
		{
			_level = level;
			_state = state;
		}
	}

	public class ConnectionStateData
	{
		bool _connectionStatus;
		string _connectionStatusString;

		public bool ConnectionStatus { get { return _connectionStatus; } }

		public string ConnectionStatusString { get { return _connectionStatusString; } }

		public ConnectionStateData(bool connectionStatus, string connectionStatusString)
		{
			_connectionStatus = connectionStatus;
			_connectionStatusString = connectionStatusString;
		}
	}

}