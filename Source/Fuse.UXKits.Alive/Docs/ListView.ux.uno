namespace Alive
{
	/**
		A striped list of items, with optional Adding/Removing/LayoutAnimations.
		
		ListView takes its items directly as a property.
		
		**Note:** `Items` must be an @Observable.
		
			<JavaScript>
				var Observable = require("FuseJS/Observable");
				
				exports.tasks = Observable(
					{ task: "Groceries" },
					{ task: "Finish TPS report" },
					{ task: "Purchase boat" }
				);
			</JavaScript>
			
			<Alive.ListView Items="{tasks}">
				<Panel Height="80">
					<Alive.Body Value="{task}" Alignment="Center" />
				</Panel>
			</Alive.ListView>
		
		
		ListView applies @AddingAnimation, @RemovingAnimation and @LayoutAnimation to each element by default.
		This behavior can be disabled using the `IsAnimated` property.
		
			<Alive.ListView IsAnimated="false" Items="{data}">
		
	*/
	public partial class ListView {}
}
