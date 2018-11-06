# DataBinding

Fuse provides first class support for creating data driven apps with UX tags through direct binding, iteration and branching. UX can also do referencing deep inside complex data structures, so you do not have to do tedious data massaging in code.

## DataContext

At any point in a Fuse `Node` tree, there is a *data context*. A data binding on any node will be relative to the current data context on the node. By default, this data context is `null`, and any data binding will just return null or empty values. The context will also propagate down the tree, meaning that if a child node doesn't provide a data context, it will use the data context of its parent.

To set the data context, you typically add a *behavior* to a node that provides the data context, such as `<JavaScript>`.

## JavaScript module as data source

The simplest way to create a data source is through JavaScript, here is a databound "Hello world" minimal example:

	<App>
		<JavaScript>
			module.exports = {
				greeting: "Hello databound world!"
			};
		</JavaScript>
		<Text Value="{greeting}" />
	</App>

Similarly, you can bind to collections:

	<App>
		<JavaScript>
			var data = ["1", "2", "3"];

			module.exports = {
				data: data
			};
		</JavaScript>
		<StackPanel>
			<Each Items="{data}">
				<Text Value="{= data () }" />
			</Each>
		</StackPanel>
	</App>

This will predictably list out the text strings 1, 2 and 3. When binding the `Text Value` `{= data()}` means _the prime data context_, in this case the enumerated item from `Each`. Typically, you will bind to more complex data sources, so each element will have something interesting to bind to:

	<App>
		<JavaScript>
			var Observable = require("FuseJS/Observable");

			var data = Observable(
				{name: "Hubert Cumberdale", age: 12},
				{name: "Marjory Stewart-Baxter", age: 43},
				{name: "Jeremy Fisher", age: 25});

			module.exports = {
				data: data
			};
		</JavaScript>
		<StackPanel>
			<Each Items="{data}">
				<DockPanel>
					<Text Dock="Right" Value="{age}" />
					<Text Value="{name}" />
				</DockPanel>
			</Each>
		</StackPanel>
	</App>

In this case, we have also made the data source Observable. This means that it supports propagating changes to the data source at runtime. In this case, the collection itself is `Observable`, but the items are not. You can bind to the children, but if they were to change, these changes would not be reflected in the UI. If you wanted to make the children also propagate their changes to the UI, you would make them `Observable` also:

	<JavaScript>
		var Observable = require("FuseJS/Observable");
		var data = Observable(
			{ name: Observable("Hubert") },
			{ name: Observable("Marjory") });
		module.exports = {
			data: data
		};
	</JavaScript>
	<StackPanel>
		<Each Items="{data}">
			<Text Value="{name}" />
		</Each>
	</StackPanel>

You can also bind to a path:

	<JavaScript>
		var complex = {
			user: {
				userinfo: {
					name: "Bob"
				}
			}
		};
		module.exports = {
			complex: complex
		};
	</JavaScript>
	<Text Value="{complex.user.userinfo.name}" />

