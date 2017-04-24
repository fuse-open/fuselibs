using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	[UXUnaryOperator("Resource")]
	public sealed class Resource: Expression
	{
		public string Key { get; private set; }
		[UXConstructor]
		public Resource([UXParameter("Key")] string key)
		{
			Key = key;
		}
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return context.SubscribeResource(this, Key, listener);
		}
	}

}

