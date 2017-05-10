using Uno;

using Fuse;
using Fuse.Controls;
using Fuse.Triggers;

namespace FuseTest
{
	public class BindingNode : Behavior
	{
		public Node Node { get; set; }
		public Visual Visual { get; set; }
		public Trigger Trigger { get; set; }
	}
}
