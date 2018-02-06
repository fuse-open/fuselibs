using Uno;
using Uno.Collections;

namespace Fuse.Scripting
{
	public abstract class NativeMember
	{
		protected string Name { get; private set; }
		public IThreadWorker ThreadWorker { get; private set; }
		protected Object ModuleObject { get; private set; }
		protected internal NativeMember(string name) { Name = name; }

		Context _context;
		[Obsolete("Either use passed-down Context, or dispatch to ThreadWorker")]
		public Context Context { get { return _context; } }

		internal void Create(Object obj, Context context)
		{
			if (obj == null)
				throw new ArgumentNullException(nameof(obj));

			if (context == null)
				throw new ArgumentNullException(nameof(context));

			ModuleObject = obj;
			ThreadWorker = context.ThreadWorker;

			_context = context;

			var member = CreateObject(context);
			if(member != null)
				ModuleObject[Name] = member;
		}

		protected abstract object CreateObject(Context context);
	}
}
