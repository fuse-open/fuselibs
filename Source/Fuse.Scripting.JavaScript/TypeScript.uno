using Uno.UX;

namespace Fuse.Reactive
{
	/**
		The `TypeScript` tag is used to run TypeScript code.

		The TypeScript code will be transpiled to JavaScript by the UX compiler
		(located in Uno) before running the app.

		## Example

		```typescript
		<TypeScript>
			const line: string = "Hello, TypeScript!"
			console.log(line)
		</TypeScript>
		```

		@topic JavaScript
	*/
	public class TypeScript : JavaScript
	{
		[UXConstructor]
		public TypeScript([UXAutoNameTable] NameTable nameTable)
			: base(nameTable)
		{
			Transpile = true;
		}
	}
}
