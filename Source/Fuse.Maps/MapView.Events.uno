using Uno;
using Fuse.Scripting;
namespace Fuse.Controls
{
	public delegate void MapEventHandler(object sender, MapEventArgs args);
	public delegate void MarkerEventHandler(object sender, MarkerEventArgs args);
	public delegate void MapPositionEventHandler(double latitude, double longitude);

	public sealed class MarkerEventArgs : EventArgs, Fuse.Scripting.IScriptEvent
	{
		public readonly string Label;

		public MarkerEventArgs(string label)
		{
			Label = label;
		}

		void Fuse.Scripting.IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddString("label", Label);
		}
	}

	public sealed class MapEventArgs : EventArgs, Fuse.Scripting.IScriptEvent
	{
		public readonly double Latitude;
		public readonly double Longitude;

		public MapEventArgs(double latitude, double longitude) : base()
		{
			Latitude = latitude;
			Longitude = longitude;
		}

		void Fuse.Scripting.IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddDouble("latitude", Latitude);
			s.AddDouble("longitude", Longitude);
		}
	}

}
