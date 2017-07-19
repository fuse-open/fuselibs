using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Represents a reactive object-member look-up operation. */
	public sealed class Member: UnaryOperator
	{
		public string Name { get; private set; }
		[UXConstructor]
		public Member([UXParameter("Object")] Expression obj, [UXParameter("Name")] string name): base(obj)
		{
			Name = name;
		}

		public override string ToString()
		{
			return Operand.ToString() + "." + Name;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new MemberSubscription(this, context, listener);
		}

		class MemberSubscription: Subscription, IPropertyObserver, IWriteable
		{
			Member _member;
			public MemberSubscription(Member member, IContext context, IListener listener): base(member, listener)
			{
				_member = member;
				Init(context);
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

			protected override void OnNewOperand(object obj)
			{
				DisposeObservableObjectSubscription();

				ClearDiagnostic();

				var io = obj as IObject;
				if (io != null && io.ContainsKey(_member.Name))
				{
					var obsObj = io as IObservableObject;
					if (obsObj != null)
						_obsObjSub = obsObj.Subscribe(this);

					PushNewData(io[_member.Name]);
				}
				else
				{
					SetDiagnostic("'" + _member.Operand.ToString() +"' does not contain property '" + _member.Name + "'", _member);
				}
			}

			void IPropertyObserver.OnPropertyChanged(IDisposable sub, string propName, object newValue)
			{
				if (_obsObjSub != sub) return;
				if (propName != _member.Name) return;
				PushNewData(newValue);
			}

			bool IWriteable.TrySetExclusive(object newObj)
			{
				if (_obsObjSub != null)
					return _obsObjSub.TrySetExclusive(_member.Name, newObj);
				return false;
			}

			public override void Dispose()
			{
				DisposeObservableObjectSubscription();
				base.Dispose();
			}
		}
	}
}