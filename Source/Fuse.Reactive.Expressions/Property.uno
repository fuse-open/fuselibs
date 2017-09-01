using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	[UXUnaryOperator("Property")]
	public sealed class Property: Expression
	{
		public ConstantExpression Object { get; private set; }
		public PropertyAccessor Accessor { get; private set; }

		[UXConstructor]
		public Property([UXParameter("Object")] ConstantExpression obj, [UXParameter("Accessor")] PropertyAccessor accessor)
		{
			Object = obj;
			Accessor = accessor;
		}
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			var obj = (PropertyObject)Object.GetValue(context);
			return new Subscription(this, obj, Accessor, listener);
		}

		class Subscription: IPropertyListener, IWriteable
		{
			Property _prop;
			PropertyObject _object;
			PropertyAccessor _accessor;
			IListener _listener;

			public Subscription(Property prop, PropertyObject obj, PropertyAccessor accessor, IListener listener)
			{
				_prop = prop;
				_listener = listener;
				_accessor = accessor;
				_object = obj;

				_object.AddPropertyListener(this);

				PushValue();
			}

			public bool TrySetExclusive(object value)
			{
				object res;
				if (Marshal.TryConvertTo(_accessor.PropertyType, value, out res, _object))
				{
					_accessor.SetAsObject(_object, res, this);
					return true;
				}
				return false;
			}

			public void Dispose()
			{
				_object.RemovePropertyListener(this);
				_accessor = null;
				_object = null;
				_listener = null;
			}

			void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
			{
				if (prop == _accessor.Name) PushValue();
			}

			void PushValue()
			{
				_listener.OnNewData(_prop, _accessor.GetAsObject(_object));
			}
		}
	}

}

