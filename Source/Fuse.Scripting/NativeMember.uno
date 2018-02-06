using Uno;
using Uno.Collections;

namespace Fuse.Scripting
{
	public abstract class NativeMember
	{
		protected string Name { get; private set; }
		public Context Context { get; private set; }
		protected Object ModuleObject { get; private set; }
		protected internal NativeMember(string name) { Name = name; }

		internal void Create(Object obj, Context context)
		{
			if (obj == null)
				throw new ArgumentNullException(nameof(obj));

			if (context == null)
				throw new ArgumentNullException(nameof(context));

			ModuleObject = obj;
			Context = context;
			var member = CreateObject();
			if(member != null)
				ModuleObject[Name] = member;
		}

		protected abstract object CreateObject();
	}
}
