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

		class MemberSubscription: Subscription
		{
			Member _member;
			public MemberSubscription(Member member, IContext context, IListener listener): base(member, listener)
			{
				_member = member;
				Init(context);
			}

			protected override void OnNewOperand(object obj)
			{
				ClearDiagnostic();

				var io = obj as IObject;
				if (io != null && io.ContainsKey(_member.Name))
				{
					PushNewData(io[_member.Name]);
				}
				else
				{
					SetDiagnostic("'" + _member.Operand.ToString() +"' does not contain property '" + _member.Name + "'", _member);
				}
			}
		}
	}
}