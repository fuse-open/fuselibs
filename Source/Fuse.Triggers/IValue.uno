using Uno.UX;

namespace Fuse.Triggers
{
	public interface IValue<T>
	{
		T Value { get; set; }
		event ValueChangedHandler<T> ValueChanged;
	}
}