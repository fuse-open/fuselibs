# Documenting Fuselibs

## What to document

All new features should be documented by the implementor of the feature. Generally, this will be covered by inline documentation here in `fuselibs`, but sometimes a larger article is helpful. See the `fuse-docs` [documentation procedure](https://github.com/fusetools/fuse-docs/wiki/Documentation-Procedure) for more info about these cases.

If you find something that hasn't been documented yet, feel free to make a ticket on `fuse-docs` and that team can take care of it.

## Docs team review

It's a good idea to have the docs team review docs for your shiny new feature before they go out. Feel free to ping them in #docs on slack at any time, preferably with commit/PR links so they can have a look and fix grammatical mistakes, provide feedback, etc.

## Markdown comment blocks

A language entity can be documented with a comment starting with `/**`. All text in such a comment is interpeted as markdown, with special pre-processing. 

> Note: For now, we don't support real markdown. Only the features mentioned in this doc are supported. Use inline HTML for the rest.

The indentation of the first non-whitespace character in the markdown body is counted as the base indentation for the entire body.

	/**
		This is text

			This is code
	**/

Leading and trailing whitespace will be removed, as well as the base indentation for each line.

Also note that multi-line code blocks inside doc comments is *indented*, not surrounded by triple-backticks.

## Documenting language entities

All data types, type members and enum literals can have a markdown comment block.

	/** This is doc for A */
	public class A 
	{
		/** This is doc for Foo */
		public float Foo { get; }
	}
	
	/** This is doc for B
	
	And some more info, with an example:
	
		Super rad example goes here
	
	*/
	public enum B
	{
		/** This is doc for Moo */
		Moo,
		
		/** This is doc for Goo */
		Goo
	}
	
The first line of a doc comment is generally a TL;DR/short description of what the class does. This will be used in "class lists" such as [this one](https://fuseopen.com/docs/fuse/triggers/trigger) (this list also serves as a great example for how concise these should be).

When adding examples, include a header and a short description, and try to place them at the end of the text. Example:

	### Example
	This example shows a button
	
		<Button Text="button" />
		
Generally try to keep the documentation short. If you need to write a lot about something, consider making a guide about it (see next section) and shorten the inline documentation.

Explain properties by using documentation tags on the actual property if you can. This is sadly impossible in UX at the moment.
	
## Creating stand-alone articles

Stand-alone articles are created on the fuse-docs repo. Refer to [the documentation procedure document there](https://github.com/fusetools/fuse-docs/wiki/Documentation-Procedure) for more info.

## Referencing other langauge entities

Other language entities can be referenced with the same rules as regular Uno name resolving rules, with an `@` prefix. 
This means that other members of the same class or namespace can be referenced by `@Member`. Other members can be qualified in the same manner as Uno name resolving.

Classes in the default namespace pool such as `@Rectangle` can be referenced without qualifier.

When an entity is referenced somewhere, the entity's page will link to that page under a "Referenced in" section.

Names can have a pluralizing trailing `s` that is implicitly stripped when resolving the name. For example `@Nodes` refer to the `@Node` class (given that there is no actual entity called `Nodes` - then that would take precedence).

## Implicit inlining of relevant content

A lot of content will be implicitly inlined.

* Properties of enum type will have all available enum values inlined, with full description.
* Classes with subclasses will have the known subclasses listed, with brief description.
* Classes that can not be instantiated in UX (e.g. abstract classes) are clearly marked as such automatically, this need not be specified.

## Built-in macros

`@include Docs/File.md` - Inlines the content of the specified file at this point in the markdown block.

`@remarks Docs/File.md` - Places the content of the specified file in the remarks-section for the given entity.

`@default foo` - Indicates that the default value for the entity in question is `foo`

`@option Foo description` - Indicates that `Foo` is a possible setting for this property, with `description` as its documentation. This is mainly used for properties that allow assigning global singletons instead of enums. (For enums, prefer to document the enum instead of using this)

`@example Docs/File.md` - Indicates that a complete example for the entity in question is found int the file `Docs/File.md` relative to the source file.

`@docs Docs/File.md` - Indicates that the entire markdown comment block is found in the specified file, instead of here.

`@uno` - All text after this marker (either on the beginning of a line or as a line of its own) is marked as only interesting for uno coders.

`@unodoc Docs/File.md` - Points to a relevant file which content is only interesting to people writing uno code


## Headers

When using headers in a comment block, header levels will be normalized when the doc is processed. That is, the highest level you use will be normalized to the appropriate level for that section. So feel free to use the highest level (single hash) for subtopics.
