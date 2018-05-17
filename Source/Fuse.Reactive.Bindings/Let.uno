using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Reactive
{
	/**
		Provides an implementation for `Let` and the various `LetType` forms.
		@hide
	*/
	public abstract class LetBase : Behavior, Node.ISiblingDataProvider, IObject, IPropertyListener
	{
		internal LetBase() { }
		
		static Selector ValueName = "Value";
		
		bool _hasValue;
		object _value;
		internal object ObjectValue
		{
			get { return _value; }
		}
		
		internal bool HasValue
		{
			get { return _hasValue; }
		}

		LetObservable _observable;
		public void SetObjectValue( object value, IPropertyListener origin)
		{
			if (_hasValue && Object.Equals(_value, value))
				return;

			_value = value;
			_hasValue = true;
			UpdateValue(origin);
		}

		bool _updated;
		void UpdateValue( IPropertyListener origin )
		{
			_updated = true;
			OnPropertyChanged( ValueName, origin );
			if (_value is IObservable)
			{
				_observable = null;
				DataChanged( _value );
			}
			else
			{
				if (_observable == null)
				{
					_observable = new LetObservable(this);
					DataChanged( _observable );
				}
				else if (_hasValue)
				{
					_observable.UpdateSetValue();
				}
				else
				{
					_observable.UpdateClear();
				}
			}
		}
		
		void DataChanged( object newValue )
		{
			// it's possible to arrive here prior to `Name` being set since property order is not guaranteed in the UX compiler
			if (Name == null)
			{
				if (IsRootingStarted)
					Fuse.Diagnostics.UserWarning( "Missing a `Name` for Let", this );
				return;
			}
				
			OnDataChanged( Name, newValue );
		}
		
		internal void ResetObjectValue()
		{
			_value = null;
			_hasValue = false;
			UpdateValue(this);
		}
		
		object ContextValue
		{
			get
			{
				if (_observable != null)
					return _observable;
				return _value;
			}
		}
		
		protected sealed override void OnRooted()
		{
			_updated = false;
			base.OnRooted();
			OnRootedValue();
			if (!_updated)
				UpdateValue(this);
		}
		
		protected virtual void OnRootedValue() { }
		
		protected override void OnUnrooted()
		{
			_observable = null;
			//TODO: https://github.com/fuse-open/fuselibs/issues/789
			DataChanged( null );
			base.OnUnrooted();
		}		
		
		ContextDataResult ISiblingDataProvider.TryGetDataProvider( DataType type, out object provider )
		{
			provider = type != DataType.Key ? null : this;
			return ContextDataResult.Continue;
		}
		
		bool IObject.ContainsKey(string key)
		{
			return (string)Name == key;
		}
		object IObject.this[string key]
		{
			get 
			{
				if ((string)Name == key)
					return ContextValue;
				return null;
			}
		}
		string[] IObject.Keys
		{
			get { return new []{ (string)Name }; }
		}
		
		void IPropertyListener.OnPropertyChanged(PropertyObject source, Selector selector)
		{
		}
	}
	
	class LetObservable : IObservable
	{
		List<IObserver> _observers;
		LetBase _let;
		
		public LetObservable( LetBase let )
		{
			_let = let;
		}
		
		public void Dispose()
		{
			_let = null;
			_observers = null;
		}
		
		Uno.IDisposable IObservableArray.Subscribe(IObserver observer)
		{
			if (_observers == null)
				_observers = new List<IObserver>();
			_observers.Add(observer);
			return new Subscription{ Source = this, Observer = observer };
		}
		
		int IArray.Length 
		{ 	
			get { return _let != null && _let.HasValue ? 1 : 0; }
		}
		
		object IArray.this[int index] 
		{ 
			get 
			{ 
				if (index != 0 || _let == null || !_let.HasValue)
					throw new IndexOutOfRangeException();
				return _let.ObjectValue; 
			}
		}
		
		void Unsubscribe(IObserver observer)
		{
			if (_observers != null)
				_observers.Remove(observer);
		}
		
		public void UpdateSetValue()
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnSet(_let.ObjectValue);
			}
		}
		
		public void UpdateClear()
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnClear();
			}
		}
		
		class Subscription : ISubscription
		{
			public LetObservable Source;
			public IObserver Observer;
			
			public void Dispose()
			{
				Source.Unsubscribe(Observer);
			}
			
			public void ClearExclusive() { Fuse.Diagnostics.InternalError( "Unsupported", this ); }
			public void SetExclusive(object newValue) 
			{ 
				Source._let.SetObjectValue( newValue, Source._let);
			}
			public void ReplaceAllExclusive(IArray values)  { Fuse.Diagnostics.InternalError( "Unsupported", this ); }

			public void ClearExclusive(Scripting.Context context)  { Fuse.Diagnostics.InternalError( "Unsupported", this ); }
			public void SetExclusive(Scripting.Context context, object newValue)  { Fuse.Diagnostics.InternalError( "Unsupported", this ); }
			public void ReplaceAllExclusive(Scripting.Context context, IArray values)  { Fuse.Diagnostics.InternalError( "Unsupported", this ); }
		}
	}
	
	/**
		Binds an expression or value to a name in the data context. This simplifies repeated calculations and allows introduction of new variables.
		
		To introduce a new value:
		
			<Let ux:Name="a" Value="5"/>
			
		The value is now part of the data context:
		
			<Slider Value="{a}"/>
		
		It can also be accessed directly outside of the context:
		
			<Slider Value="{Property a.Value}"/>
			
		
		If you are using an expression it's recommended now to use `Expression` instead of `Value`:
		
			<Let ux:Name="p" Expression="{pos} + 5"/>
			
		This ensures proper propagation of undefined values.  (This is part of the reason this is an experimental API, since we don't really want to distinguish between Expression and Value, but have no choice at the moment).
		
		## LetType
		
		If you are creating a value of a specific type, and/or need to use `Change` or other animators, consider using one of the @LetType classes instead, such as @LetFloat or @LetString. They have a cleaner conversion mechanism, leading to fewer surprises.
		
		@experimental
		Experimental since there are some fine details about handling observables, nulls, and expressions that aren't quite defined and might subtlely alter the behaviour. For typical use-cases it should be okay though.
	*/
	public class Let : LetBase, IListener
	{
		IExpression _expr;
		public IExpression Expression
		{
			get { return _expr; }
			set 
			{ 
				CleanupExpression();
				_expr = value;
				if (IsRootingCompleted)
					SubscribeExpression();
			}
		}
		
		[UXOriginSetter("SetValue")]
		public object Value
		{
			get { return ObjectValue; }
			set { SetValue(value, this); }
		}
		
		public void SetValue( object value, IPropertyListener origin)
		{
			SetObjectValue(value, origin);
		}
		
		protected sealed override void OnRootedValue()
		{
			SubscribeExpression();
		}
		
		protected sealed override void OnUnrooted()
		{
			CleanupExpression();
		}

		NodeExpressionBinding _exprSub;
		void CleanupExpression()
		{
			if (_exprSub != null)
			{
				_exprSub.Dispose();
				_exprSub = null;
			}
		}
		
		void SubscribeExpression()
		{
			CleanupExpression();
			if (_expr == null)
				return;
				
			_exprSub = new NodeExpressionBinding(_expr, this, this);
		}
		
		void IListener.OnNewData(IExpression source, object value)
		{
			SetObjectValue( value, this );
		}
		
		void IListener.OnLostData(IExpression source)
		{
			ResetObjectValue();
		}
	}

	/** 
		Provides a bindable value for use in UX. This assists in combining animations and transitions in the UX without needing to use JavaScript intermediates. It is not meant to store application state, being intended only for UI level changes and effects.
		
		Unlike @Let this enforces a specific value type and is suitable for use with `Change`, `Set`, and other property bindings.
		
		These values are two-way bindable (like Observables), for example:
		
			<LetString Value="hello" ux:Name="a"/>
			<TextInput Value="{a}"/>
			<Text Value="{a}"/>
			
		Typing in the `TextInput` will modify the value of `a` and update the `Text` value.
		
		## Available types
		
		[subclass Fuse.Reactive.LetType]
		
		@see Let
		@experimental Though is is based on the `Let` feature, which is experimental. The `LetType` classes are more predictable and have less conversion issues. It's unlikely the semantics will change -- but will remain experimental so long as `Let` is experimental.
	*/
	public abstract class LetType<T> : LetBase
	{
		[UXOriginSetter("SetValue")]
		public T Value
		{
			get 
			{ 
				//need marshalling since two-way bindings might set a non-T, but compatible value
				T result = default(T);
				if (HasValue && Marshal.TryToType<T>( ObjectValue, out result))
					return result;
				return default(T); 
			}
			set { SetValue(value, this); }
		}
		
		public void SetValue( T value, IPropertyListener origin )
		{
			SetObjectValue(value, origin);
		}
	}

	/** A @LetType that specifies a `float` value. */
	public class LetFloat : LetType<float> { }
	/** A @LetType that specifies a `float2` value. */
	public class LetFloat2 : LetType<float2> { }
	/** A @LetType that specifies a `float3` value. */
	public class LetFloat3 : LetType<float3> { }
	/** A @LetType that specifies a `float4` value. */
	public class LetFloat4 : LetType<float4> { }
	/** A @LetType that specifies a `string` value. */
	public class LetString : LetType<string> { }
	/** A @LetType that specifies a `bool` value. */
	public class LetBool : LetType<bool> { }
	/** A @LetType that specifies a `Size` value. */
	public class LetSize : LetType<Size> { }
	/** A @LetType that specifies a `Size2` value. */
	public class LetSize2 : LetType<Size2> { }
}
