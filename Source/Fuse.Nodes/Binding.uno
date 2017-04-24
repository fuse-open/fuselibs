
namespace Fuse
{
	/** Base class for binding classes that provide data for a @Node properties. */
	public abstract class Binding
	{
		protected bool IsRooted { get { return Parent != null; } }
		public Node Parent { get; private set; }

		protected virtual void OnRooted() {}
		protected virtual void OnUnrooted() {}

		internal void Root(Node parent)
		{
			if (Parent != null)
				Fuse.Diagnostics.InternalError( "double Binding rooting detected", this );

			Parent = parent;
			OnRooted();
		}

		internal void Unroot()
		{
			if (Parent == null)
				Fuse.Diagnostics.InternalError( "double Binding unrooting detected", this );

			OnUnrooted();
			Parent = null;
		}
	}
}