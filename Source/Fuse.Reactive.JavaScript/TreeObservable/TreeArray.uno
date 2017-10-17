using Uno.Collections;
using Uno;
using Fuse;

namespace Fuse.Reactive
{
	class TreeArray : ArrayMirror, IObservableArray
	{
		internal TreeArray(Scripting.Array arr): base(arr) {}

		public IDisposable Subscribe(IObserver observer)
		{
			return new ArraySubscription(this, observer);
		}

		internal class ArraySubscription: Subscription, ISubscription
		{
			readonly IObserver _observer;

			public ArraySubscription(ArrayMirror am, IObserver observer): base(am)
			{
				_observer = observer;
			}

			public void OnReplaceAt(int index, object newValue)
			{
				_observer.OnNewAt(index, newValue);
				var next = Next as ArraySubscription;
				if (next != null) next.OnReplaceAt(index, newValue);
			}

			public void OnAdd(object newValue)
			{
				_observer.OnAdd(newValue);
				var next = Next as ArraySubscription;
				if (next != null) next.OnAdd(newValue);
			}

			public void OnInsertAt(int index, object newValue)
			{
				_observer.OnInsertAt(index, newValue);
				var next = Next as ArraySubscription;
				if (next != null) next.OnInsertAt(index, newValue);
			}

			public void OnRemoveAt(int index)
			{
				_observer.OnRemoveAt(index);
				var next = Next as ArraySubscription;
				if (next != null) next.OnRemoveAt(index);
			}

			public void OnReplaceAll(IArray values, ArraySubscription exclude)
			{
				if (this != exclude) _observer.OnNewAll(values);

				var next = Next as ArraySubscription;
				if (next != null) next.OnReplaceAll(values, exclude);
			}

			class ReplaceAllOperation
			{
				ThreadWorker _worker;
				Scripting.Array _target;
				IArray _newValues;

				public ReplaceAllOperation(ThreadWorker worker, Scripting.Array target, IArray newValues)
				{
					_worker = worker;
					_target = target;
					_newValues = newValues;
				}

				public void Perform()
				{
					var ctx = _worker.Context;

					var nv = new object[_newValues.Length];
					for (var i = 0; i < _newValues.Length; ++i) {
						nv[i] = _worker.Unwrap(_newValues[i]);
					}
					var newValuesJs = ctx.NewArray(nv);

					var replaceAllFn = (Scripting.Function) ctx.Evaluate("replaceAll",
						"(function(array, values) {" +
							"if ('__fuse_replaceAll' in array) array.__fuse_replaceAll(values);" +
							"else {"+
								"array.length = 0;"+
								"Array.prototype.push.apply(array, values);"+
							"}"+
						"})");

					replaceAllFn.Call(_target, newValuesJs);
				}
			}


			public void ReplaceAllExclusive(IArray values)
			{
				var ta = SubscriptionSubject as TreeArray;

				var worker = JavaScript.Worker;
				var replaceAll = new ReplaceAllOperation(worker, (Scripting.Array)ta.Raw, values);
				worker.Invoke(replaceAll.Perform);

				ta.ReplaceAll(values, this);
			}

			public void ClearExclusive()
			{
				ReplaceAllExclusive(new SimpleArray());
			}

			public void SetExclusive(object newValue)
			{
				ReplaceAllExclusive(new SimpleArray(newValue));
			}

			class SimpleArray : IArray
			{
				object[] _values;

				public SimpleArray(params object[] values)
				{
					_values = values;
				}

				public int Length { get { return _values.Length; } }
				public object this[int index]
				{
					get
					{
						return _values[index];
					}
				}
			}
		}

		internal void ReplaceAll(IArray newValues, ArraySubscription exclude)
		{
			for (var i = 0; i < _items.Count; ++i)
			{
				ValueMirror.Unsubscribe(_items[i]);
			}

			_items.Clear();

			for (var i = 0; i < newValues.Length; ++i)
			{
				_items.Add(newValues[i]);
			}

			var sub = Subscribers as ArraySubscription;
			if (sub != null)
				sub.OnReplaceAll(newValues, exclude);
		}

		internal void Set(int index, object newValue)
		{
			ValueMirror.Unsubscribe(_items[index]);

			_items[index] = newValue;

			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnReplaceAt(index, newValue);
		}

		internal void Add(object value)
		{
			_items.Add(value);
			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnAdd(value);
		}

		internal void InsertAt(int index, object value)
		{
			_items.Insert(index, value);
			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnInsertAt(index, value);
		}

		internal void RemoveAt(int index)
		{
			_items.RemoveAt(index);
			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnRemoveAt(index);
		}
	}
}