# Working with named objects

## Static naming (`ux:Name`)

It is recommended to primarily work with *static names* with UX documents. Static names are specified using the `ux:Name` attribute. This also implicitly sets the `Name` property accordingly on objects that support the property, such as @Nodes.

Statically named objects can be referenced from other UX nodes and resolved at compile time, e.g.

	<Panel ux:Name="panel1" />
	<AlternateRoot ParentNode="panel1">
		<Image ... />
	</AlternateRoot>

Or,

	<Rectangle ux:Name="rect1" ... />
	<WhilePressed>
		<Change rect1.CornerRadius="20" />
	</WhilePressed


Note that `ux:Name` must be set to a static name at compile time, it can not be used with a binding or changed at runtime.

`ux:Name` can be used on all objects, even those which don't support a `Name` property. 

Inside a `ux:Class` or `ux:InnerClass`, the root node (the one decorated with `ux:Class`) is named `this` by default. You don't need to give it a name explicitly.

## Name uniqueness and scoping

Static names must be unique within the scope it is declared. 

A node marked `ux:Class` represents a new root scope. You can not reference names in a different class.

Nodes marked `ux:InnerClass` and factory nodes represents child scopes. A factory node is e.g. a node declared within an @Each node.

Child scopes may access names from their parent scopes. Parent scopes may not access names in child scopes, as names in child scopes are not unique or guaranteed to exist at runtime. Child scopes may not access names from their sibling scopes for the same reason.

## Dynamic naming (`Name`)

Sometimes Nodes must be assigned a name dynamically. This can be done by using the @Node.Name property.

	<Panel Name="{name}">

Note that dynamically named objects can not be referenced statically by @Change animators or similar. 

Uniqueness and scoping is not enforced for dynamic names, which can lead to ambiguity and name clashes at runtime.

## Dynamic resolving of named @Nodes in data-binding

When data-binding to a property that expects a @Node, you can provide a string with the name of the node.

For this to work, the name must be unique within the context it is used. Names are first looked up in the subtree of inquiry, then traversing to the parent node, searching it's subtree. The first node with a matching name is returned, regardless of whether there were multiple objects matching the name at the same level. Take extra care to avoid name clashes if using dynamic naming.
