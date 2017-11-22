using Uno.Collections;
using Fuse.Reactive;

namespace Fuse.Scripting.JavaScript
{
	class Observable : ListMirror, IObservable
	{
		List<object> _values = new List<object>();
		public override int Length { get { return _values.Count; } }

		public override object this[int index]
		{
			get { return _values[index]; }
			
		}

		public void SetValue(int index, object value)
		{
			_values[index] = value;
		}

		readonly List<Subscription> _observers = new List<Subscription>();
		bool _usingObservers;
		
		void ObserversCleanup()
		{
			if (_usingObservers)
				return;
		
			for (int i=_observers.Count-1; i>=0; --i)
			{
				if (_observers[i].Removed)
					_observers.RemoveAt(i);
			}
		}
		
		internal int TestObserverCount
		{
			get
			{
				var c =0;
				for (int i=0; i < _observers.Count; ++i)
				{
					if (!_observers[i].Removed)
						c++;
				}
				return c;
			}
		}

		public class Subscription: DiagnosticSubject, ISubscription
		{
			static int _counter = 1;
			readonly int _origin;
			public int Origin { get { return _origin; } }
			//actual remove is deferred until safe (`Perform` locks the removals)
			public bool Removed { get; private set; }
			
			public bool ShouldSend(int origin = -1)
			{
				return !Removed && origin != _origin;
			}

			readonly Observable _om;
			readonly IObserver _obs;
			public IObserver Observer { get { return _obs; } }

			public Subscription(Observable om, IObserver obs)
			{
				Removed = false;
				_origin = _counter++;

				om._observers.Add(this);
				_om = om;
				_obs = obs;

			}

			class SetExclusiveOperation
			{
				public SetExclusiveOperation(IThreadWorker worker, Scripting.Object obj, object newValue, int origin, DiagnosticSubject diagnosticSubject)
				{
					Worker = worker;
					Object = obj;
					NewValue = newValue;
					Origin = origin;
					DiagnosticSubject = diagnosticSubject;
				}

				readonly IThreadWorker Worker;
				readonly Scripting.Object Object;
				readonly object NewValue;
				readonly int Origin;
				readonly DiagnosticSubject DiagnosticSubject;

				public void Perform(Scripting.Context context)
				{
					try
					{
						var newValue = context.Unwrap(NewValue);
						Object.CallMethod(context, "setValueWithOrigin", newValue, Origin);
					}
					catch (Scripting.ScriptException ex)
					{
						//This assumes the Observable.js code is not the source of the error and thus it must be
						//user code causing the problem
						DiagnosticSubject.SetDiagnostic(ex);
					}
				}
			}

			public void SetExclusive(Scripting.Context context, object newValue)
			{
				ClearDiagnostic();

				if (_om.Object == null)
				{
					Fuse.Diagnostics.InternalError( "Unexpected null object", this );
					return;
				}

				var op = new SetExclusiveOperation(_om._worker, _om.Object, newValue, _origin, this);
				op.Perform(context);
			}

			void ISubscription.SetExclusive(object newValue)
			{
				ClearDiagnostic();

				if (_om.Object == null)
				{
					Fuse.Diagnostics.InternalError( "Unexpected null object", this );
					return;
				}

				var op = new SetExclusiveOperation(_om._worker, _om.Object, newValue, _origin, this);
				_om._worker.Invoke(op.Perform);
			}

			class ReplaceAllExclusiveOperation
			{
				public ReplaceAllExclusiveOperation(IThreadWorker worker, Scripting.Object obj, object[] newValues, int origin)
				{
					Worker = worker;
					Object = obj;
					NewValues = newValues;
					Origin = origin;
				}

				readonly IThreadWorker Worker;
				Scripting.Object Object;
				readonly object[] NewValues;
				readonly int Origin;


				public void Perform(Scripting.Context context)
				{
					for (int i = 0; i < NewValues.Length; i++)
						NewValues[i] = context.Unwrap(NewValues[i]);

					Object.CallMethod(context, "replaceAllWithOrigin", context.NewArray(NewValues), Origin);
				}
			}