This is very useful when binding to arbitrary data sources such as those returned from a REST service as JSON, as it often allows you to bind directly to complex data without processing the data in code first. [See this in-depth example](https://fuseopen.com/examples/news-feed/).

## Binding directions

### Two-way binding (default)

By default, data bindings are *two-way* when possible. This means if the property that emits changed events changes by some other means 
than the data binding, such as user input or animation, the binding object will write the new value back to the source if it is an `Observable`.

	<TextInput Value="{text}" />

In the above example, if the user manipulates the text input, and `text` is a bound observable, the observable will be updated.

### Read-only bindings (one-way)

To create a strictly *one way* binding that *reads* from the data source and upates the property, use the `Read` binding alias:

	<TextInput Value="{Read text}" />

In the above example, a bound observable `text` will not be updated if the user manipulates the text input.

### Write-only bindings (one-way)

To create a strictly *one way* binding that *writes* to the data source when the property is changed by external actors, use the `Write` binding alias:

	<TextInput Value="{Write text}" />

In the above example, the `Value` will not respect the value of `text` coming from JavaScript, but it will update `text` observable when the user manipulates the text box.

## Event binding to JavaScript functions

You can hook up event handlers to call JavaScript functions with similar syntax:

	<JavaScript>
		module.exports = {
			clickHandler: function (args) {
				console.log("I was clicked: " + JSON.stringify(args));
			}
		};
	</JavaScript>
	<Button Clicked="{clickHandler}" Text="Click me!" />

## Clear-bindings

Sometimes it is desireable for the data binding to clear the target property value when the binding is unrooted, for example when the containing page is removed or navigated away from, and later added back or navigated back to with a different data context. In some scenarios, the page will then show some undesired, outdated data while the new data is being loaded.

To avoid that, so called clear-bindings can be used:

	<Text Value="{Clear foo}" />

This will cause the `Value` of the `Text` to be reset to `null` (empty string) when the containing page is unrooted, so that the old text does not linger if the page is reused later.

There are also variants of clear binidngs for read-only and write-only bindings:

	<Text Value="{ReadClear foo}" />
	<Text Value="{WriteClear foo}" />

> Note: Clear-bindings always push `default(T)` (e.g. `null`, `false`, `0` or `0.0`) when unrooted, which is not neccessarily the default value of the property.

## Each

`Each` is used to repeat pieces of UX markup for each item in a collection.

The `Each` behavior maintains one copy of its subtree per item in its Items collection, and adds and removes these from the parent node accordingly. The `Items` collection can be an Observable that can be changed dynamically.

When using `Each`, we typically data-bind the `Items` property to an array data source to produce one visual
node per object in the data source.

	<Each Items="{items}">
		<Rectangle Width="{width}" Height="{height}" Fill="#808" />
	</Each>

Observable add/remove operations on the `Items` collection can be animated using AddingAnimation, RemovingAnimation and LayoutAnimation

It is also possible to nest `Each` behaviors:

	<JavaScript>
		var Observable = require("FuseJS/Observable");
		module.exports = {
			items: [
				{
					inner: [
						{ child: "John" },
						{ child: "Paul" }
					]
				},
				{
					inner: [
						{ child: "Ringo" },
						{ child: "George" }
					]
				}
			]
		};
	</JavaScript>
	<ScrollView>
		<StackPanel>
			<Each Items="{items}">
				<StackPanel Orientation="Horizontal">
					<Each Items="{inner}">
						<Text Value="{child}" Margin="10" />
					</Each>
				</StackPanel>
			</Each>
		</StackPanel>
	</ScrollView>

You can get the number of items being iterated over using the `Count` property.

You can also just use `Each` as a simple repeater:

	<Grid ColumnCount="3">
		<Each Count="9">
			<Rectangle Margin="10" Fill="#610" />
		</Each>
	</Grid>

## WhileCount and WhileEmpty

The `WhileEmpty` and `WhileCount` Triggertriggers) can be used to act on the number of items in a collection:

	<Each Items="{friends}">
		<!-- ... List friend ... -->
	</Each>
	<WhileEmpty Items="{friends}">
		<Text>No friends. :(</Text>
	</WhileEmpty>

`WhileEmpty` is a special case of `WhileCount` where the `EqualTo`-property is set to `0`. `WhileCount` accepts the following properties:

- `EqualTo` - Active when the count of the collection is equal to the provided value
- `GreaterThan` - Active when the count of the collection is greater than the provided value
- `LessThan` - Active when the count of the collection is less than the provided value

For example:

	<WhileCount Items="{things}" EqualTo="3" GreaterThan="3" >
		<Text>You have 3 or more things.</Text>
	</WhileCount>

## Select

If you have a complex data context and want to narrow the data context down, you can use `Select`:

	<JavaScript>
		module.exports = {
			complex: {
				item1: {
					subitem1: { name: "Spongebob", age: 32 }
				}
			}
		};
	</JavaScript>
	<Select Data="{complex.item1.subitem1}">
		<Text Value="{name}" />
		<Text Value="{age}" />
	</Select>


## Match and Case

You can drive which subtree should be active using `Match` and `Case`:

	<JavaScript>
		module.exports = {
			active: "blue"
		};
	</JavaScript>
	<Match Value="{active}">
		<Case String="red">
			<Rectangle Fill="#f00" Height="50" Width="50" />
		</Case>
		<Case String="blue">
			<Rectangle Fill="#00f" Height="50" Width="50" />
		</Case>
	</Match>

Valid match properties for `Case` are:

- `String` - match a string
- `Number` - match a number
- `Bool` - match a boolean
- `IsDefault` - default case if no other case matches

* Note: Match.Value can be data-bound to any JavaScript-type, but if using property-binding, one has to use the specialized properties `String`, `Number`, `Integer` or `Bool`. This is because property-bindings requires that the types are identical.

## DataToResource

You can bind to a defined resource using DataToResource:

	<FileImageSource ux:Key="picture" File="Pictures/Picture1.jpg" />
	<JavaScript>
		module.exports = {
			picture: "picture"
		}
	</JavaScript>
	<Image Source="{DataToResource picture}" />

