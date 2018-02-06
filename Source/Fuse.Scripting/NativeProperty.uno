using Uno;
using Uno.Collections;

namespace Fuse.Scripting
{
	public delegate TJSValue ValueConverter<T, TJSValue>(Context context, T originalValue);

	public class NativeProperty<T, TJSValue> : NativeMember
	{
		Action<TJSValue> _setHandler;
		Func<T> _getHandler;
		ValueConverter<T, TJSValue> _valueConverter;
		TJSValue _readonlyValue = default(TJSValue);
		bool _isReadonly = false;

		public NativeProperty(string name) : this(name, null, null, null) {}


		public NativeProperty(string name, TJSValue value) : this(name, null, null, null)
		{
			_isReadonly = true;
			_readonlyValue = value;
		}
		
		public NativeProperty(string name, Func<T> getHandler = null, Action<TJSValue> setHandler = null, ValueConverter<T, TJSValue> valueConverter = null) : base(name)
		{
			_setHandler = setHandler;
			_getHandler = getHandler;

			_valueConverter = valueConverter;
		}

		protected override object CreateObject(Context context)
		{
			if(_isReadonly)
				context.ObjectDefineProperty(ModuleObject, Name, _readonlyValue);
			else
				context.ObjectDefineProperty(ModuleObject, Name, (Callback)GetProperty, (Callback)SetProperty);

			return null;
		}
		
		object SetProperty(Context context, object[] args)
		{
			if(_setHandler == null) _setHandler = SetProperty;

			_setHandler((args.Length > 0 && args[0] is TJSValue) ? (TJSValue)args[0] : default(TJSValue));

			return null;
		}
		protected virtual void SetProperty(TJSValue value) {}
		
		object GetProperty(Context context, object[] args)
		{
			if(_getHandler == null)
				_getHandler = GetProperty;

			if(_valueConverter != null)
				return _valueConverter(context, _getHandler());
			
			return _getHandler();
		}
		protected virtual T GetProperty() { return default(T); }
	}
}