			void ISubscription.ReplaceAllExclusive(IArray newValues)
			{
				var arr = new object[newValues.Length];
				for (int i = 0; i < arr.Length; i++)
					arr[i] = newValues[i];

				var op = new ReplaceAllExclusiveOperation(_om._worker, _om.Object, arr, _origin);
				_om._worker.Invoke(op.Perform);
			}

			public void ReplaceAllExclusive(Scripting.Context context, IArray newValues)
			{
				var arr = new object[newValues.Length];
				for (int i = 0; i < arr.Length; i++)
					arr[i] = newValues[i];

				var op = new ReplaceAllExclusiveOperation(_om._worker, _om.Object, arr, _origin);
				op.Perform(context);
			}

			class ClearExclusiveOperation
			{
				public ClearExclusiveOperation(Scripting.Object obj, int origin)
				{
					Object = obj;
					Origin = origin;
				}

				Scripting.Object Object;
				readonly int Origin;


				public void Perform(Scripting.Context context)
				{
					Object.CallMethod(context, "clear", Origin);
				}
			}

			public void ClearExclusive(Scripting.Context context)
			{
				var op = new ClearExclusiveOperation(_om.Object, _origin);
				op.Perform(context);
			}

			void ISubscription.ClearExclusive()
			{
				var op = new ClearExclusiveOperation(_om.Object, _origin);
				_om._worker.Invoke(op.Perform);
			}

			/**
				Unsubscribes from receiving updates.
			*/
			public void Dispose()
			{
				Removed = true;
				_om.ObserversCleanup();
			}
		}

		/**
			Subscribes to updates on the `Observable`.
			
			The `Observer` state will be updated just prior to the callback on the `IObserver`.
			The internal state will be consistent with the state expected as a result of that operation (it
			won't lag behind or go ahead with compount operations, such as InsertAll using individual
			operations).
		*/
		public ISubscription Subscribe(IObserver observer)
		{
			return SubscribeInternal(observer);
		}

		internal Subscription SubscribeInternal(IObserver observer)
		{
			return new Subscription(this, observer);
		}

		Uno.IDisposable IObservableArray.Subscribe(IObserver observer)
		{
			return Subscribe(observer);
		}

		readonly IThreadWorker _worker;

		Scripting.Object _observable;
		internal Scripting.Object Object { get { return _observable; } }

		Scripting.Function _observeChange;

		internal Observable(Scripting.Context context, ThreadWorker worker, Scripting.Object obj, bool suppressCallback): base(obj)
		{
			_worker = worker;
			_observable = obj;
			_observeChange = context.CallbackToFunction((Scripting.Callback)ObserveChange);
			obj.CallMethod(context, "addSubscriber", _observeChange, suppressCallback);
		}

		internal static Observable Create(Scripting.Context context, ThreadWorker worker)
		{
			var jsContext = (JSContext)context;
			return new Observable(context, worker, (Scripting.Object)jsContext.FuseJS.Observable.Call(context), true);
		}

		int ToInt(object obj)
		{
			if (obj is int)
				return (int) obj;
			if (obj is double)
				return (int)((double)obj);
			return -1;
		}

		object ObserveChange(Scripting.Context context, object[] args)
		{
			var ctx = (JSContext)context;

			var op = args[1] as string;
			var origin = ToInt(args[2]);

			if (op == "set")
			{
				UpdateManager.PostAction(new Set(this, ctx.Reflect(args[3]), origin).Perform);
			}
			else if (op == "clear") 
			{
				UpdateManager.PostAction(new Clear(this, origin).Perform);
			}
			else if (op == "newAt")
			{
				UpdateManager.PostAction(new NewAt(this, ToInt(args[3]), ctx.Reflect(args[4])).Perform);
			}
			else if (op == "newAll") 
			{
				UpdateManager.PostAction(new NewAll(this, (ArrayMirror)ctx.Reflect(args[3]), origin).Perform);
			}
			else if (op == "add") 
			{
				UpdateManager.PostAction(new Add(this, ctx.Reflect(args[3])).Perform);
			}
			else if (op == "removeAt")
			{
				UpdateManager.PostAction(new RemoveAt(this, ToInt(args[3])).Perform);
			}
			else if (op == "insertAt")
			{
				UpdateManager.PostAction(new InsertAt(this, ToInt(args[3]), ctx.Reflect(args[4])).Perform);
			}
			else if (op == "removeRange")
			{
				UpdateManager.PostAction(new RemoveRange(this, ToInt(args[3]), ToInt(args[4])).Perform);
			}
			else if (op == "insertAll") 
			{
				UpdateManager.PostAction(new InsertAll(this, ToInt(args[3]), (ArrayMirror)ctx.Reflect(args[4])).Perform);
			}
			else if (op == "failed")
			{
				UpdateManager.PostAction(new Failed(this, args[3] as string).Perform);
			}
			else 
			{	
				throw new Uno.Exception("Unhandled observable operation: " + op);
			}

