> Note: It is recommended that you first read the [Navigation guide](/docs/navigation/navigation) for a full overview of Fuse's navigation system.

## Pages

`Navigator` takes a collection of [templates](/docs/basics/creating-components#templates-ux-template) as its children.
This allows it to instantiate and recycle pages as it needs.

You can declare a node as a template by specifying the `ux:Template` attribute. The path of the route is matched to the `ux:Template` value to select a template.

	<Page ux:Template="matchPath">

You can read more about templates [here](/docs/basics/creating-components#templates-ux-template).

Non-template pages can also be used. The `Name` of the page will be used to match the path:

	<Page Name="matchPath">
	
These pages always just have the one instance, will always be reused, and will never be removed. Otherwise they function the same as the template pages.

Here are some general rules that will you help decide whether you want to use a template or non-template page:

- If you need transitions between pages with the same path, but different parameter, then use a template.
- If you have pages that impact performance even when inactive, or for other reasons should be removed when unused, then use a template.
- If you have a page that should always exist to preserve state, or is very frequently navigated to, use a non-template.

Note that templates and non-templates can be mixed within one `Navigator`.

## Transitions

Navigator comes with a set of default transitions that match the behavior of
[`push()`](/docs/fuse/navigation/router/push_0f0d575d),
[`goBack()`](/docs/fuse/navigation/router/goback_c0e37bee) and
[`goto()`](/docs/fuse/navigation/router/goto_0f0d575d).

To have complete control over page transitions use the @PageView class. It works just like a `Navigator` but has no standard transitions or state changes.

When using custom transitions be sure to add a @ReleasePage action. This instructs the `Navigator` and `PageView` on when it can reuse, discard, or add the page to its cache.

## Example
	
The following example illustrates a basic navigation setup using a @Router and @Navigator.
For a complete introduction and proper examples of Fuse's navigation system, see the [Navigation guide](/docs/navigation/navigation).
	
	<JavaScript>
		module.exports = {
			gotoFirst: function() { router.goto("firstPage"); },
			gotoSecond: function() { router.goto("secondPage"); }
		};
	</JavaScript>

	<Router ux:Name="router" />

	<DockPanel>
		<Navigator DefaultPath="firstPage">
			<Page ux:Template="firstPage">
				<Text Alignment="Center">This is the first page.</Text>
			</Page>
			<Page ux:Template="secondPage">
				<Text Alignment="Center">This is the second page.</Text>
			</Page>
		</Navigator>
		
		<Grid Dock="Bottom" Columns="1*,1*">
			<Button Text="First page" Padding="20" Clicked="{gotoFirst}" />
			<Button Text="Second page" Padding="20" Clicked="{gotoSecond}" />
		</Grid>
	</DockPanel>
	
## Navigation Order

The `Navigator` uses discrete page progress changes while navigating. The active page will have progress `0`. If a page is pushed it will start at `1` and be switched immediately to `0`. The previously active page will become `-1`. A "back" operation will reverse the transition.

Only progresses `-1`, `0`, and `1` are used. Further distance is not calculated, nor are partial values possible.

See [Navigation Order](articles:navigation/navigationorder.md)
