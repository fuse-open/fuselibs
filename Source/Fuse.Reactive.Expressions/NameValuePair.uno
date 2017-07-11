using Uno.UX;

namespace Fuse.Reactive
{
	/** Creates a `Fuse.NameValuePair` from a name and a value. */
	public class NameValuePair: UnaryOperator
	{
		public string Name { get; private set; }

		[UXConstructor]
		public NameValuePair([UXParameter("Name")] string name, [UXParameter("Value")] Expression value) : base(value)
		{
			Name = name;
		}

		protected override object Compute(object value)
		{
			return new Fuse.NameValuePair(Name, value);
		}
	}
}