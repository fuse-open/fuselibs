using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Threading;

namespace Fuse.Reactive
{
	/** Represents an object with reactive properties.

		An `IObject` that also implements this interface will emit events to observers when the
		value of any of its properties change.

		This interface can be implemented by any reactive data provider that wants to interop
		with the `Fuse.Reactive` framework.
	*/
	interface IObservableObject: IObject
	{
		/** Creates a new subscription to the object, which will pass change events to the given observer. */
		IPropertySubscription Subscribe(IPropertyObserver observer);
	}

	interface IPropertySubscription: IDisposable
	{
		/** Attempts to write back to the property. If successful, the current subscription will not be notified. */
		bool TrySetExclusive(string propertyName, object newValue);
	}

	interface IPropertyObserver
	{
		/**
			@param subscription The subscription that corresponds to this change event. Should be used to filter events that arrived after disposal.
			@param propertyName The name of the property that changed
			@param newValue The new value of the property
		*/
		void OnPropertyChanged(IDisposable subscription, string propertyName, object newValue);
	}

	/** Represents a reactive collection. 

		This interface can be implemented by any reactive data provider that wants to interop
		with the `Fuse.Reactive` framework.

		## Availability of data

		As `IObservableArray` extends `IArray`, it is always safe to read synchronously from
		the collection in the range `0..Length`. However, any meaningful data may be unavailable 
		(and hence `Length == 0`), or out of date. 
		
		A subscription is needed in order to instruct the implementation to fetch the
		underlaying data or bring the collection up to date. When subscribed to, the data 
		may then be fetched	asynchronously. The first reliable up-to-date data is passed 
		to the subscription	via callbacks.
	*/
	interface IObservableArray: IArray
	{
		/** Creates a new subscription to the collection, which will pass change events to the given observer. 

			## Disposal of subscription

			The returned object is an `IDisposable`. Calling `Dispose()` on the subscription will unsubscribe from further
			callbacks to the subscriber. However, the subscriber cannot safely assume that no more callbacks will be made.
			The implementation may have already queued additional callbacks	to the subscriber that cannot be cancelled.
			The subscriber must filter out any late callback messages that arrives after disposal of the subscription.

			## Write-back subscriptions
			
			The returned object may or may not support the `ISubscription` interface. The subscriber can test whether the
			returned object `is ISubscription`.If so, the data source supports write-backs	to the data source, where
			the current subscription can be excluded from callbacks.
		*/
		IDisposable Subscribe(IObserver observer);
	}

	/** Represents a single reactive value, or a reactive collection.

		Note that `Fuse.Reactive.IObservable` has many differences from observables in other reactive
		frameworks (such as Rx, or `Uno.IObservable`). This is to accommodate many different types of data providers.

		An `IObservable` can be in several significant states:
		 * It can be *empty*, i.e. have *no value* (`Length == 0`)
		 * It can hold a single primary value (`Length == 1`)
		 * It can hold multiple values (`Length > 1`). The value at index `0` is still refered to as the *primary value*.

		The most significant implementation of this interface is `FuseJS/Observable`.

		## Primary value usage

		This interface extends the `IObservableArray` with the added contract of
		being interpretable as a single value, called the *primary value*. The primary
		value of the `IObservable` is the value at index `0` in the collection, if available.
		
		When interpreted as a single value, it is valid for the collection to be empty, 
		which which means the primary value is not available. It is also valid for the
		collection to have more than one value, in which case the other values will be ignored.
		
		The `IObservable` interface receives special treatment by the reactive operators. For 
		example, consider the following data-binding expression:

			<Text>Hello {user.name}!</Text>

		If `user` is an `IObservable`, then this data binding refers to `user[0].name`, when
		at least one element is available in the `IObservable`.

		An `IObservable` also gets special treatment by `DataBinding`. If a bound expression
		yields an `IObservable`, and the target property is not compatible with `IObservable`,
		the data binding will create a subscription and feed the primary value to the target
		property. Example:

			<Text>{message}</Text>

		If `message` yields an `IObservable`, the primary value (`message[0]`) of the observable 
		will be displayed, if available. If there primary value is not available, the expression
		will not yield any value (no value is written to the target property.)

		Some properties accept all types (`object`), or `IObservable` explicitly. In these cases,
		the data binding will not create a subscription, but rather pass the object directly to 
		the target property for it to create a subscription. Examples of this is `Each.Items`,
		`Selection.Values`, `Match.Value`, `With.Data` and `WhileCount.Items`.

		## Multi-value usage

		If an `IObservable` is subscribed to in a scenario where an array is expected,
		the object behaves identically to `IObservableArray`.
	*/
	interface IObservable: IObservableArray
	{

	}

	/** Represents a subscription to an `IObservableArray` that supports write-backs. */
	interface ISubscription: IDisposable
	{
		/** Clears the contents of the `IObservableArray` without notifying this subscription of the change. */
		void ClearExclusive();
		/** Replaces the `IObservableArray` with a list of length 1, containting the given object, without notifying this subscription of the change. */
		void SetExclusive(object newValue);
		/** Replaces the `IObservableArray` with the given values, without notifying this subscription of the change. */
		void ReplaceAllExclusive(IArray values);
	}
	
	/** Represents an object that can receive change notifications for an `IObservableArray`. */
	interface IObserver
	{
		/** Clear all items */
		void OnClear();
		/** Replace all items with these new values (clear old list, set new list) */
		void OnNewAll(IArray values);
		/** Replace the item at the index */
		void OnNewAt(int index, object newValue);
		/** Replace all items with this singular value */
		void OnSet(object newValue);
		/** Add a new item to the list */
		void OnAdd(object addedValue);
		/** Remove an item at the given index */
		void OnRemoveAt(int index);
		/** Insert an item at the given index */
		void OnInsertAt(int index, object value);
		void OnFailed(string message);
	}
}