
namespace Fuse.Controls.Graphics
{
	public abstract class ControlVisual<T>: Visual
	{
		T FindControl()
		{
			var p = (Node)this;
			while (p != null)
			{
				if (p is T) return (T)p;
				p = p.Parent;
			}
			return default(T);
		}

		T _control;
		protected T Control { get { return _control; } }

		protected override void OnRooted()
		{
			base.OnRooted();
			_control = FindControl();

			if ((object)_control == null)
				throw new Uno.Exception(this + " must be rooted in the subtree of a " + typeof(T));

			Attach();
		}

		protected override void OnUnrooted()
		{
			Detach();
			_control = default(T);
			base.OnUnrooted();
		}

		protected abstract void Attach();
		protected abstract void Detach();

		//this is a reasonable default
		protected override VisualBounds HitTestLocalBounds
		{
			get
			{
				return VisualBounds.Rect( float2(0), ActualSize );
			}
		}
	}
}