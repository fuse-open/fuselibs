using Uno;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Represents a scope in which the current data context is narrowed down.

		`With` is useful when you have a complex data context and you'd like to simplify data-binding. This is
		particularly useful for "viewing" part of a deeply-nested object graph.

		## Example
		```xml
			<JavaScript>
				module.exports = {
					complex: {
						item1: {
							subitem1: { name: "Spongebob", age: 32 }
						}
					}
				};
			</JavaScript>
			<With Data="{complex.item1.subitem1}">
				<Text Value="{name}" />
				<Text Value="{age}" />
			</With>
		```
	*/
	public class With : Triggers.Trigger, Node.ISubtreeDataProvider, ValueForwarder.IValueListener
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			Activate();
		}

		IDisposable _sub;
		object _sourceData;

		/** Specifies the new data context for the subtree.

			If this property is to an `IObservable`, the subtree will see first actual
			value of that observable.
		*/
		public object Data
		{
			get { return _sourceData; }
			set
			{
				if (_sourceData != value)
				{
					if (_sub != null) _sub.Dispose();

					_sourceData = value;

					var obs = value as IObservable;
					if (obs != null)
					{
						// Special case for `IObservable` which can be interpreted as a single value
						SetSubtreeData(null);
						_sub = new ValueForwarder(obs, this);
					}
					else
					{
						SetSubtreeData(value);
					}
				}
			}
		}

		object _subtreeData;
		ContextDataResult ISubtreeDataProvider.TryGetDataProvider( Node child, DataType type, out object provider )
		{
			provider = _subtreeData;
			return type == DataType.Prime ? ContextDataResult.NullProvider : ContextDataResult.Continue;
		}

		void ValueForwarder.IValueListener.NewValue(object value)
		{
			SetSubtreeData(value);
		}

		void ValueForwarder.IValueListener.LostValue()
		{
			SetSubtreeData(null);
		}

		void SetSubtreeData(object value)
		{
			var oldData = _subtreeData;
			_subtreeData = value;
			BroadcastDataChange(oldData, value);
		}
	}



	/**
		Deprecated (< 2017-01-01)
		@see With
	*/
	public class Select : With
	{
		public Select()
		{
			Fuse.Diagnostics.Deprecated("'Select' is deprecated, use 'With' instead (works the same way). ", this );
		}
	}
}
