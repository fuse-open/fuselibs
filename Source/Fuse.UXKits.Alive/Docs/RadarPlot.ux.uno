namespace Alive
{
	/**
		A radar-style [Plot](api:fuse/charting/plot) for a single data series of *exactly* six data points.
		
			<JavaScript>
				var Observable = require("FuseJS/Observable");
				
				exports.data = Observable(
					{ y: 1, label: "Talks" },
					{ y: 2, label: "Exhibitions" },
					{ y: 7, label: "Music" },
					{ y: 4, label: "Workshops" },
					{ y: 5, label: "Comedy" },
					{ y: 6, label: "Meetups }
				)
			</JavaScript>
		
			<Alive.RadarPlot>
				<Fuse.Charting.DataSeries Data="{data}" />
			</Alive.RadarPlot>
	*/
	public partial class RadarPlot {}
}
