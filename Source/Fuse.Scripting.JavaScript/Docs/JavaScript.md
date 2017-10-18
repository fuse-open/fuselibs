# Working with JavaScript modules

## Scripts as data context

If a `<JavaScript>` tag is placed inside an UX @Visual, it will be evaluated for each instance of the @Visual, and the resulting
`module.exports` becomes the @DataContext of the parent @Visual.

Example:

	<Panel>
		<JavaScript>
			module.exports = { foo: "bar" }
		</JavaScript>
		<Text Value="{foo}" />
	</Panel>

The `Text` in the above example will display the string `bar`. 

## Global modules

If a `<JavaScript>` tag is decorated with `ux:Global="alias"`, it will not behave as data context for the containing node. Instead, it becomes available to `require()` with `alias` as the module name.

Example:

	<Panel>
		<JavaScript File="foo.js" ux:Global="foo" />

		<JavaScript>
			var foo = require("foo");
		</JavaScript>
	</Panel>