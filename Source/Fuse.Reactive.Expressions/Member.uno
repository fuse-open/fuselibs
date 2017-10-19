using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Represents a reactive object-member look-up operation. */
	public sealed class Member: Expression
	{
		Expression BaseObject { get; private set; }
		public string Name { get; private set; }
		[UXConstructor]
		//It's unclear why this has to have the name "Object" here... "BaseObject" causes UX compile erorrs on bindings like {some.key}
		public Member([UXParameter("Object")] Expression obj, [UXParameter("Name")] string name)
		{
			BaseObject = obj;
			Name = name;
		}

		public override string ToString()
		{
			return BaseObject.ToString() + "." + Name;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new Subscription(this, context, listener);
		}

		class Subscription: InnerListener, IPropertyObserver, IWriteable
		{
			Member _member;
			IListener _listener;
			IDisposable _objectSub;
			
			public Subscription(Member member, IContext context, IListener listener)
			{
				_listener = listener;
				_member = member;
				//at end, be aware of sync call to OnNewData
				_objectSub = _member.BaseObject.Subscribe(context, this);
			}
			
			IPropertySubscription _obsObjSub;
			void DisposeObservableObjectSubscription()
			{
				if (_obsObjSub != null)
				{
					_obsObjSub.Dispose();
					_obsObjSub = null;
				}
			}

			protected override void OnNewData(IExpression source, object obj)
			{
				DisposeObservableObjectSubscription();

				ClearDiagnostic();

				var io = obj as IObject;
				if (io != null && io.ContainsKey(_member.Name))
				{
					var obsObj = io as IObservableObject;
					if (obsObj != null)
						_obsObjSub = obsObj.Subscribe(this);

					_listener.OnNewData(_member, io[_member.Name]);
				}
				else
				{
					SetDiagnostic("'" + _member.BaseObject.ToString() +"' does not contain property '" + _member.Name + "'", _member);
					_listener.OnLostData(_member);
				}
			}
			
			protected override void OnLostData(IExpression source)
			{
				DisposeObservableObjectSubscription();
			}

			void IPropertyObserver.OnPropertyChanged(IDisposable sub, string propName, object newValue)
			{
				if (_obsObjSub != sub) return;
				if (propName != _member.Name) return;
				_listener.OnNewData(_member, newValue);
			}

			bool IWriteable.TrySetExclusive(object newObj)
			{
				if (_obsObjSub != null)
					return _obsObjSub.TrySetExclusive(_member.Name, newObj);
				return false;
			}

			public override void Dispose()
			{
				if (_objectSub != null)
				{
					_objectSub.Dispose();
					_objectSub = null;
				}
				DisposeObservableObjectSubscription();
				base.Dispose();
			}
		}
	}
}