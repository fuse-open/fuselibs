using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Triggers;

namespace Fuse.Reactive
{
	/** Active when the number of items in a collection is 0.

		This is equivalent to using @WhileCount with `EqualTo="0"`.

		## Example

		This example displays the text `Your friends list is empty.` using `WhileEmpty`:

			<JavaScript>
				var Observable = require("FuseJS/Observable");
				module.exports = {
					friends: Observable()
				}
			</JavaScript>
			<WhileEmpty Items="{friends}">
				<Text>Your friends list is empty.</Text>
			</WhileEmpty>

		@see WhileCount
		@see WhileNotEmpty
	*/
	public class WhileEmpty : WhileCount
	{
		public WhileEmpty()
		{
			EqualTo = 0;
		}
	}

	/** Active when the number of items in a collection is greater than 0.

		This is opposite of using @WhileEmpty.

		## Example

		This example displays the text `You have at least one friend!` using `WhileNotEmpty`:

			<JavaScript>
				var Observable = require("FuseJS/Observable");
				module.exports = {
					friends: Observable("Jake")
				}
			</JavaScript>
			<WhileNotEmpty Items="{friends}">
				<Text>You have at least one friend!</Text>
			</WhileNotEmpty>

		@See WhileEmpty
	*/
	public class WhileNotEmpty : WhileCount
	{
		public WhileNotEmpty()
		{
			GreaterThan = 0;
		}
	}
}