			return null;
		}

		bool _isUnsubscribed;
		public bool IsUnsubscribed { get { return _isUnsubscribed; } }

		// JS thread
		public override void Unsubscribe()
		{
			UnsubscribeValues();

			if (!_isUnsubscribed)
			{
				_isUnsubscribed = true;
				_worker.Invoke(RemoveSubscriber);
			}
		}

		void UnsubscribeValues()
		{
			for (int i = 0; i < _values.Count; i++)
			{
				var vm = _values[i] as ValueMirror;
				if (vm != null) vm.Unsubscribe();
			}
		}

		void RemoveSubscriber(Scripting.Context context)
		{
			_observable.CallMethod(context, "removeSubscriber", _observeChange);
			_observeChange = null;
			_observable = null;
		}

		public abstract class Operation
		{
			readonly Observable _observable;

			bool _isPerformed;

			protected Operation(Observable observable)
			{
				_observable = observable;
			}

			protected Observable Observable { get { return _observable; } }

			public void Perform()
			{
				if (_observable.IsUnsubscribed) 
				{
					Unsubscribe();
					return;
				}

				try
				{
					_observable._usingObservers = true;
					OnPerform(Observable._observers);
					_observable.ObserversCleanup();
				}
				finally
				{
					_observable._usingObservers = false;
				}
				
				_isPerformed = true;
			}

			protected virtual void Unsubscribe() {}

			/**
				@param sub a list of subscriptions to inform. This must be provided as part of OnPerfom
					in case the operation isn't supported directly and is done as a series of steps, like
					`RemoveRange`. The callbacks must be done on those steps to have an internal
					consistent state with `Observable`.  The `ShouldSend` function should be used on
					each sub (to also support deferred deletion at no cost)
			*/
			protected abstract void OnPerform(IList<Subscription> sub);
		}

		class Set: Operation
		{
			readonly object _value;
			readonly int _origin;

			public Set(Observable obs, object value, int origin): base(obs)
			{
				_value = value;
				_origin = origin;
			}

			protected override void Unsubscribe()
			{
				ValueMirror.Unsubscribe(_value);
			}

			protected override void OnPerform(IList<Subscription> sub)
			{
				Observable.UnsubscribeValues();

				Observable._values.Clear();
				Observable._values.Add(_value);
				
				for (int i=0; i < sub.Count; ++i)
				{
					if (sub[i].ShouldSend(_origin))
						sub[i].Observer.OnSet(_value);
				}
			}
		}

		class Clear: Operation
		{
			readonly int _origin;

			public Clear(Observable obs, int origin): base(obs)
			{
				_origin = origin;
			}

			protected override void OnPerform(IList<Subscription> sub)
			{
				Observable.UnsubscribeValues();
				Observable._values.Clear();
				
				for (int i=0; i < sub.Count; ++i)
				{
					if (sub[i].ShouldSend(_origin))
						sub[i].Observer.OnClear();
				}
			}
		}
		
		class Failed : Operation
		{
			readonly string _message;
			
			public Failed(Observable obs, string message) : base(obs)
			{
				_message = message;
			}
			
			protected override void OnPerform(IList<Subscription> sub)
			{
				Observable.UnsubscribeValues();
				Observable._values.Clear();
				
				for (int i=0; i < sub.Count; ++i)
				{
					if (sub[i].ShouldSend())
						sub[i].Observer.OnFailed(_message);
				}
			}
		}

		class NewAt: Operation
		{
			readonly int _index;
			readonly object _value;

			public NewAt(Observable obs, int index, object newValue): base(obs)
			{
				_index = index;
				_value = newValue;
			}

