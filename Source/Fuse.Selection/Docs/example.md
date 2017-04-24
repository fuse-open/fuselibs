The following example uses @Selection to create a simple list of options. Tap the items to toggle their selection. `Values` is bound to a JavaScript `Observable` in order to track the currently selected items.

	<Panel ux:Class="MyItem" Color="#aaa">
		<string ux:Property="Label"/>
		<string ux:Property="Value"/>
		
		<Selectable Value="{ReadProperty this.Value}"/>
		<Text Value="{ReadProperty this.Label}"/>
		
		<WhileSelected>
			<Change this.Color="#ffc"/>
		</WhileSelected>
		<Tapped>
			<ToggleSelection/>
		</Tapped>
	</Panel>

	<JavaScript>
		var Observable = require("FuseJS/Observable")
		exports.values = Observable()
		
		exports.list = Observable("")
		exports.values.onValueChanged( module, function() {
			exports.list.value = exports.values.toArray().join(",")
		})
	</JavaScript>
	<StackPanel>
		<Selection Values="{values}"/>
	
		<MyItem Label="Big Red One" Value="sku-01"/>
		<MyItem Label="Small Green Two" Value="sku-02"/>
		<MyItem Label="Third Last One" Value="sku-03"/>
		<MyItem Label="Four Fore For" Value="sku-04"/>
		<MyItem Label="Point Oh-Five" Value="sku-05"/>

		<Text Value="Selected:" Margin="0,10,0,0"/>
		<Text Value="{list}"/>
	</StackPanel>
