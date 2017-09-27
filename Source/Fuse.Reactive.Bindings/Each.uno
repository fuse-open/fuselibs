using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Triggers;

namespace Fuse.Reactive
{
	/** Displays a collection of objects using the given template(s) for each item.

		The children of an `Each` tag represent a template that will be "projected" for each item in the collection
		specified by the `Items` property. The projected item then becomes the data context for that instance, so
		data-binding can be specified relative to the item itself rather than having to index the collection explicitly.
		
		Note that each subtree projected by `Each` lives in its own scope.
		This means that the children of an `Each` cannot be accessed from outside it.
		You can, however, access nodes declared outside the `Each` from the inside.

		## Example

			<JavaScript>
				module.exports = {
					items: [
						{ name: "Jake", age: 24 },
						{ name: "Julie", age: 25 },
						{ name: "Jerard", age: 26 }
					]
				};
			</JavaScript>
			<StackPanel>
				<Each Items="{items}">
					<StackPanel>
						<Text Value="{name}" />
						<Text Value="{age}" />
					</StackPanel>
				</Each>
			</StackPanel>

		# Using `Each` with `ux:Template`

		If you are using `Each` in a custom made component, you can increase the cusomizability of that component by allowing it to take in custom template objects which it can use instead of the default template the `Each` is using. To do this, you need to do two things:

		 * Give the `TemplateSource` property an element that can recieve templates (in the case of custom made components, that would be your custom component's class)
		 * Specify the template name `Each` will be looking for, using the property `TemplateKey`

		If a template isn't specified, the child element of `Each` will be used as a de-facto template.

		## Example
		The following example demonstrates passing custom templates into a class for an `Each` to use:

			<StackPanel ux:Class="CoolRepeater" Background="#FAD">
				<Each TemplateSource="this" TemplateKey="Item" Count="20">
					<Text>No template is given</Text>
				</Each>
			</StackPanel>
			<CoolRepeater>
				<Text ux:Template="Item">Hello, world!</Text>
			</CoolRepeater>

		Notice that if you remove the "Hello, world!" text that is our custom template, the `Each` will fall back to using the child as the template.

		If you want the ability to control the template on a per-item basis, the similar `MatchKey`-property can be used:

			<JavaScript>
			    var Observable = require("FuseJS/Observable");

			    module.exports.posts = Observable(
				    {postType: "text", body: "Lorem ipsum", title: "Hello, world"}, 
				    {postType: "quote", quote: "Stuff", title: "A quote"}
			    );
			</JavaScript>

			<ScrollView>
				<StackPanel>
					<Each Items="{posts}" MatchKey="postType"> 
						<StackPanel ux:Template="text" Height="100" Color="#FFF" Margin="10" Padding="10">
							<Shadow Distance="3" />
							<Text FontSize="25" Value="{title}" />
							<Text FontSize="15" Value="{body}" TextWrapping="Wrap" />
						</StackPanel>
						<DockPanel ux:Template="quote" Height="200" Color="#FFF" Margin="10" Padding="10">
							<Shadow Distance="3" />
							<Text FontSize="25" Value="{title}" Dock="Top" />
							<Text FontSize="50" Value="”" Dock="Left" />
							<Text FontSize="15" Margin="10" Value="{quote}" />
						</DockPanel>
					</Each>
				</StackPanel>
			</ScrollView>

		`MatchKey` works by looking for a property in the data context of each item from `Items`.
		The value of this property is then used to determine the template to use for the current item. 
		In the above example, we store the template we want to use in the property `postType`, which will appear in the data context of each item being iterated.
	*/
	public class Each: Instantiator
	{
		static PropertyHandle _eachHandle = Properties.CreateHandle();

		static Each GetEach(Visual container)
		{
			var each = container.Properties.Get(_eachHandle) as Each;
			if (each == null)
			{
				each = new Each(container.Templates);
				container.Properties.Set(_eachHandle, each);
				container.Children.Add(each);
			}
			return each;
		}

		[UXAttachedPropertySetter("Each.Items")]
		/** The item collection that will be used to populate this visual.

			The item collection can be a script array, @Observable or Uno array.

			For the view to be populated, you also have to:
			* Provide at least one `ux:Template` as a child of this visual
			* Set the @MatchKey property to the name of a field on each data item
			  that will be used to select the corresponding template.
		*/
		public static void SetItems(Visual container, object items)
		{
			GetEach(container).Items = items;
		}

		[UXAttachedPropertyGetter("Each.Items")]
		public static object GetItems(Visual container)
		{
			return GetEach(container).Items;
		}

		[UXAttachedPropertySetter("Each.MatchKey")]
		/** Shorthand for setting the `MatchKey` property on the implicit `Each` created when using the `Items` attached property. */
		public static void SetMatchKey(Visual container, string key)
		{
			GetEach(container).MatchKey = key;
		}

		[UXAttachedPropertyGetter("Each.MatchKey")]
		public static string GetMatchKey(Visual container)
		{
			return GetEach(container).MatchKey;
		}

		Each(IList<Template> templates): base(templates) {}
		public Each() {}

		/** A collection containing the data items used to populate the parent. 

			This property can not be used together with `Count`.

			The provided object must implement `IArray`. To support dynamic changes to the collection, it can also implement `IObservableArray`.
			For example, if a `FuseJS/Observable` is provided, this implements `IObservableArray`.
	
			Each item in the collection can in turn be an `IObservable`. If so, the Each will subscribe to these items and use the dynamic value. However,
			this will not work in combination with the `MatchKey`, `IdentityKey` and `MatchObject` features which require an immediate value.

			For legacy reasons, this property will also accept an `object[]` as the collection. This feature is deprecated.
		*/
		public object Items
		{
			get { return _items; }
			set
			{
				if (_items != value)
				{
					_items = value;
					OnItemsChanged();
				}
			}
		}

		/** The number of items to create. If `Items` is set, this property is ignored. */
		new public int Count
		{
			get { return base.Count; }
			set { base.Count = value; }
		}

		/**
			The index of the first item added.
			
			The default is 0.
			
			This can be used together with `Limit` to create a window of items.
		*/
		new public int Offset 
		{
			get { return base.Offset; }
			set { base.Offset = value; }
		}

		/**
			Limits the number of items added by each.
			
			The default is to not limit the number of items added.
			
			The first item is the one at `Offset`, and then subsequent items, up to the `Limit` amount, are added.
		*/
		new public int Limit
		{
			get { return base.Limit; }
			set { base.Limit = value; }
		}
	}
}