			protected override void Unsubscribe()
			{
				ValueMirror.Unsubscribe(_value);
			}


			protected override void OnPerform(IList<Subscription> sub)
			{
				ValueMirror.Unsubscribe(Observable[_index]);
				Observable.SetValue(_index, _value);
				
				for (int i=0; i < sub.Count; ++i)
				{
					if (sub[i].ShouldSend())
						sub[i].Observer.OnNewAt(_index, _value);
				}
			}
		}

		class NewAll: Operation
		{
			readonly ArrayMirror _newValues;
			readonly int _origin;

			public NewAll(Observable obs, ArrayMirror newValues, int origin): base(obs)
			{
				_newValues = newValues;
				_origin = origin;
			}

			protected override void Unsubscribe()
			{
				ValueMirror.Unsubscribe(_newValues);
			}

			protected override void OnPerform(IList<Subscription> sub)
			{
				Observable.UnsubscribeValues();

				Observable._values.Clear();
				Observable._values.AddRange(_newValues.ItemsReadonly);
				
				for (int i=0; i < sub.Count; ++i)
				{
					if (sub[i].ShouldSend(_origin))
						sub[i].Observer.OnNewAll(_newValues);
				}
			}
		}

		class Add: Operation
		{
			readonly object _value;

			public Add(Observable obs, object value): base(obs)
			{
				_value = value;
			}

			protected override void OnPerform(IList<Subscription> sub)
			{
				Observable._values.Add(_value);
				
				for (int i=0; i < sub.Count; ++i)
				{
					if (sub[i].ShouldSend())
						sub[i].Observer.OnAdd(_value);
				}
			}
		}

		class RemoveAt: Operation
		{
			readonly int _index;

			public RemoveAt(Observable obs, int index): base(obs)
			{
				_index = index;
			}

			protected override void OnPerform(IList<Subscription> sub)
			{
				ValueMirror.Unsubscribe(Observable[_index]);
				Observable._values.RemoveAt(_index);
				
				for (int i=0; i < sub.Count; ++i)
				{
					if (sub[i].ShouldSend())
						sub[i].Observer.OnRemoveAt(_index);
				}
			}
		}

		class RemoveRange: Operation
		{
			readonly int _index;
			readonly int _count;

			public RemoveRange(Observable obs, int index, int count): base(obs)
			{
				_index = index;
				_count = count;
			}

			protected override void OnPerform(IList<Subscription> sub)
			{
				// todo: optimize, introduce IObserver.OnRemoveRange
				for (int i = 0; i < _count; i++)
				{
					ValueMirror.Unsubscribe(Observable[_index]);
					Observable._values.RemoveAt(_index);
					
					for (int j=0; j < sub.Count; ++j)
					{
						if (sub[j].ShouldSend())
							sub[j].Observer.OnRemoveAt(_index);
					}
				}
			}
		}

		class InsertAt: Operation
		{
			readonly int _index;
			readonly object _value;

			public InsertAt(Observable obs, int index, object value): base(obs)
			{
				_index = index;
				_value = value;
			}

			protected override void Unsubscribe()
			{
				ValueMirror.Unsubscribe(_value);
			}

			protected override void OnPerform(IList<Subscription> sub)
			{
				Observable._values.Insert(_index, _value);
				
				for (int i=0; i < sub.Count; ++i)
				{
					if (sub[i].ShouldSend())
						sub[i].Observer.OnInsertAt(_index, _value);
				}
			}
		}

		class InsertAll: Operation
		{
			readonly int _index;
			readonly ArrayMirror _items;

			public InsertAll(Observable obs, int index, ArrayMirror items): base(obs)
			{
				_index = index;
				_items = items;
			}

			protected override void Unsubscribe()
			{
				ValueMirror.Unsubscribe(_items);
			}

			protected override void OnPerform(IList<Subscription> sub)
			{
				// TODO: optimize, introduce Observer.OnInsertAll
				for (int i = 0; i < _items.Length; i++)
				{
					Observable._values.Insert(_index+i, _items[i]);
					
					for (int j = 0; j < sub.Count; ++j)
					{
						if (sub[j].ShouldSend())
							sub[j].Observer.OnInsertAt(_index+i, _items[i]);
					}
				}
			}
		}
	}
}
