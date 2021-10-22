namespace Alive
{
	/**
		A striped list of items, with optional Adding/Removing/LayoutAnimations.

		ListView takes its items directly as a property.

		>**Note:** `Items` must be an @Observable.
		>**Note:** The **child** of the ListView MUST HAVE the property `ux:Template="Item"`

		```xml
		<JavaScript>
			var Observable = require("FuseJS/Observable");
			var tasks = Observable(
				{ task: "Groceries" },
				{ task: "Finish TPS report" },
				{ task: "Purchase boat" }
			);
			var isAnimated = Observable(true);
			var add = function() {
				tasks.add({ task: `New task ${tasks.length + 1}` });
			};
			var remove = function(ctx) {
				tasks.remove(ctx.data);
			};
			
			module.exports = {
				tasks,
				add,
				remove,
				isAnimated,
			};
		</JavaScript>
		
		<Alive.ListView Items="{tasks}" IsAnimated="False">
			<Panel ux:Template="Item" Height="50" Clicked="{remove}">
				<Alive.Body Value="{task}" Alignment="Center" />
			</Panel>
		</Alive.ListView>
		<Button Text="Add" Clicked="{add}" Alignment="BottomCenter" Margin="30"/>
		```

		![actionButton](../../docs/media/alive/listview.gif)

		ListView applies @AddingAnimation, @RemovingAnimation and @LayoutAnimation to each element by default.
		This behavior can be disabled using the `IsAnimated` property.
		
		```xml
			<Alive.ListView IsAnimated="false" Items="{tasks}">
		```

		![actionButton](../../docs/media/alive/listviewnoanima.gif)
	*/
	public partial class ListView {}
}
