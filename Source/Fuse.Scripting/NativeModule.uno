using Uno;
using Uno.Collections;

namespace Fuse.Scripting
{
	public class NativeModule : Module, IModuleProvider
	{
		List<NativeMember> _members = new List<NativeMember>();

		Module IModuleProvider.GetModule()
		{
			return this;
		}
		
		public event EventHandler Reset;

		internal void InternalReset()
		{
			if (Reset != null)
				Reset(null, EventArgs.Empty);
		}

		protected void AddMember(NativeMember member)
		{
			if (IsEvaluated) throw new Exception("NativeModule(): Cannot add more members after first use");

			_members.Add(member);
		}

		public override void Evaluate(Context c, ModuleResult result)
		{
			var module = result.GetObject(c);
			if (module != null)
			{
				var obj = module["exports"] as Scripting.Object;
				if (obj != null)
				{
					foreach (var m in _members)
						m.Create(obj, c);
				}
			}
		}
	}
}
